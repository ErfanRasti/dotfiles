# Home Manager module for Wolfram Mathematica, set up like comsol.nix: Wolfram's own
# installer puts it in ~/.local/wolfram and it runs inside an FHS env, so Nix never needs the
# installer and nothing has to be detected at build time. The commands and the menu entry
# check for the installation when they start.
#
# Install (or reinstall) with:  wolfram-install [path/to/Wolfram_*.sh]
# (defaults to the newest ~/programs/wolfram/Wolfram_*.sh)
{
  pkgs,
  config,
  ...
}:

let
  dir = "${config.home.homeDirectory}/.local/wolfram";
  version = "15.0"; # used in the installer's desktop entry name and window app ID
  appId = "com.wolfram.Wolfram.${version}";

  # Libraries Mathematica expects in /usr/lib (the same list as the nixpkgs package).
  wolframLibs =
    pkgs: with pkgs; [
      # the installer
      coreutils
      which
      gnused
      gnugrep
      gawk
      gnutar
      procps
      util-linux

      alsa-lib
      cups.lib
      dbus
      flite
      fontconfig
      freetype
      gcc-unwrapped.lib
      glib
      gmpxx
      keyutils.lib
      libGL
      libGLU
      libpcap
      libtins
      libuuid
      libxkbcommon
      libxml2
      llvmPackages.libllvm.lib
      matio
      mpfr
      ncurses
      opencv4
      openjdk11
      openssl
      pciutils
      tre
      unixodbc
      xkeyboard_config
      zlib
      # not in the nixpkgs list (it ignores missing libraries), but needed here
      libdrm
      wayland
      libxau
      libice
      libsm
      libx11
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxinerama
      libxmu
      libxrandr
      libxrender
      libxtst
      libxcb
      libxcb-image
      libxcb-keysyms
    ];

  # A shell inside the FHS sandbox; the commands below run Mathematica through it.
  wolfram-fhs = pkgs.buildFHSEnv {
    name = "wolfram-fhs";
    targetPkgs = wolframLibs;
    runScript = "bash";
    # Same settings as the nixpkgs package's wrappers.
    profile = ''
      export USE_WOLFRAM_LD_LIBRARY_PATH=1 # use its bundled Qt
      export QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
      export QT_QPA_PLATFORM="wayland;xcb"
    '';
  };

  # Runs ~/.local/wolfram/Executables/<name> in the FHS env, if Mathematica is installed.
  launcher =
    name:
    pkgs.writeShellScriptBin name ''
      exe=${dir}/Executables/${name}
      if [ ! -x "$exe" ]; then
        echo "${name}: Mathematica isn't installed in ${dir}; run wolfram-install" >&2
        exit 1
      fi
      exec ${wolfram-fhs}/bin/wolfram-fhs -c 'exec "$0" "$@"' "$exe" "$@"
    '';

  desktopItem = pkgs.makeDesktopItem {
    name = appId;
    desktopName = "Wolfram ${version}";
    comment = "Technical Computing System";
    exec = "WolframNB --name ${appId} %F";
    icon = "${dir}/SystemFiles/FrontEnd/SystemResources/X/App-128.png";
    terminal = false;
    categories = [
      "Science"
      "Math"
      "Education"
    ];
    keywords = [
      "Mathematica"
      "Wolfram"
    ];
    mimeTypes = [
      "application/mathematica"
      "application/x-mathematica"
      "application/vnd.wolfram.nb"
      "application/vnd.wolfram.cdf"
      "application/vnd.wolfram.player"
      "application/vnd.wolfram.mathematica.package"
      "application/vnd.wolfram.wl"
      "x-scheme-handler/wolfram+cloudobject"
    ];
    # Shells match the window's app ID against StartupWMClass to find the icon.
    startupWMClass = appId;
    # Launchers that honour TryExec hide the entry until Mathematica is installed.
    tryExec = "${dir}/Executables/WolframNB";
  };

  wolfram-install = pkgs.writeShellScriptBin "wolfram-install" ''
    set -eu
    installer=''${1:-$(ls -v "$HOME"/programs/wolfram/Wolfram_*.sh 2>/dev/null | tail -n 1)}
    if [ ! -f "$installer" ]; then
      echo "usage: wolfram-install [Wolfram_*.sh] (none found in ~/programs/wolfram)" >&2
      exit 1
    fi
    exec ${wolfram-fhs}/bin/wolfram-fhs -c \
      'sh "$0" -- -auto -targetdir="$1" -execdir="$1/bin" -createdir=y' "$installer" ${dir}
  '';
in
{
  home.packages = [
    wolfram-fhs
    wolfram-install
  ]
  ++ map launcher [
    "WolframNB"
    "wolfram"
    "wolframscript"
    "WolframKernel"
    "math"
  ];

  # The installer also writes this entry to ~/.local/share/applications, running Mathematica
  # outside the FHS env (which fails), and that folder wins over ~/.nix-profile. So own that
  # exact path; force lets the next switch replace the installer's copy instead of stopping on it.
  xdg.dataFile."applications/${appId}.desktop" = {
    force = true;
    source = "${desktopItem}/share/applications/${appId}.desktop";
  };
}
