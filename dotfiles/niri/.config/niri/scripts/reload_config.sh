#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/niri/config.kdl"

# Restart noctalia
if grep -q '^include "config/noctalia.kdl"' "$CONFIG_FILE"; then
  if pgrep -fx "qs -c noctalia-shell"; then
    pkill -fx "qs -c noctalia-shell"
  fi
  qs -c noctalia-shell
fi

# Restart dms
if grep -q '^include "config/dms.kdl"' "$CONFIG_FILE"; then
  if pgrep -x "dms"; then
    dms restart
  else
    dms run
  fi
fi

# Restart swayidle
if pgrep -x "swayidle"; then
  pkill -x swayidle
fi

"$HOME"/.config/niri/scripts/swayidle_ruuner.sh &
disown

# Restart gnome-polkit
if pgrep -f 'polkit-gnome-authentication-agent-1'; then
  pkill -f 'polkit-gnome-authentication-agent-1'
fi

sh -c "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 & disown"
