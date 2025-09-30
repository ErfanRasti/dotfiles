#!/usr/bin/env bash

if [[ $SWAYNC_TOGGLE_STATE == true ]]; then
  systemctl --user stop hypridle.service
  systemctl --user start hypridle-coffee.service
  notify-send -u "critical" -a "swaync" "󰅶 Coffee mode enabled" "The device won't suspend"

else
  systemctl --user stop hypridle-coffee.service
  systemctl --user start hypridle.service
  notify-send -u "critical" -a "swaync" "󰾪 Coffee mode disabled" "The device will suspend"
fi
