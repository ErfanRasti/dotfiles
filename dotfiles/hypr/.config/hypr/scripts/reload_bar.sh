#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
CONFIG_AUTOSTART_FILE="$HOME/.config/hypr/config/autostart.conf"

# Restart noctalia
if grep -q "^source = ~/.config/hypr/config/noctalia.conf" "$CONFIG_FILE"; then
  if pgrep -fx "qs -c noctalia-shell"; then
    pkill -fx "qs -c noctalia-shell"
  fi
  qs -c noctalia-shell &
  disown

# Restart dms
elif grep -q "^source = ~/.config/hypr/config/dms.conf" "$CONFIG_FILE"; then
  if pgrep -x "dms"; then
    dms restart
  else
    dms run
  fi
else
  # Restart waybar if set
  if grep -q "^exec-once = waybar" "$CONFIG_AUTOSTART_FILE"; then
    echo "Found waybar exec-once"
    if pgrep -x waybar >/dev/null; then
      pkill waybar
    fi
    setsid -f waybar >/dev/null 2>&1
  fi

  # Restart ashell if set
  if grep -q "^exec-once = ashell" "$CONFIG_AUTOSTART_FILE"; then
    echo "Found ashell exec-once"
    if pgrep -x ashell >/dev/null; then
      pkill ashell
    fi
    setsid -f ashell >/dev/null 2>&1
  fi
fi
