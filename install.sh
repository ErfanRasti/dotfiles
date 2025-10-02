#!/usr/bin/env bash

echo "------------------- paru installation -------------------"

# Check if paru is installed
if command -v paru >/dev/null 2>&1; then
  echo "✅ paru is already installed."
else
  echo "⚡ paru not found. Installing..."
  mkdir -p "$HOME/programs"
  cd "$HOME/programs" || exit

  sudo pacman -S --needed base-devel
  git clone https://aur.archlinux.org/paru.git
  cd "paru" || exit
  makepkg -si

  echo "✅ paru installed successfully!"
fi

echo "------------------- pacman packages -------------------"
sudo pacman -Syu
sudo pacman -S \
  linux-headers \
  linux-firmware \
  base-devel \
  bluez \
  bluez-utils \
  noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra \
  dconf \
  wayland gnome \
  gdm \
  egl-wayland \
  zsh-autosuggestions zsh-syntax-highlighting \
  fish pkgfile inetutils \
  nautilus-python python-dbus \
  hyprland vim wget curl kitty \
  hyprland \
  kitty \
  shfmt stylua \
  svn \
  git-delta \
  eza \
  wireplumber \
  ripgrep \
  evolution-data-server \
  python-icalendar \
  python-tzlocal \
  yq fd \
  glow \
  lazydocker \
  yazi \
  zellij \
  git stow \
  trash-cli \
  ttf-font-awesome \
  woff2-font-awesome tree \
  fisher \
  adwaita-icon-theme hicolor-icon-theme \
  xdg-desktop-portal \
  adw-gtk-theme \
  xdg-desktop-portal-gnome \
  mesa vulkan-intel \
  xdg-desktop-portal-gtk \
  gnome-shell gnome-session gjs \
  gtk3 gtk4 glib2 \
  qt5-base qt6-base qt5-wayland qt6-wayland \
  qt6 \
  timeshift \
  brightnessctl \
  cliphist \
  hyprshot \
  hypridle \
  hyprlock \
  rofi \
  hyprpaper \
  hyprsunset hyprpicker \
  bash zsh fish nvim tmux flatpak zoxide lazygit kitty ghostty \
  xdg-desktop-portal-hyprland \
  feh \
  papirus-icon-theme \
  hyprcursor \
  zathura \
  zathura-pdf-poppler \
  television \
  waybar \
  hyprpolkitagent \
  mpc \
  hyprsunset \
  hyprland-qtutils \
  foot fzf chafa jq \
  pixman \
  libpng \
  wl-clipboard \
  cpio cmake git meson gcc \
  mpv \
  hyprshot \
  libxkbcommon \
  showmethekey \
  wmctrl xdotool \
  libpulse \
  xdg-desktop-portal-hyprland \
  playerctl \
  swaync \
  wiremix \
  swayosd \
  rofimoji \
  gnome-color-manager \
  gamemode \
  nm-connection-editor \
  ydotool \
  rofi-calc \
  udiskie \
  superfile \
  btop \
  bluez bluez-utils \
  dosfstools \
  swww \
  sbctl \
  gpsd upower \
  power-profiles-daemon \
  inotify-tools \
  breeze-icons

echo "✅ pacman packages installed successfully!"

echo "------------------- AUR packages -------------------"
paru
paru -S \
  envycontrol \
  nix-zsh-completions \
  zsh-nix-shell \
  shell-color-scripts-git \
  tabby \
  zsh-theme-powerlevel10k zsh-autocomplete zsh-fast-syntax-highlighting \
  ascii-image-converter \
  sesh-bin \
  apple-fonts \
  hyprsysteminfo \
  qt6ct-kde qt5ct-kde \
  spicetify-cli \
  spotify \
  libinput-gestures \
  better-control-git \
  pyprland \
  flat-remix \
  rofi-tools-bin \
  pwvucontrol \
  overskride-bin \
  clipse-bin clipse-gui \
  matugen-bin \
  waypaper

echo "✅ AUR packages installed successfully!"

echo "------------------- flatpak packages -------------------"
# flatpak packages
flatpak install flathub com.dec05eba.gpu_screen_recorder

echo "✅ flatpak packages installed successfully!"

echo "------------------- hyprpm packages -------------------"
# hyprpm
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm add https://github.com/KZDKM/Hyprspace

echo "✅ hyprpm packages installed successfully!"

echo "------------------- dotfiles -------------------"
git clone --recurse-submodules https://github.com/ErfanRasti/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles/" || exit
stow */
waypaper --wallpaper ~/wallpapers/School/arseniy-chebynkin-school-enter2.jpg

echo "✅ dotfiles installed successfully!"

echo "------------------- fish configurations -------------------"
fisher update
chsh -s "$(which bash)"
fish_update_completions

echo "✅ fish configured successfully!"
