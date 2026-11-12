#!/usr/bin/env bash
# swayidle for umbriel (port of niri/scripts/swayidle_runner.sh)
# Check https://man.archlinux.org/man/extra/swayidle/swayidle.1.en

lock_cmd='noctalia msg session lock'

swayidle -w \
  lock "$lock_cmd" \
  before-sleep 'loginctl lock-session;~/scripts/system_resume.sh save' \
  after-resume 'umbriel msg dpms-on;~/scripts/system_resume.sh restore;howdy-background-unlock' \
  timeout 150 'brightnessctl -s set 5%' resume 'brightnessctl -r' \
  timeout 160 'brightnessctl -sd asus::kbd_backlight set 0' resume 'brightnessctl -rd asus::kbd_backlight' \
  timeout 300 'loginctl lock-session' \
  timeout 330 'umbriel msg dpms-off' resume 'umbriel msg dpms-on && brightnessctl -r' \
  timeout 360 'systemctl suspend'
