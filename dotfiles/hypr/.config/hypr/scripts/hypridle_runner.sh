#!/usr/bin/env bash

CONFIG=${HYPRIDLE_CONFIG:-~/.config/hypr/hypridle.conf}

if pgrep -fx "qs -c noctalia-shell"; then
  CONFIG="$HOME/.config/hypr/hypride-noctalia.conf"
fi

exec /usr/bin/hypridle -c "$CONFIG"
