#!/usr/bin/env bash

# Get the current Hyprbars enabled state (int: 1 or int: 0)
state=$(hyprctl getoption plugin:dynamic-cursors:enabled | grep "int:" | awk '{print $2}')

# Toggle it
if [ "$state" -eq 1 ]; then
  hyprctl keyword plugin:dynamic-cursors:enabled false
  notify-send -u critical -a "Hyprland" "   Hypr-dynamic-cursors disabled"
else
  hyprctl keyword plugin:dynamic-cursors:enabled true
  notify-send -u critical -a "Hyprland" "  󰳽 Hypr-dynamic-cursors enabled"
fi
