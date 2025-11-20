#!/usr/bin/env bash

CONFIG=${HYPRIDLE_CONFIG:-~/.config/hypr/hypridle.conf}

if pgrep -x "dms"; then
  systemctl --user stop swaync
  systemctl --user disable swaync
  exit 0
fi

if pgrep -fx "qs -c noctalia-shell"; then
  CONFIG="$HOME/.config/hypr/hypride-noctalia.conf"
fi

exec /usr/bin/hypridle -c "$CONFIG"
