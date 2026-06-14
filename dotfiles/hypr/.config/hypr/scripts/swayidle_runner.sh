#!/usr/bin/env bash

# This script runs the swayidle for Hyprland
# Check https://man.archlinux.org/man/extra/swayidle/swayidle.1.en

lock_cmd='hyprlock'

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

if grep -q "^source = ~/.config/hypr/config/noctalia.conf" "$CONFIG_FILE"; then
  lock_cmd='qs -c noctalia-shell ipc call lockScreen lock'
elif grep -q "^source = ~/.config/hypr/config/dms.conf" "$CONFIG_FILE"; then
  lock_cmd='dms ipc call lock lock'
fi

swayidle -w \
  lock "$lock_cmd" \
  before-sleep 'loginctl lock-session;~/.config/hypr/scripts/hypr_resume.sh save' \
  after-resume 'niri msg action power-on-monitors;~/.config/hypr/scripts/hypr_resume.sh restore' \
  timeout 150 'brightnessctl -s set 5%' resume 'brightnessctl -r' \
  timeout 160 'brightnessctl -sd asus::kbd_backlight set 0' resume 'brightnessctl -rd asus::kbd_backlight' \
  timeout 300 'loginctl lock-session' \
  timeout 330 'niri msg action power-off-monitors' resume 'niri msg action power-on-monitors && brightnessctl -r' \
  timeout 360 'systemctl suspend'
