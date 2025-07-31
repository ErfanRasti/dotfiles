#!/bin/bash

WALLPAPER=$(jq -r '."wallpaper.image"' ~/.config/hyprpanel/config.json 2>/dev/null || grep -oP '"wallpaper.image":\s*"\K[^"]+' ~/.config/hyprpanel/config.json)

echo "$WALLPAPER"
