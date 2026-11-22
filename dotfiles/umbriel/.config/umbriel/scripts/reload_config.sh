#!/usr/bin/env bash
# Mod+R: reload umbriel's config and restart noctalia + the idle daemon.

umbriel msg config-reload

"$HOME/.config/umbriel/scripts/reload_noctalia.sh"

pkill -x swayidle
setsid -f "$HOME/.config/umbriel/scripts/swayidle_runner.sh" >/dev/null 2>&1
