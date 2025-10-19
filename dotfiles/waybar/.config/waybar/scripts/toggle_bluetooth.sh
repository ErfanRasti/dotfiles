#!/usr/bin/env bash
set +e # disable immediate exit on error

if bluetoothctl show | grep -q "Powered: yes"; then
  { bluetoothctl power off; } >/dev/null 2>&1 || :
else
  {
    rfkill unblock bluetooth
    bluetoothctl power on
  } >/dev/null 2>&1 || :
fi

exit 0
