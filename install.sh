#!/usr/bin/env bash

help() {
  echo "Usage: $0 [OPTION]"
  echo
  echo "Options:"
  echo "  (no arguments)        Continue without enabling niri-shells installation"
  echo "  -ns, --niri-shells    Enable niri-shells installation flag"
  echo "  -h,  --help           Show this help message"
}

NIRI_SHELLS=false
case "$1" in
"")
  # No argument passed → do nothing
  ;;

-h | --help)
  help
  exit 0
  ;;

-ns | --niri-shells)
  NIRI_SHELLS=true
  ;;

*)
  echo "Error: Unknown option '$1'"
  echo
  help
  exit 1
  ;;
esac

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
  wayland gnome polkit-gnome \
  gdm \
  egl-wayland \
  zsh-autosuggestions zsh-syntax-highlighting \
  fish pkgfile inetutils \
  nautilus-python python-dbus \
  hyprland vim wget curl \
  hyprland \
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
  yazi ouch dragon mediainfo \
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
  hyprsunset \
  hyprland-qtutils \
  foot fzf chafa jq bat \
  pixman \
  libpng \
  wl-clipboard wl-clip-persist \
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
  btop nvtop \
  bluez bluez-utils \
  dosfstools \
  swww \
  sbctl \
  gpsd upower \
  power-profiles-daemon \
  inotify-tools \
  breeze-icons \
  wev \
  acpi \
  npm \
  alsa-utils \
  cava \
  zenity \
  ttf-cascadia-code-nerd \
  niri xwayland-satellite \
  cmatrix \
  kdeconnect

echo "✅ pacman packages installed successfully!"

echo "------------------- AUR packages -------------------"
paru
paru -S \
  envycontrol \
  nix-zsh-completions \
  zsh-nix-shell \
  shell-color-scripts-git \
  tabby \
  zsh-theme-powerlevel10k zsh-autocomplete zsh-fast-syntax-highlighting zsh-vi-mode \
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
  rofi-tools-bin \
  pwvucontrol \
  overskride-bin \
  clipse-bin \
  matugen-bin \
  waypaper \
  python-pywalfox \
  fum-bin \
  actions-for-nautilus-git nautilus-admin-gtk4 nautilus-checksums nautilus-image-converter nautilus-share \
  flat-remix \
  ashell \
  unimatrix-git pipes.sh \
  nitch \
  hypr-dock \
  bibata-cursor-theme-bin \
  gitfetch-python \
  wdisplays

echo "!!!!!!!!!!!!!! niri-shells installation"
$NIRI_SHELLS && paru -S \
  noctalia-shell wlsunset \
  dms-shell-git dsearch qt6-multimedia \
  vicinae-bin

echo "✅ AUR packages installed successfully!"

echo "------------------- flatpak packages -------------------"
# flatpak packages
flatpak update
flatpak install flathub com.dec05eba.gpu_screen_recorder
flatpak install flathub io.missioncenter.MissionCenter
flatpak install flathub app.devsuite.Ptyxis

flatpak override --user \
  --filesystem=xdg-config/gtk-2.0:ro \
  --filesystem=xdg-config/gtk-3.0:ro \
  --filesystem=xdg-config/gtk-4.0:ro \
  --filesystem=~/.gtkrc-2.0:ro

flatpak override --user \
  --filesystem=xdg-config/qt5ct:ro \
  --filesystem=xdg-config/qt6ct:ro \
  --env=QT_QPA_PLATFORMTHEME=qt6ct

echo "✅ flatpak packages installed successfully!"

echo "------------------- hyprpm packages -------------------"
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm add https://github.com/KZDKM/Hyprspace
hyprpm add https://github.com/VirtCode/hypr-dynamic-cursors
hyprpm add https://github.com/zakk4223/hyprland-easymotion
hyprpm add https://github.com/outfoxxed/hy3
hyprpm update
hyprpm enable hyprexpo
hyprpm enable hyprscrolling
hyprpm enable hyprfocus
hyprpm enable xtra-dispatchers
hyprpm enable dynamic-cursors
hyprpm enable hyprEasymotion
hyprpm enable hy3
hyprpm reload

echo "✅ hyprpm packages installed successfully!"

echo "------------------- dotfiles -------------------"
git clone --recurse-submodules https://github.com/ErfanRasti/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles/dotfiles/" || exit

# shellcheck disable=SC2035
stow */

waypaper --wallpaper ~/wallpapers/School/arseniy-chebynkin-school-enter2.jpg

echo "✅ dotfiles installed successfully!"

echo "------------------- settings -------------------"
gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'
nautilus -q

echo "✅ settings applied successfully!"

echo "------------------- enable services -------------------"
systemctl --user reenable ydotoold.service
systemctl --user restart ydotoold.service

systemctl --user reenable hypridle-runner.service
systemctl --user restart hypridle-runner.service

systemctl --user reenable hyprpolkitagent.service
systemctl --user restart hyprpolkitagent.service

systemctl --user reenable gpu-screen-recorder-ui.service
systemctl --user restart gpu-screen-recorder-ui.service

echo "✅ services enabled and started!"

echo "------------------- fish configurations -------------------"
fisher update
chsh -s "$(which bash)"
fish_update_completions
tide configure --auto --style=Lean --prompt_colors='16 colors' --show_time='24-hour format' --lean_prompt_height='One line' --prompt_spacing=Compact --icons='Many icons' --transient=No
fisher install vitallium/tokyonight-fish
fish_config theme save "TokyoNight Moon"
# tide configure

echo "------------------- yazi plugins -------------------"
ya pkg add yazi-rs/plugins:toggle-pane
ya pack -a h-hg/yamb
ya pkg add ndtoan96/ouch
ya pkg add yazi-rs/plugins:smart-enter
ya pkg add grappas/wl-clipboard
ya pkg add MasouShizuka/projects
ya pkg add yazi-rs/plugins:diff
ya pkg add yazi-rs/plugins:zoom
ya pkg add yazi-rs/plugins:vcs-files
ya pkg add boydaihungst/mediainfo
ya pkg add yazi-rs/plugins:mount

echo "✅ fish configured successfully!"
