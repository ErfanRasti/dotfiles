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

  # Applies the theme/extensions and reloads the open Spotify through its DevTools
  # port (see spotify-flags.conf) instead of restarting it. Run by the matugen/Noctalia
  # post_hook and by the spicetify-setup service below.
  spicetify-reload = pkgs.writeShellApplication {
    name = "spicetify-reload";
    runtimeInputs = with pkgs; [
      spicetify-cli
      flatpak
      curl
      jq
      websocat
    ];
    text = ''
      # Paths must match spotify_path / prefs_path in config-xpui.ini
      spotify="$HOME/.local/share/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"
      prefs="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"

      if [ ! -d "$spotify/Apps" ]; then
        echo "spicetify-reload: Spotify Flatpak isn't installed yet, skipping"
        exit 0
      fi

      if [ -f "$spotify/Apps/xpui.spa" ]; then
        # Stock Spotify (new system, or a Flatpak update swapped in fresh files):
        # first-time patch. spicetify reads Spotify's version from prefs, which Spotify
        # only writes when launched, so take it from Flatpak instead.
        version=$(flatpak info --user com.spotify.Client | sed -n 's/^ *Version: *//p')
        mkdir -p "$(dirname "$prefs")"
        touch "$prefs"
        sed -i '/^app\.last-launched-version=/d' "$prefs"
        echo "app.last-launched-version=\"$version\"" >>"$prefs"
        spicetify -q backup
      fi
      # Not just `refresh`: only `apply` loads newly listed extensions (~0.1s either way)
      spicetify -q apply --no-restart

      ws=$(curl -sf "http://127.0.0.1:9222/json/list" |
        jq -r '[.[] | select(.type == "page")][0].webSocketDebuggerUrl // empty') || exit 0
      [ -n "$ws" ] || exit 0
      echo '{"id":1,"method":"Page.reload"}' | websocat -n1 "$ws" >/dev/null
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
    spicetify-reload
  ];

  # Patches a stock Spotify at login, on `home-manager switch`, and right after
  # nix-flatpak installs/updates Flatpaks (which can reset Spotify to stock)
  systemd.user.services.spicetify-setup = {
    Unit = {
      Description = "Patch a stock (new or updated) Spotify Flatpak with spicetify";
      After = [ "flatpak-managed-install.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe spicetify-reload;
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
    ".config/spicetify/Extensions/coverExpand.js".source = ./spicetify-cover-expand.js;
  };
}
