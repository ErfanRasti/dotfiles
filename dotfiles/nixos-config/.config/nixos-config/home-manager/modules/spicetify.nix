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

  # matugen/Noctalia post_hook: apply the new colors, then reload the open Spotify
  # through its DevTools port (see spotify-flags.conf) instead of restarting it
  spicetify-reload = pkgs.writeShellApplication {
    name = "spicetify-reload";
    runtimeInputs = with pkgs; [
      spicetify-cli
      curl
      jq
      websocat
    ];
    text = ''
      spicetify -q refresh || spicetify -q apply --no-restart
      # 9222 from spotify-flags.conf, 8088 is Spotify's own port when devtools are enabled
      for port in 9222 8088; do
        ws=$(curl -sf "http://127.0.0.1:$port/json/list" |
          jq -r '[.[] | select(.type == "page")][0].webSocketDebuggerUrl // empty') || continue
        [ -n "$ws" ] || continue
        echo '{"id":1,"method":"Page.reload"}' | websocat -n1 "$ws" >/dev/null
        exit 0
      done
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

  # Extra flags read by the Flatpak's own launcher. Copied rather than linked:
  # the sandbox can't follow a symlink into /nix/store, so the flags got ignored.
  home.activation.spotifyFlags = lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "linkGeneration" ] ''
    flags="$HOME/.var/app/com.spotify.Client/config/spotify-flags.conf"
    run rm -f "$flags"
    run install -Dm644 ${spotifyFlags} "$flags"
  '';

  home.file = {
    # Comfy theme; color.ini is left out so matugen/Noctalia can write it
    ".config/spicetify/Themes/Comfy/user.css".source = "${comfy}/Comfy/user.css";
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
