#!/usr/bin/env bash

CONFIG=${HYPRIDLE_CONFIG:-~/.config/hypr/hypridle.conf}
exec /usr/bin/hypridle -c "$CONFIG"
