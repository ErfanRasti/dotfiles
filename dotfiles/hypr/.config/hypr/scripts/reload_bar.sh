#!/usr/bin/env bash

AUTOSTART_FILE="$HOME/.config/hypr/config/autostart.conf"

# Restart waybar if set
if grep -q "^exec-once = waybar" "$AUTOSTART_FILE"; then
  echo "Found waybar exec-once"
  if pgrep -x waybar >/dev/null; then
    pkill waybar
  fi
  setsid -f waybar >/dev/null 2>&1

fi

# Restart ashell if set
if grep -q "^exec-once = ashell" "$AUTOSTART_FILE"; then
  echo "Found ashell exec-once"
  if pgrep -x ashell >/dev/null; then
    pkill ashell
  fi
  setsid -f ashell >/dev/null 2>&1

fi
