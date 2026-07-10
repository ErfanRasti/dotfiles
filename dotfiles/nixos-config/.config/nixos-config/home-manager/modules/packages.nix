{ pkgs, inputs, ... }: {
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

    # Dev Tools
    github-desktop

    # Terminals
    kitty
    ghostty

    # Fetch
    fastfetch

    # File managers
    yazi
    television

    # Menus
    vicinae
    (rofi.override { plugins = [ rofi-calc ]; })

    # Controllers
    brightnessctl
    playerctl

    # Shells
    noctalia-shell
    dms-shell
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
    desktop-file-utils

    # Sway tools
    swaynotificationcenter
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
    jetbrains.pycharm

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
    ffmpeg
    v4l-utils

    # Nautilus
    nautilus
    sushi
    nautilus-open-any-terminal
    code-nautilus

    # Nix
    nix-prefetch-git

    # Fonts
    nerd-fonts.caskaydia-cove
    nerd-fonts.fira-code
    noto-fonts
    vazirmatn
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    libertinus

    # Music
    spotify
    #spicetify-cli
    amberol
    fum
    gapless

    # Videos
    vlc
    mpv

    # System monitor
    btop
    htop
    nvtopPackages.full
    mission-center

    # Stores
    flatpak # use it with flatpak --user ...
    gnome-software
    # inputs.nix-software-center.packages.${stdenv.hostPlatform.system}.nix-software-center

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
    flat-remix-icon-theme

    # Offices
    onlyoffice-desktopeditors
    libreoffice
    zathura

    # Windows
    winboat

    # Languages
    gcc
    python3
    matlab
    lua
    luarocks

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

  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  # https://wiki.nixos.org/wiki/Polkit
  services.polkit-gnome.enable = true;
}
