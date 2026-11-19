#!/usr/bin/env bash
# swayidle for Hyprland with a desktop shell (same timers as umbriel's swayidle_runner.sh).
# Usage: swayidle_runner.sh <noctalia|dms>   (started by config/autostart.lua)
# Without a shell, hypridle (hypridle-runner.service) is used instead.
# https://man.archlinux.org/man/extra/swayidle/swayidle.1.en

shell="${1:-$(sed -n 's/^DESKTOP_SHELL = "\([a-z]*\)".*/\1/p' "$HOME/.config/hypr/hyprland.lua")}"

dpms_on="hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'"
dpms_off="hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'"
after_resume="$dpms_on;$HOME/scripts/system_resume.sh restore"

case "$shell" in
noctalia)
  lock_cmd='noctalia msg session lock'
  after_resume="$HOME/.config/noctalia/scripts/lock_widgets_resume.sh & $after_resume;howdy-background-unlock"
  ;;
dms) lock_cmd='dms ipc call lock lock' ;;
*) lock_cmd='hyprlock' ;;
esac

exec swayidle -w \
  lock "$lock_cmd" \
  before-sleep 'loginctl lock-session;~/scripts/system_resume.sh save' \
  after-resume "$after_resume" \
  timeout 150 'brightnessctl -s set 5%' resume 'brightnessctl -r' \
  timeout 160 'brightnessctl -sd asus::kbd_backlight set 0' resume 'brightnessctl -rd asus::kbd_backlight' \
  timeout 300 'loginctl lock-session' \
  timeout 330 "$dpms_off" resume "$dpms_on && brightnessctl -r" \
  timeout 360 'systemctl suspend'
