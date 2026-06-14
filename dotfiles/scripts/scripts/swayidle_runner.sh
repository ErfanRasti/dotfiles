#!/usr/bin/env bash

# This script runs the swayidle
# Check https://man.archlinux.org/man/extra/swayidle/swayidle.1.en

swayidle -w \
  lock "loginctl lock-session" \
  before-sleep 'loginctl lock-session;~/scripts/system_resume.sh save' \
  after-resume 'niri msg action power-on-monitors;~/scripts/system_resume.sh restore' \
  timeout 150 'brightnessctl -s set 5%' resume 'brightnessctl -r' \
  timeout 160 'brightnessctl -sd asus::kbd_backlight set 0' resume 'brightnessctl -rd asus::kbd_backlight' \
  timeout 300 'loginctl lock-session' \
  timeout 330 'niri msg action power-off-monitors' resume 'niri msg action power-on-monitors && brightnessctl -r' \
  timeout 360 'systemctl suspend'
