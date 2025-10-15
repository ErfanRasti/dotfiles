#!/usr/bin/env bash
set +e # disable immediate exit on error

if [[ $SWAYNC_TOGGLE_STATE == true ]]; then
  { nmcli radio wifi on; } >/dev/null 2>&1 || :
else
  {
    rfkill unblock wifi
    nmcli radio wifi off
  } >/dev/null 2>&1 || :

fi

exit 0
