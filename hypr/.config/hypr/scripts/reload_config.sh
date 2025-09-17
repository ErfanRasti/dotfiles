#!/bin/bash

waypaper --restore

# Restart waybar if running
if pgrep -x waybar >/dev/null; then
  pkill waybar
fi
waybar &

# Restart pyprland if running
if pgrep -x pypr >/dev/null; then
  pkill pypr
fi
pypr &

# Apply spicetify
spicetify apply
