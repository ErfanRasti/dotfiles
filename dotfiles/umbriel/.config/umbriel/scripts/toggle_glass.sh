#!/usr/bin/env bash
# Toggle the liquid glass window shader (effects/liquid_glass/) on all windows.
# Writes config/glass_effect.toml (optional include, git-ignored) and reloads umbriel.
# Bound to Mod+Alt+Shift+G.

config="$HOME/.config/umbriel/config/glass_effect.toml"

if [ -f "$config" ]; then
  rm -f "$config"
  state="on"
else
  printf '# Written by scripts/toggle_glass.sh: liquid glass shader off.\n[effects]\nwindow = ""\n' >"$config"
  state="off"
fi

umbriel msg config-reload >/dev/null 2>&1
notify-send -a umbriel -t 1500 "Liquid glass" "Window glass effect: $state" 2>/dev/null || true
