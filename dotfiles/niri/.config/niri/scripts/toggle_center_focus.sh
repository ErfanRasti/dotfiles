#!/bin/bash

config="$HOME/.config/niri/config/overwrites.kdl"

mkdir -p "$(dirname "$config")"
touch "$config"

if ! grep -q 'center-focused-column' "$config"; then
  cat >>"$config" <<EOF
layout {
  center-focused-column "always"
}
EOF
elif grep -q 'center-focused-column "on-overflow"' "$config"; then
  sed -i 's/center-focused-column "on-overflow"/center-focused-column "always"/' "$config"
else
  sed -i 's/center-focused-column "always"/center-focused-column "on-overflow"/' "$config"
fi

niri msg action load-config-file
