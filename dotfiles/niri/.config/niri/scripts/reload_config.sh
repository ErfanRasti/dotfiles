#!/usr/bin/env bash
CONFIG_FILE="$HOME/.config/niri/config.kdl"

if grep -q '^include "config/noctalia.kdl"' "$CONFIG_FILE"; then
  if pgrep -fx "qs -c noctalia-shell"; then
    pkill -fx "qs -c noctalia-shell"
  fi
  qs -c noctalia-shell
fi

if grep -q '^include "config/dms.kdl"' "$CONFIG_FILE"; then
  if pgrep -x "dms"; then
    dms restart
    exit 0
  fi
  dms run
fi

systemctl --user restart hypridle-runner.service

if pgrep -f 'polkit-gnome-authentication-agent-1'; then
  pkill -f 'polkit-gnome-authentication-agent-1'
fi

sh -c "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 & disown"
