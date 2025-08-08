#!/bin/bash

# Get the first available capslock brightness file
caps_file=$(ls /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -n 1)

if [[ -z "$caps_file" ]]; then
  echo '{"error":"No Caps Lock LED found"}'
  exit 1
fi

# Check if Caps Lock is ON (1) or OFF (0)
if [[ $(cat "$caps_file") -eq 1 ]]; then
  echo '{"state":"CAPS ON"}'
fi
