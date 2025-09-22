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

# Apply spicetify
spicetify apply
