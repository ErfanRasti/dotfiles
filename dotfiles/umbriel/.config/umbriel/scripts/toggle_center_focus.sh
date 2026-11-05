#!/usr/bin/env bash
# Toggle the scrolling layout's center_focused between "on_overflow" and "always".
# Writes config/overwrites.toml (optional include, git-ignored) and reloads umbriel.
# Bound to Mod+C (Mod+Shift+C centers the column once).

config="$HOME/.config/umbriel/config/overwrites.toml"

mkdir -p "$(dirname "$config")"
touch "$config"

if ! grep -q 'center_focused' "$config"; then
  printf '[layout.scrolling]\ncenter_focused = "always"\n' >>"$config"
  mode="always"
elif grep -q 'center_focused = "on_overflow"' "$config"; then
  sed -i 's/center_focused = "on_overflow"/center_focused = "always"/' "$config"
  mode="always"
else
  sed -i 's/center_focused = "always"/center_focused = "on_overflow"/' "$config"
  mode="on_overflow"
fi

umbriel msg config-reload >/dev/null 2>&1
notify-send -a umbriel -t 1500 "Center focus" "Focused column centering: $mode" 2>/dev/null || true
