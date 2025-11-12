#!/usr/bin/env bash

if pgrep -x rofi >/dev/null; then
  pkill rofi
else
  ~/.config/rofi/launcher/run.sh "$1"
fi
