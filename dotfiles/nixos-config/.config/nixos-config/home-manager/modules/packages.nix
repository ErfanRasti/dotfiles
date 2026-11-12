{
  pkgs,
  lib,
  inputs,
  config,
  system,
  ...
}:
{

  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];


  # programs.firefox.enable = false;
  # programs.google-chrome.enable = true;
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  home.packages =
    with pkgs;
    [
      # CLI Tools
      bash
      fish
      zsh
      oh-my-zsh
      zsh-autosuggestions
      zsh-syntax-highlighting
      zsh-fast-syntax-highlighting
      zsh-vi-mode
      zsh-autocomplete
      zsh-powerlevel10k
      fd
      fzf
      git
      jujutsu
      lazyjj
      github-cli
      pre-commit
      tmux
      sesh
      herdr
      bat
      wget
      zoxide
      ripgrep
      file
      (pkgs.runCommand "figlet-with-fonts"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        }
        ''
          mkdir -p $out/bin $out/share/figlet
          ln -s ${figlet}/share/figlet/* $out/share/figlet/
          for f in ${inputs.figlet-fonts}/*.flf ${inputs.figlet-fonts}/*.flc; do
            [ -f "$f" ] && ln -sf "$f" $out/share/figlet/
          done
          makeWrapper ${figlet}/bin/figlet $out/bin/figlet \
            --set FIGLET_FONTDIR "$out/share/figlet"
        ''
      )
      lolcat
      stow
      lazygit
      lazydocker
      trash-cli
      jq
      yq
      zellij
      cmatrix
      cava
      dwt1-shell-color-scripts
      ggh
      ascii-image-converter
      unzip
      unrar

      # Dev Tools
      github-desktop

      # Terminals
      kitty
      ghostty
      ptyxis

      # Fetch
      fastfetch

      # File managers
      yazi
      mediainfo # for yazi plugin
      television

      # Menus
      vicinae
      (rofi.override { plugins = [ rofi-calc ]; })
      rofimoji
      dux-search
      # dcal dms calendar

      # Controllers
      brightnessctl
      playerctl

      # Shells
      noctalia
      # noctalia-shell
      dux-shell
      quickshell
      # ashell

      # Themes
      matugen
      pywalfox-native
      gtk3
      gtk4
      adw-gtk3
      qt5.qtbase
      qt6.qtbase
      libsForQt5.qt5ct
      qt6Packages.qt6ct
      flatpak-xdg-utils
      xdg-desktop-portal
      desktop-file-utils
      gnome-tweaks

      # Sway tools
      # swaynotificationcenter
      swayidle
      swayosd
      libnotify

      # hyprland tools
      hypridle
      hyprpaper
      hyprshot
      hyprlock
      hyprsunset
      hyprpicker

      # AI Tools
      # opencode # nixos-unstable 2.2.5 has a broken node_modules hash; re-enable after the next update
      ollama
      # codex
      claude-code
      inputs.claude-desktop.packages.${stdenv.hostPlatform.system}.claude-desktop

      # Browsers
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      google-chrome
      chromium
      microsoft-edge
      firefox

      # Password Managers
      pass
      gnupg

      # Android Tools
      android-tools

      # Editors
      neovim
      emacs
      vscode

      # Clipboard managers
      wtype

      # Network & Proxy
      v2rayn
      networkmanagerapplet
      # speedtest
      speedtest-cli
      geteduroam-cli
      geteduroam

      # Social Media
      telegram-desktop
      discord
      teams-for-linux
      zoom-us

      # Camera
      cheese

      # Video/Audio data composition framework tools like "gst-inspect", "gst-launch" ...
      gst_all_1.gstreamer
      # Common plugins like "filesrc" to combine within e.g. gst-launch
      gst_all_1.gst-plugins-base
      # Specialized plugins separated by quality
      gst_all_1.gst-plugins-good
      # Plugins to reuse ffmpeg to play almost every video format
      gst_all_1.gst-libav

      # Image Editors
      gimp
      imagemagick
      # posthog is marked broken only because its tests fail with mcp >= 2
      (gnome-frog.override {
        python3Packages = python3Packages.overrideScope (
          _: prev: {
            posthog = prev.posthog.overridePythonAttrs (old: {
              doCheck = false;
              meta = old.meta // {
                broken = false;
              };
            });
          }
        );
      })

      # Video Editors
      kdePackages.kdenlive
      v4l-utils

      # Nautilus
      nautilus
      sushi
      nautilus-open-any-terminal
      code-nautilus
      rclone

      # Nix
      nix-prefetch-git
      nil

      # Fonts
      font-awesome
      nerd-fonts.caskaydia-cove
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      libertinus

      vazirmatn
      ir-standard-fonts
      behdad-fonts
      gandom-fonts
      nahid-fonts

      # Music
      # spotify - installed via flatpak
      # amberol
      fum
      gapless

      # Audio control
      pulseaudio
      pavucontrol
      # audacity
      gnome-sound-recorder

      # Radio
      shortwave

      # Videos
      mpv
      vlc
      ffmpeg-full

      # System monitor
      btop
      htop
      nvtopPackages.full
      mission-center
      dux-gop

      # Stores
      flatpak # use it with flatpak --user ...
      gnome-software
      inputs.nix-software-center.packages.${stdenv.hostPlatform.system}.nix-software-center
      inputs.app-manager.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Dictionaries
      wordbook

      # Container managers
      docker
      docker-compose
      podman
      podman-compose
      podman-desktop
      fuse-overlayfs

      # X Apps
      xwayland-satellite
      xeyes
      xrdb

      # Icons & Cursors
      bibata-cursors
      papirus-icon-theme
      flat-remix-icon-theme
      iconic
      icon-library

      # Offices
      onlyoffice-desktopeditors
      libreoffice
      zathura

      # Windows
      winboat

      #Languages
      gcc
      python3
      matlab
      lua
      lua5
      luarocks
      nodejs
      sqlite
      jdk17

      # Power Management tools
      acpi

      # Storage
      impression
      gparted
      gptfdisk # use it as gdisk

      # LaTeX
      pandoc
      texliveFull

      # PDF tools
      poppler-utils
      ghostscript

      # Tools
      showmethekey

      # Polkits
      # shouldn't be here and should be activated using host configs to create /run/wrappers/bin/pkexec
      #polkit

      # Thumbnails
      # https://wiki.nixos.org/wiki/Thumbnails
      ffmpegthumbnailer
      gdk-pixbuf
      libheif
      libheif.out
      webp-pixbuf-loader

      # Sounds
      sound-theme-freedesktop
      kdePackages.ocean-sound-theme # ocean sound theme

      # Download managers
      yt-dlp
      uget

      # note apps
      sticky-notes

      # System check
      stress

      # Screen recorder
      obs-studio

      # Graph tools
      gnome-graphs

      # GNOME
      gnome-extension-manager
      gnome-extensions-cli

      # USB
      ntfs3g

    ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # https://wiki.nixos.org/wiki/Polkit
  # services.polkit-gnome.enable = true;

  # Activation snippets all run in one `set -eu -o pipefail` script, so they must not
  # `exit`, set traps or let a failing command through: that stops the whole switch.
  home.activation.pywalfox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe pkgs.pywalfox-native} install || warnEcho "pywalfox: install failed, skipping"
    run ${lib.getExe pkgs.pywalfox-native} update || warnEcho "pywalfox: update failed, skipping"
  '';

  # Google Drive mount as a user service instead of an activation step: it mounts at
  # every login (not only after a switch), retries while offline, and unmounts on logout.
  systemd.user.services.rclone-gdrive = {
    Unit.Description = "Mount Google Drive at ~/GoogleDrive with rclone";
    Service = {
      Type = "notify";
      Environment = [ "PATH=/run/wrappers/bin" ]; # setuid fusermount3
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p %h/GoogleDrive"
        "-/run/wrappers/bin/fusermount3 -uz %h/GoogleDrive" # clear a stale mount
      ];
      ExecStart = "${lib.getExe pkgs.rclone} mount \"Google Drive:\" %h/GoogleDrive";
      ExecStop = "/run/wrappers/bin/fusermount3 -u %h/GoogleDrive";
      Restart = "on-failure";
      RestartSec = 30;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Noctalia keeps the wallpaper panel's "Flatten" toggle in its state file, not in
  # settings.toml, so set it here. Only that key is touched; the rest of the file is
  # runtime state (last screenshot region, annotate colors...) that noctalia owns.
  home.activation.noctaliaWallpaperFlatten = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/state.toml"
    run mkdir -p "$(dirname "$state")"
    [ -e "$state" ] || run touch "$state"
    tmp="$(mktemp)"
    if ${lib.getExe pkgs.gawk} '
      /^\[/ { if (insec && !done) { print "flatten = true"; done = 1 } insec = ($0 == "[wallpaper_panel]") }
      insec && /^flatten[ \t]*=/ { print "flatten = true"; done = 1; next }
      { print }
      END {
        if (insec && !done) { print "flatten = true"; done = 1 }
        if (!done) { print ""; print "[wallpaper_panel]"; print "flatten = true" }
      }
    ' "$state" > "$tmp"; then
      if cmp -s "$tmp" "$state"; then rm -f "$tmp"; else run mv "$tmp" "$state"; fi
    else
      rm -f "$tmp"
      warnEcho "noctalia: failed to set wallpaper_panel.flatten, skipping"
    fi
  '';

  home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "writeBoundary" "installPackages" ] ''
    export PATH="${
      lib.makeBinPath [
        pkgs.git
        pkgs.curl
        pkgs.gnutar
        pkgs.gzip
        pkgs.gawk
        pkgs.go
      ]
    }:$PATH"
    herdr=${lib.getExe pkgs.herdr}
    installed="$($herdr plugin list --json 2>/dev/null || true)"
    # Only install missing plugins: reinstalling on every switch hits GitHub's
    # rate limit (403) and a network failure shouldn't abort activation.
    for spec in cloudmanic/herdr-plus:cloudmanic.herdr-plus smarzban/herdr-file-viewer:herdr-file-viewer; do
      if ! grep -q "\"plugin_id\":\"''${spec#*:}\"" <<<"$installed"; then
        run $herdr plugin install "''${spec%%:*}" --yes \
          || warnEcho "herdr: failed to install ''${spec%%:*}, skipping"
      fi
    done
  '';
  # Xray core for v2rayN, from nixpkgs: it updates with the flake, needs no network at
  # switch time, and is the same on every machine. Copied, not linked, so v2rayN can
  # chmod it. pkgs.xray is a wrapper that only sets XRAY_LOCATION_ASSET when unset, so
  # v2rayN's own geoip/geosite files in bin/ still win.
  home.activation.installXrayCore = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    xrayDir="${config.home.homeDirectory}/.local/share/v2rayN/bin/xray"
    if ! cmp -s ${lib.getExe pkgs.xray} "$xrayDir/xray"; then
      run install -Dm755 ${lib.getExe pkgs.xray} "$xrayDir/xray"
    fi
    run rm -f "$xrayDir/.version" # left over from the old GitHub download
  '';

  services.flatpak = {
    enable = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "io.github.flattool.Warehouse"
      "org.videolan.VLC"
      "org.cvfosammmm.Lemma"
      "io.github.giantpinkrobots.flatsweep"
      "com.spotify.Client"
    ];
    overrides = {
      global = {
        Context = {
          filesystems = [
            "xdg-config/gtk-2.0:ro"
            "xdg-config/gtk-3.0:ro"
            "xdg-config/gtk-4.0:ro"
            "~/.gtkrc-2.0:ro"
            "xdg-config/qt5ct:ro"
            "xdg-config/qt6ct:ro"
          ];
        };
        Environment = {
          QT_QPA_PLATFORMTHEME = "qt6ct";
        };
      };
    };
  };
}
