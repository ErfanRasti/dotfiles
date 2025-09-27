#!/usr/bin/env bash

if [[ $SWAYNC_TOGGLE_STATE == true ]]; then
  sed -i 's/-m "light"/-m "dark"/' ~/.config/waypaper/config.ini
else
  sed -i 's/-m "dark"/-m "light"/' ~/.config/waypaper/config.ini
fi
setsid -f waypaper --restore >/dev/null 2>&1
