#!/usr/bin/env bash

AUTOSTART_FILE="$HOME/.config/hypr/config/autostart.conf"

# Restore last wallpaper of waypaper
waypaper --restore

# Restart pyprland if running
pypr reload

# Reload hyprpm state
hyprpm reload

# Reload bar
~/.config/hypr/scripts/reload_bar.sh

# Restart swaync
if grep -q "^exec-once = swaync" "$AUTOSTART_FILE"; then

  if pgrep -x swaync >/dev/null; then
    pkill swaync
  fi
  setsid -f swaync >/dev/null 2>&1
fi

# Restart swayosd
if grep -q "^exec-once = swayosd" "$AUTOSTART_FILE"; then
  if pgrep -x swayosd-server >/dev/null 2>&1; then
    pkill swayosd-server
  fi
  setsid -f swayosd-server >/dev/null 2>&1
fi

# Restart vicinae
if grep -q "^exec-once = systemctl --user start vicinae.service" "$AUTOSTART_FILE"; then
  systemctl --user restart vicinae.service
fi

# Restart hypr-dock
if grep -q "^exec-once = hypr-dock" "$AUTOSTART_FILE"; then
  if pgrep -x hypr-dock >/dev/null 2>&1; then
    pkill hypr-dock
  fi
  setsid -f hypr-dock >/dev/null 2>&1
fi

# Restart kitty
# kitty +kitten themes --reload-in=all "Tokyo Night Moon"

# Restart hyprpolkitagent
systemctl --user restart hyprpolkitagent

# Restart xdg-desktop-portal-hyprland
systemctl --user restart xdg-desktop-portal-hyprland
