# Nautilus wrapped with exactly the extensions below, so others installed on the system
# (e.g. gnome-terminal's "Open in Terminal") stay out of it. Its theming and folder setup
# is the dotfiles' ~/.local/share/nautilus-python/extensions/theme.py.
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  ext = pkgs.callPackage ./extensions.nix { inherit inputs; };

  # Compiled extensions (with properties pages from nautilus, papers and totem);
  # nautilus-python loads the Python ones.
  extensions = pkgs.buildEnv {
    name = "nautilus-extensions";
    paths = with pkgs; [
      nautilus
      papers
      totem
      nautilus-python
      ext.nautilus-checksums
      ext.nautilus-image-converter
      ext.nautilus-share
    ];
    pathsToLink = [ "/lib/nautilus/extensions-4" ];
  };

  # nautilus-python looks for these under $XDG_DATA_DIRS/nautilus-python/extensions.
  pythonExtensions = pkgs.buildEnv {
    name = "nautilus-python-extensions";
    paths = [
      ext.actions-for-nautilus
      ext.nautilus-admin
    ];
    pathsToLink = [ "/share/nautilus-python/extensions" ];
  };

  # Codecs for the audio/video properties page and thumbnails.
  gstPlugins = with pkgs.gst_all_1; [
    gst-plugins-good
    gst-plugins-bad
  ];

  # Wrap the binary-cached Nautilus instead of rebuilding it. Its D-Bus services are
  # rewritten too, so apps that open folders through D-Bus get this Nautilus as well.
  nautilusWrapped = pkgs.symlinkJoin {
    name = "nautilus-with-extensions-${pkgs.nautilus.version}";
    paths = [ pkgs.nautilus ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nautilus \
        --set NAUTILUS_4_EXTENSION_DIR ${extensions}/lib/nautilus/extensions-4 \
        --prefix XDG_DATA_DIRS : ${pythonExtensions}/share \
        --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${lib.makeSearchPath "lib/gstreamer-1.0" gstPlugins}

      for service in $out/share/dbus-1/services/*.service; do
        original=$(readlink -f "$service")
        rm "$service"
        substitute "$original" "$service" \
          --replace-fail ${pkgs.nautilus}/bin/nautilus $out/bin/nautilus
      done
    '';
  };
in
{
  home.packages = [
    nautilusWrapped
    pkgs.sushi # quick look (space)
    pkgs.packet # "Send with Packet"; nautilus-python finds its extension in the profile
  ];

  # nautilus-python also scans the profile's share/, so drop the extensions other packages
  # bring along (Ghostty's "Open in Ghostty", Collision's "Check Hashes", GSConnect's).
  home.extraProfileCommands = ''
    rm -f $out/share/nautilus-python/extensions/{ghostty,collision-extension,nautilus-gsconnect}.py
  '';
}
