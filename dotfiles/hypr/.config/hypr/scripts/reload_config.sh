#!/usr/bin/env bash

# Restore last wallpaper of waypaper
waypaper --restore

# Restart pyprland if running
pypr reload

# Restart waybar if running
if pgrep -x waybar >/dev/null; then
  pkill waybar
fi
setsid -f waybar >/dev/null 2>&1

# Restart ashell if running
# if pgrep -x ashell >/dev/null; then
#   pkill ashell
# fi
# setsid -f ashell >/dev/null 2>&1

# Restart swaync
if pgrep -x swaync >/dev/null; then
  pkill swaync
fi
setsid -f swaync >/dev/null 2>&1

# Restart kitty
# kitty +kitten themes --reload-in=all "Tokyo Night Moon"

# Restart hyprpolkitagent
systemctl --user restart hyprpolkitagent

# Apply spicetify
# spicetify apply
