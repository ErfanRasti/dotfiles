#!/usr/bin/env bash
CONFIG_FILE="$HOME/.config/niri/config.kdl"

if grep -q '^spawn-at-startup "qs" "-c" "noctalia-shell"' "$CONFIG_FILE"; then
  if pgrep -fx "qs -c noctalia-shell"; then
    pkill -fx "qs -c noctalia-shell"
  fi
  qs -c noctalia-shell
fi

if grep -q '^spawn-at-startup "dms" "run"' "$CONFIG_FILE"; then
  if pgrep -x "dms"; then
    dms restart
    exit 0
  fi
  dms run
fi
