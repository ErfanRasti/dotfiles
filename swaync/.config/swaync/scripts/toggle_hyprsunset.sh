#!/usr/bin/env bash

if [[ $SWAYNC_TOGGLE_STATE == true ]]; then
  systemctl --user start hyprsunset.service
else
  systemctl --user stop hyprsunset.service
fi
