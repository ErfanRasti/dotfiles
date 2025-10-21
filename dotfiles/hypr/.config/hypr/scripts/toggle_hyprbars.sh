#!/usr/bin/env bash

# Get the current Hyprbars enabled state (int: 1 or int: 0)
state=$(hyprctl getoption plugin:hyprbars:enabled | grep "int:" | awk '{print $2}')

# Toggle it
if [ "$state" -eq 1 ]; then
  hyprctl keyword plugin:hyprbars:enabled false
  notify-send -u critical -a "Hyprland" "   Hyprbars Disabled"
else
  hyprctl keyword plugin:hyprbars:enabled true
  notify-send -u critical -a "Hyprland" "   Hyprbars Enabled"
fi
