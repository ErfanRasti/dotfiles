{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Flake inputs, so `nix flake update` pulls their latest commits
  comfy = inputs.spicetify-comfy;
  adblock = inputs.spicetify-adblock;
  # nixpkgs' spicetify-cli doesn't install its bundled Extensions folder
  builtinExtensions = "${pkgs.spicetify-cli.src}/Extensions";

  # Must match spotify_path / prefs_path in config-xpui.ini
  spotifyDir = "$HOME/.local/share/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify";
  spotifyPrefs = "$HOME/.var/app/com.spotify.Client/config/spotify/prefs";

  # Reload the open Spotify through its DevTools port (see spotify-flags.conf)
  # instead of restarting it; does nothing when Spotify isn't running
  reloadSpotifyPage = ''
    ws=$(curl -sf "http://127.0.0.1:9222/json/list" |
      jq -r '[.[] | select(.type == "page")][0].webSocketDebuggerUrl // empty') || exit 0
    [ -n "$ws" ] || exit 0
    echo '{"id":1,"method":"Page.reload"}' | websocat -n1 "$ws" >/dev/null
  '';

  # First-time patch of a stock Spotify: on a new system, and again after every
  # Flatpak update (an update swaps in fresh, unpatched files). No-op once patched.
  spicetify-setup = pkgs.writeShellApplication {
    name = "spicetify-setup";
    runtimeInputs = with pkgs; [
      spicetify-cli
      flatpak
      gnused
      curl
      jq
      websocat
    ];
    text = ''
      spotify="${spotifyDir}"
      prefs="${spotifyPrefs}"

      if [ ! -d "$spotify/Apps" ]; then
        echo "spicetify-setup: Spotify Flatpak isn't installed yet, skipping"
        exit 0
      fi
      # Patched Spotify has an extracted Apps/xpui folder instead of xpui.spa
      [ -f "$spotify/Apps/xpui.spa" ] || exit 0

      # spicetify reads Spotify's version from prefs, which Spotify only writes on its
      # first launch (and only updates on the launch after an update). Take it from
      # Flatpak instead, so the backup is tagged with the installed version.
      version=$(flatpak info --user com.spotify.Client | sed -n 's/^ *Version: *//p')
      mkdir -p "$(dirname "$prefs")"
      touch "$prefs"
      sed -i '/^app\.last-launched-version=/d' "$prefs"
      echo "app.last-launched-version=\"$version\"" >>"$prefs"

      echo "spicetify-setup: patching Spotify $version"
      spicetify -q backup apply --no-restart
      ${reloadSpotifyPage}
    '';
  };

  # matugen/Noctalia post_hook: apply the new colors, then reload the open Spotify
  spicetify-reload = pkgs.writeShellApplication {
    name = "spicetify-reload";
    runtimeInputs = with pkgs; [
      spicetify-cli
      spicetify-setup
      curl
      jq
      websocat
    ];
    text = ''
      spicetify-setup # patches a stock Spotify first, if needed
      spicetify -q refresh || spicetify -q apply --no-restart
      ${reloadSpotifyPage}
    '';
  };

  spotifyFlags = pkgs.writeText "spotify-flags.conf" ''
    --remote-debugging-port=9222
    --enable-features=UseOzonePlatform
    --ozone-platform=wayland
    --enable-wayland-ime
  '';
in
{
  # Spotify itself is the user Flatpak (packages.nix), so spicetify can patch it.
  # Settings (spotify_path, theme, extensions) live in ~/.config/spicetify/config-xpui.ini.
  home.packages = [
    pkgs.spicetify-cli
    spicetify-setup
    spicetify-reload
  ];

  # Runs spicetify-setup at login, on `home-manager switch`, and right after
  # nix-flatpak installs/updates Flatpaks (which can reset Spotify to stock)
  systemd.user.services.spicetify-setup = {
    Unit = {
      Description = "Patch a stock (new or updated) Spotify Flatpak with spicetify";
      After = [ "flatpak-managed-install.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe spicetify-setup;
    };
    Install.WantedBy = [
      "default.target"
      "flatpak-managed-install.service"
    ];
  };

  # Extra flags read by the Flatpak's own launcher, inside its sandbox. Copied rather
  # than linked: the sandbox can't see /nix/store, so a symlink gets the flags ignored.
  home.activation.spotifyFlags = lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "linkGeneration" ] ''
    flags="$HOME/.var/app/com.spotify.Client/config/spotify-flags.conf"
    run rm -f "$flags"
    run install -Dm644 ${spotifyFlags} "$flags"
  '';

  # Only spicetify reads these, outside the sandbox, so store symlinks are fine here:
  # `apply`/`refresh` copies them into the Flatpak's own files (spotify_path).
  home.file = {
    # Comfy theme; color.ini is left out so matugen/Noctalia can write it.
    # user.css = upstream's (it @imports Comfy's app.css) + my overrides on top
    ".config/spicetify/Themes/Comfy/user.css".text =
      builtins.readFile "${comfy}/Comfy/user.css" + "\n" + builtins.readFile ./spicetify-comfy.css;
    ".config/spicetify/Themes/Comfy/app.css".source = "${comfy}/Comfy/app.css";
    ".config/spicetify/Themes/Comfy/theme.js".source = "${comfy}/Comfy/theme.js";
    ".config/spicetify/Themes/Comfy/theme.script.js".source = "${comfy}/Comfy/theme.script.js";
    ".config/spicetify/Themes/Comfy/assets".source = "${comfy}/Comfy/assets";

    ".config/spicetify/Extensions/fullAppDisplay.js".source = "${builtinExtensions}/fullAppDisplay.js";
    ".config/spicetify/Extensions/shuffle+.js".source = "${builtinExtensions}/shuffle+.js";
    ".config/spicetify/Extensions/keyboardShortcut.js".source =
      "${builtinExtensions}/keyboardShortcut.js";
    ".config/spicetify/Extensions/adblock.js".source = "${adblock}/adblock/adblock.js";
  };
}
