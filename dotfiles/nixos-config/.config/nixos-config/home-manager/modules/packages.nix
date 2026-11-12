{
  pkgs,
  lib,
  inputs,
  config,
  system,
  ...
}:
let
  # Mathematica, built from the pinned nixpkgs-mathematica input (see flake.nix) so updates
  # don't rebuild it.
  mathematica =
    (import inputs.nixpkgs-mathematica {
      inherit system;
      config.allowUnfree = true;
    }).mathematica.override
      {
        version = "15.0.1"; # the version you downloaded (installer pinned by wolfram-installer-pin)
        webdoc = false; # true if you took the smaller web-docs installer
      };

  # Its installer must already be in the Nix store (nixpkgs uses requireFile), so it is only
  # installed when it is; otherwise it is skipped instead of failing the switch. The check
  # needs impure evaluation (nh is wrapped with pure-eval = false in host/modules/packages.nix);
  # a pure eval can't see the store path and just skips Mathematica. tryEval also skips it if
  # nixpkgs drops this version.
  withMathematica =
    let
      src = builtins.tryEval (builtins.unsafeDiscardStringContext mathematica.src.outPath);
    in
    src.success && builtins.pathExists src.value;

  # A hand-added store path is unreferenced, so `nh clean` would delete it. This adds every
  # ~/programs/wolfram/Wolfram_*.sh to the store and pins it with a GC root
  # (~/.local/state/nix-gcroots/), at login, whenever an installer lands in that folder, and
  # on every switch (so the next switch picks Mathematica up).
  # Upgrading: put the new installer there, then bump `version` above. Delete old roots in
  # ~/.local/state/nix-gcroots/ to let old installers be collected.
  wolframPin = pkgs.writeShellScript "wolfram-installer-pin" ''
    set -eu
    roots="$HOME/.local/state/nix-gcroots"
    mkdir -p "$roots"
    shopt -s nullglob
    for f in "$HOME"/programs/wolfram/Wolfram_*.sh; do
      root="$roots/$(basename "$f")"
      [ -e "$root" ] && continue # already in the store and pinned
      path="$(${pkgs.nix}/bin/nix-store --add-fixed sha256 "$f")"
      ${pkgs.nix}/bin/nix-store --add-root "$root" --indirect --realise "$path" >/dev/null
      echo "pinned $f -> $path"
    done
  '';
in
{

  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  # Keep the Wolfram installer in the store (see wolframPin above).
  systemd.user.services.wolfram-installer-pin = {
    Unit.Description = "Add and pin the Wolfram installer in the Nix store";
    Service = {
      Type = "oneshot";
      ExecStart = "${wolframPin}";
    };
    Install.WantedBy = [ "default.target" ]; # run once at login
  };
  systemd.user.paths.wolfram-installer-pin = {
    Unit.Description = "Watch ~/programs/wolfram for Wolfram installers";
    Path = {
      PathChanged = "%h/programs/wolfram"; # a file finished writing / was moved in
    };
    Install.WantedBy = [ "default.target" ];
  };

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
      rPackages.treesitter
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

    ]
    # Mathematica only where its installer is in the store (see withMathematica at the top of this file).
    ++ lib.optional withMathematica mathematica;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # https://wiki.nixos.org/wiki/Polkit
  # services.polkit-gnome.enable = true;

  # Pin the Wolfram installer now too, not only via the user service (see wolframPin above).
  home.activation.wolframInstallerPin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${wolframPin} || warnEcho "wolfram: failed to pin the installer, skipping"
  '';

  # Activation snippets all run in one `set -eu -o pipefail` script, so they must not
  # `exit`, set traps or let a failing command through: that stops the whole switch.
  home.activation.pywalfox = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe pkgs.pywalfox-native} install || warnEcho "pywalfox: install failed, skipping"
    run ${lib.getExe pkgs.pywalfox-native} update || warnEcho "pywalfox: update failed, skipping"
  '';

  # Mount only if not already mounted: mounting again fails and used to abort the switch.
  home.activation.rclone = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ~/GoogleDrive
    if ! ${pkgs.util-linux}/bin/mountpoint -q ~/GoogleDrive; then
      run ${lib.getExe pkgs.rclone} mount "Google Drive": ~/GoogleDrive --daemon \
        || warnEcho "rclone: failed to mount Google Drive, skipping"
    fi
  '';

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
  # Install or update the latest Xray core for v2rayN. Offline or rate-limited: keep what's there.
  home.activation.installXrayCore =
    let
      xrayAsset =
        {
          x86_64-linux = "Xray-linux-64.zip";
          aarch64-linux = "Xray-linux-arm64-v8a.zip";
        }
        .${system};
      curl = lib.getExe pkgs.curl;
    in
    lib.hm.dag.entryAfter [ "writeBoundary" "installPackages" ] ''
      xrayDir="${config.home.homeDirectory}/.local/share/v2rayN/bin/xray"
      xrayVersion="$(${curl} -fsSL https://api.github.com/repos/xtls/xray-core/releases/latest \
        | ${lib.getExe pkgs.jq} -r .tag_name)" || xrayVersion=""
      if [[ -z "$xrayVersion" || "$xrayVersion" == null ]]; then
        warnEcho "xray: couldn't get the latest version, skipping"
      elif [[ ! -f "$xrayDir/xray" || "$(cat "$xrayDir/.version" 2>/dev/null)" != "$xrayVersion" ]]; then
        xrayZip="$(mktemp)"
        if ${curl} -fsSLo "$xrayZip" \
          "https://github.com/xtls/xray-core/releases/download/$xrayVersion/${xrayAsset}" \
          && run mkdir -p "$xrayDir" \
          && run ${lib.getExe pkgs.unzip} -oq "$xrayZip" -d "$xrayDir"; then
          run chmod +x "$xrayDir/xray"
          echo "$xrayVersion" > "$xrayDir/.version"
        else
          warnEcho "xray: failed to install $xrayVersion, skipping"
        fi
        rm -f "$xrayZip"
      fi
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
