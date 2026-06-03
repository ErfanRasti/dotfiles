#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/hypr/hyprland.lua"
CONFIG_AUTOSTART_FILE="$HOME/.config/hypr/config/autostart.lua"

# Restore last wallpaper of waypaper
# waypaper --restore

# Restart pyprland if running
pypr reload

# Reload hyprpm state
hyprpm reload

# Replace packages
replace_packages() {
  pkill swaync
  pkill swayosd-server
  pkill waybar
  pkill ashell
  pkill swww-daemon
  systemctl --user stop vicinae.service
  systemctl --user stop hypridle-runner.service
  systemctl --user stop hyprsunset.service

  if pgrep -x "swayidle"; then
    pkill -x swayidle
  fi
  ~/.config/hypr/scripts/swayidle_ruuner.sh &
  disown
}

# Reload bar
pkill qs
export CONFIG_FILE
export CONFIG_AUTOSTART_FILE
~/.config/hypr/scripts/reload_bar.sh &
disown

if ! grep -q '^require("config\.noctalia")' "$CONFIG_FILE" &&
  ! grep -q '^require("config\.dms")' "$CONFIG_FILE"; then
  pkill swayidle

  # \s = any whitespace character (spaces, tabs, newlines, carriage returns, form feeds)
  # \+ = one or more of the preceding character (same as {1,})
  # So \s\+ = one or more whitespace characters

  # Restart swww
  if grep -q '^\s\+hl\.exec_cmd("swww-daemon")' "$CONFIG_AUTOSTART_FILE"; then

    if pgrep -x swww-daemon >/dev/null; then
      pkill -x swww-daemon
    fi
    setsid -f swww-daemon >/dev/null 2>&1
  fi

  # Restart hyprpaper
  if grep -q '^\s\+hl\.exec_cmd("hyprpaper")' "$CONFIG_AUTOSTART_FILE"; then

    if pgrep -x hyprpaper >/dev/null; then
      pkill -x hyprpaper
    fi
    setsid -f hyprpaper >/dev/null 2>&1
  fi

  # Restart swaync
  if grep -q '^\s\+hl\.exec_cmd("swaync")' "$CONFIG_AUTOSTART_FILE"; then

    if pgrep -x swaync >/dev/null; then
      pkill swaync
    fi
    setsid -f swaync >/dev/null 2>&1
  fi

  # Restart swayosd
  if grep -q '^\s\+hl\.exec_cmd("swayosd")' "$CONFIG_AUTOSTART_FILE"; then
    if pgrep -x swayosd-server >/dev/null 2>&1; then
      pkill swayosd-server
    fi
    setsid -f swayosd-server >/dev/null 2>&1
  fi

  # Restart vicinae
  if grep -q '^\s\+hl\.exec_cmd("systemctl --user start vicinae\.service")' "$CONFIG_AUTOSTART_FILE"; then
    systemctl --user restart vicinae.service
  fi

  # Restart hypr-dock
  if grep -q '^\s\+hl\.exec_cmd("hypr-dock")' "$CONFIG_AUTOSTART_FILE"; then
    if pgrep -x hypr-dock >/dev/null 2>&1; then
      pkill hypr-dock
    fi
    setsid -f hypr-dock >/dev/null 2>&1
  fi
else
  replace_packages
fi

# Restart kitty
# kitty +kitten themes --reload-in=all "Tokyo Night Moon"

# Restart hyprpolkitagent
systemctl --user restart hyprpolkitagent

# Restart xdg-desktop-portal-hyprland
systemctl --user restart xdg-desktop-portal-hyprland
