#!/bin/bash

# Restore last wallpaper of waypaper
waypaper --restore

# Restart pyprland if running
pypr reload

# Restart waybar if running
if pgrep -x waybar >/dev/null; then
  pkill waybar
fi
waybar &

# Restart hyprpolkitagent
systemctl --user restart hyprpolkitagent

# Apply spicetify
spicetify apply
