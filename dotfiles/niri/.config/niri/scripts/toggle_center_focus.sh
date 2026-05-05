#!/bin/bash

config="$HOME/.config/niri/config/overwrites.kdl"

mkdir -p "$(dirname "$config")"

if grep -q 'center-focused-column "on-overflow"' "$config"; then
  sed -i 's/center-focused-column "on-overflow"/center-focused-column "always"/' "$config"
else
  sed -i 's/center-focused-column "always"/center-focused-column "on-overflow"/' "$config"
fi

niri msg action load-config-file
