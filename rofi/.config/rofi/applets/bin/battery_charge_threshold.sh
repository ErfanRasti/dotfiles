#!/usr/bin/env bash

theme="~/.config/rofi/applets/style-battery-threshold.rasi"

# Read current threshold
CURRENT_THRESHOLD=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo "Unknown")

# Build the placeholder text first
PLACEHOLDER="Set Threshold \n(Current: $CURRENT_THRESHOLD%)"

# Rofi command with style
NEW_THRESHOLD=$(
  rofi -dmenu \
    -theme ${theme} \
    -theme-str "entry { placeholder: \"$PLACEHOLDER\"; }"
)

# Exit if no input
[[ -z "$NEW_THRESHOLD" ]] && exit 0

# Validate input
if [[ "$NEW_THRESHOLD" =~ ^[0-9]+$ ]] && ((NEW_THRESHOLD >= 1 && NEW_THRESHOLD <= 100)); then
  if pkexec --user root bash -c "echo $NEW_THRESHOLD > /sys/class/power_supply/BAT0/charge_control_end_threshold"; then
    notify-send -u normal -i battery "Threshold Updated" "New: $NEW_THRESHOLD% (Was: $CURRENT_THRESHOLD%)"
  else
    notify-send -u critical -i dialog-error "Error" "Failed to set threshold"
  fi
else
  notify-send -u low -i dialog-warning "Invalid Input" "Enter a number (1-100)"
fi
