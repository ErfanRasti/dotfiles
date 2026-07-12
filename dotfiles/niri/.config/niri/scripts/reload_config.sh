#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/niri/config.kdl"
CONFIG_AUTOSTART_FILE="$HOME/.config/niri/config/autostarts.kdl"

# Restart noctalia
if grep -q '^include "config/noctalia.kdl"' "$CONFIG_FILE"; then
  pkill -x dms
  pkill -x dsearch
  if pgrep -f "noctalia"; then
    pkill -f "noctalia"
  fi
  # noctalia has its own polkit
  systemctl --user stop polkit-gnome.service

  noctalia &
  disown
else
  # polkit-gnome restart
  systemctl --user restart polkit-gnome.service
fi

# Restart dms
if grep -q '^include "config/dms.kdl"' "$CONFIG_FILE"; then
  pkill -x qs
  pkill -f dms
  pkill -x dsearch
  dsearch serve
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

"$HOME"/.config/niri/scripts/swayidle_runner.sh &
disown

# Restart gnome-polkit
# if grep -q '^spawn-sh-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"' "$CONFIG_AUTOSTART_FILE"; then
#   if pgrep -f 'polkit-gnome-authentication-agent-1'; then
#     pkill -f 'polkit-gnome-authentication-agent-1'
#   fi
#
#   sh -c "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 & disown"
# fi
