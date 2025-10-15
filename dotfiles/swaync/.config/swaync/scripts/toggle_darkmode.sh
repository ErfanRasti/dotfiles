#!/usr/bin/env bash
set +e # disable immediate exit on error

if [[ $SWAYNC_TOGGLE_STATE == true ]]; then
  { sed -i 's/-m "light"/-m "dark"/' ~/.config/waypaper/config.ini; } >/dev/null 2>&1 || :
else
  { sed -i 's/-m "dark"/-m "light"/' ~/.config/waypaper/config.ini; } >/dev/null 2>&1 || :
fi
{ setsid -f waypaper --restore; } >/dev/null 2>&1 || :

exit 0
