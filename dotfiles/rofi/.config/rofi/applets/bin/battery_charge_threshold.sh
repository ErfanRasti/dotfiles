#!/usr/bin/env bash

theme="$HOME/.config/rofi/applets/style-battery-threshold.rasi"

# Build the placeholder text first
PLACEHOLDER="Set Threshold \n(Current: $CURRENT_THRESHOLD)"

# Rofi command with style
NEW_THRESHOLD=$(
  rofi -dmenu \
    -theme "${theme}" \
    -theme-str "entry { placeholder: \"$PLACEHOLDER\"; }"
)

# Exit if no input
[[ -z "$NEW_THRESHOLD" ]] && exit 0

notify_failed_to_set() {
  notify-send -u critical -i dialog-error "Error" "Failed to set threshold"
}

# Mode
if [ "$MODE" -eq 0 ]; then
  # Validate input
  if [[ "$NEW_THRESHOLD" =~ ^[0-9]+$ ]] && ((NEW_THRESHOLD >= 1 && NEW_THRESHOLD <= 100)); then
    if pkexec --user root bash -c "echo $NEW_THRESHOLD > $PATH0"; then
      notify-send -u normal "󱈑 Threshold Updated" "New: $NEW_THRESHOLD% (Was: $CURRENT_THRESHOLD)"
    else
      notify_failed_to_set
    fi
  else
    notify-send -u low -i dialog-warning "Invalid Input" "Enter a number from 0 to 100"
  fi

else
  # Validate input
  if [[ "$NEW_THRESHOLD" = "0" || "$NEW_THRESHOLD" = "1" ]]; then
    if pkexec --user root bash -c "echo $NEW_THRESHOLD > $PATH1"; then
      notify-send -u normal "󱈑 Threshold Updated" "New: $([[ "$NEW_THRESHOLD" == "1" ]] && echo "Enabled" || echo "Disabled") (Was: $CURRENT_THRESHOLD)"
    else
      notify_failed_to_set
    fi
  else
    notify-send -u low -i dialog-warning "Invalid Input" "Enter 0 to disable and 1 to enable"
  fi
fi
