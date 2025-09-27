#!/usr/bin/env bash

if [[ $SWAYNC_TOGGLE_STATE == true ]]; then
  systemctl --user stop hypridle.service
  systemctl --user start hypridle-coffee.service
  notify-send -u "critical" -a "swaync" "󰅶 Coffee mode enabled" "The screen won't turn off"

else
  systemctl --user stop hypridle-coffee.service
  systemctl --user start hypridle.service
  notify-send -u "critical" -a "swaync" "󰾪 Coffee mode disabled" "The screen will turn off"
fi
