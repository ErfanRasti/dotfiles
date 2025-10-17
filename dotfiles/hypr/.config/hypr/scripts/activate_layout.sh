#!/usr/bin/env bash

# Check if an argument was provided
if [ -z "$1" ]; then
  echo "Usage: $0 [gamemode|smartgaps|dwindle|master|scrolling|hy3]"
  exit 1
fi

case "$1" in
gamemode)
  ~/.config/hypr/scripts/toggle_gamemode.sh
  # Do not add `hyprctl reload` to have this feature with other layouts
  notify-send -u critical -a "Hyprland" " 󰊗 Hyprland game mode toggled"
  ;;
smartgaps)
  ~/.config/hypr/scripts/toggle_smartgaps.sh
  # Do not add `hyprctl reload` to have this feature with other layouts
  notify-send -u critical -a "Hyprland" "  Hyprland smart gaps toggled"
  ;;
dwindle)
  hyprctl reload
  hyprctl keyword general:layout dwindle
  notify-send -u critical -a "Hyprland" "  Hyprland dwindle layout activated"
  ;;
master)
  hyprctl reload
  hyprctl keyword general:layout master
  notify-send -u critical -a "Hyprland" " 󱌼 Hyprland master layout activated"
  ;;
scrolling)
  hyprctl reload
  hyprctl keyword source ~/.config/hypr/config/keybindings-hyprscrolling.conf
  hyprctl keyword general:layout scrolling
  notify-send -u critical -a "Hyprland" "  Hyprland scrolling layout activated"
  ;;
hy3)
  hyprctl reload
  hyprctl keyword source ~/.config/hypr/config/keybindings-hy3.conf
  hyprctl keyword general:layout hy3
  notify-send -u critical -a "Hyprland" " 󰲤 Hyprland hy3 layout activated"
  ;;
*)
  echo "Invalid option: $1"
  echo "Usage: $0 [gamemode|smartgaps|dwindle|master|scrolling]"
  exit 1
  ;;
esac
