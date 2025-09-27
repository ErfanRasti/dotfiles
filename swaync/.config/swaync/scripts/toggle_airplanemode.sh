#!/usr/bin/env bash

if [[ $SWAYNC_TOGGLE_STATE == true ]]; then

  rfkill block all
  nmcli radio wifi off
  bluetooth power off
  notify-send -u "critical" -a "swaync" "󰀝 Airplane mode enabled"
else
  rfkill unblock all
  nmcli radio wifi on
  bluetooth power on
  notify-send -u "critical" -a "swaync" "󰀞 Airplane mode disabled"
fi
