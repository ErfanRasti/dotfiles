#!/bin/bash

# Restore last wallpaper of waypaper
waypaper --restore

# Restart pyprland if running
pypr reload

# Restart waybar if running
if pgrep -x waybar >/dev/null; then
  pkill waybar
fi
setsid -f waybar >/dev/null 2>&1

# Restart swaync
if pgrep -x swaync >/dev/null; then
  pkill swaync
fi
setsid -f swaync >/dev/null 2>&1

# Restart hyprpolkitagent
systemctl --user restart hyprpolkitagent

# Apply spicetify
# spicetify apply
