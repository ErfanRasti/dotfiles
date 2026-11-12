# Home Manager module for COMSOL Multiphysics on NixOS.
# Import it from your home.nix:  imports = [ ./comsol.nix ];
#
# Note: hardware.graphics.enable = true; must stay in your NixOS config,
# Home Manager can't set it.
{
  pkgs,
  config,
  inputs,
  ...
}:

let
  # Libraries COMSOL and its installer expect to find in /usr/lib, /lib64, ...
  comsolLibs =
    pkgs:
    with pkgs;
    [
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

      # LiveLink for MATLAB (`comsol mphserver matlab`) starts MATLAB in an xterm
      xterm
    ]
    # LiveLink for MATLAB starts ~/matlab inside this FHS env, so it needs
    # MATLAB's libraries too (libpam, libXt, ...): the same list as the matlab package.
    ++ import ./matlab-libs.nix inputs pkgs;

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
      # Same as nix-matlab's launcher, for the MATLAB that LiveLink starts
      export QT_QPA_PLATFORM=xcb
      # Render on the NVIDIA GPU (PRIME offload, like nvidia-offload). COMSOL's
      # JOGL fails on the Intel/Mesa GLX path under Xwayland ("X11GLXDrawableFactory
      # - Could not initialize shared resources") when loaded in LiveLink MATLAB.
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      # MATLAB's libcef.so has an old fontconfig built in that spams the LiveLink
      # xterm with "invalid constant/attribute" warnings on these newer configs.
      # Use a copy of the font config without them.
      fcdir="''${XDG_CACHE_HOME:-$HOME/.cache}/comsol-fontconfig"
      mkdir -p "$fcdir/conf.d"
      rm -f "$fcdir"/conf.d/*
      for f in /etc/fonts/conf.d/*; do
        case "''${f##*/}" in
          48-guessfamily.conf | 48-spacing.conf | 49-sansserif.conf) ;;
          *) ln -sf "$f" "$fcdir/conf.d/" ;;
        esac
      done
      sed "s|/etc/fonts/conf.d|$fcdir/conf.d|" /etc/fonts/fonts.conf > "$fcdir/fonts.conf"
      export FONTCONFIG_FILE="$fcdir/fonts.conf"
      exec "$HOME/.local/comsol/bin/comsol" "$@"
    '';
  };
in
{
  home.packages = [
    comsol-fhs
    comsol
  ];

  # The installer also writes ~/.local/share/applications/comsol-multiphysics-6.3.desktop,
  # which runs COMSOL outside the FHS env and fails, and it keeps coming back.
  # Own that path with a hidden entry so it never shows up; the entry below replaces it.
  xdg.dataFile."applications/comsol-multiphysics-6.3.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=COMSOL Multiphysics 6.3
    Hidden=true
    NoDisplay=true
  '';

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

  # LiveLink for MATLAB: starts a COMSOL server and MATLAB connected to it.
  # The server exits on its own when MATLAB is closed.
  xdg.desktopEntries.comsol-matlab = {
    name = "COMSOL with MATLAB";
    comment = "MATLAB connected to a COMSOL Multiphysics server (LiveLink)";
    exec = "comsol mphserver matlab";
    icon = "${config.home.homeDirectory}/.local/comsol/bin/glnxa64/comsol.png";
    terminal = false;
    categories = [
      "Science"
      "Engineering"
    ];
  };
}
