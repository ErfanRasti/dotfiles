{
  pkgs,
  inputs,
  ...
}:
{

  imports = [
    inputs.spicetify-nix.homeManagerModules.default
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  # programs.firefox.enable = false;
  # programs.google-chrome.enable = true;
  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  home.packages = with pkgs; [
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
    github-cli
    pre-commit
    tmux
    sesh
    bat
    wget
    zoxide
    ripgrep
    ripdrag
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
    dsearch
    # dcal dms calendar

    # Controllers
    brightnessctl
    playerctl

    # Shells
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    noctalia-shell
    dms-shell
    quickshell
    ashell

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

    # Audio
    pulseaudio

    # AI Tools
    opencode
    ollama

    # Browsers
    inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
    google-chrome
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

    # Social Media
    telegram-desktop
    discord
    teams-for-linux

    # Camera
    cheese

    # Image Editors
    gimp
    imagemagick

    # Video Editors
    kdePackages.kdenlive
    v4l-utils

    # Nautilus
    nautilus
    sushi
    nautilus-open-any-terminal
    code-nautilus

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
    # spotify - installed via spicetify-nix
    amberol
    fum
    gapless

    # Videos
    mpv
    vlc
    ffmpeg-full

    # System monitor
    btop
    htop
    nvtopPackages.full
    mission-center
    dgop

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

    # Power Management tools
    acpi

    # Storage
    impression
    gparted
    gptfdisk # use it as gdisk

    # LaTeX
    pandoc
    texliveFull

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
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # https://wiki.nixos.org/wiki/Polkit
  # services.polkit-gnome.enable = true;

  services.flatpak = {
    enable = true;
    packages = [
      "com.github.tchx84.Flatseal"
      "se.sjoerd.Graphs"
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
