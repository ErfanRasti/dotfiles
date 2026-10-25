# Home Manager module for COMSOL Multiphysics on NixOS.
# Import it from your home.nix:  imports = [ ./comsol.nix ];
#
# Note: hardware.graphics.enable = true; must stay in your NixOS config,
# Home Manager can't set it.
{ pkgs, config, ... }:

let
  # Libraries COMSOL and its installer expect to find in /usr/lib, /lib64, ...
  comsolLibs =
    pkgs: with pkgs; [
      # basics for the installer and the FlexNet license tools
      glibc
      zlib
      libuuid
      ncurses5
      coreutils
      which
      procps
      file
      unzip
      gnutar

      # X11
      libx11
      libxext
      libxrender
      libxtst
      libxi
      libxrandr
      libxcursor
      libxfixes
      libxcomposite
      libxdamage
      libxinerama
      libxxf86vm
      libxcb
      libsm
      libice
      libdrm

      # GUI toolkit (SWT on GTK3) and the help browser
      gtk3
      glib
      cairo
      pango
      gdk-pixbuf
      atk
      at-spi2-atk
      webkitgtk_4_1
      libsecret

      # fonts, graphics, sound, misc
      fontconfig
      freetype
      dejavu_fonts
      libGL
      libGLU
      mesa
      alsa-lib
      dbus
      nss
      nspr
      expat
    ];

  # A shell inside the FHS sandbox. Use it to run the installer (./setup).
  # NO SPACE IN INSTALLATION PATH
  comsol-fhs = pkgs.buildFHSEnv {
    name = "comsol-fhs";
    targetPkgs = comsolLibs;
    runScript = "bash";
  };

  # Starts COMSOL directly. Expects it installed in ~/.local/comsol.
  comsol = pkgs.buildFHSEnv {
    name = "comsol";
    targetPkgs = comsolLibs;
    runScript = pkgs.writeShellScript "comsol-run" ''
      exec "$HOME/.local/comsol/bin/comsol" "$@"
    '';
  };
in
{
  home.packages = [
    comsol-fhs
    comsol
  ];

  # The installer also writes ~/.local/share/applications/comsol-multiphysics-*.desktop,
  # which runs COMSOL outside the FHS env and fails. Delete it; this entry replaces it.
  xdg.desktopEntries.comsol = {
    name = "COMSOL Multiphysics";
    exec = "comsol";
    icon = "${config.home.homeDirectory}/.local/comsol/bin/glnxa64/comsol.png";
    # COMSOL's GUI is SWT, so its windows report app ID "SWT" (not "comsol").
    # Shells like noctalia match app IDs against StartupWMClass to find the icon.
    settings.StartupWMClass = "SWT";
    terminal = false;
    categories = [
      "Science"
      "Engineering"
    ];
  };
}
