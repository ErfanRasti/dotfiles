#!/usr/bin/env bash
# Mod+R: reload umbriel's config and restart noctalia + the idle daemon.

umbriel msg config-reload

# noctalia ships its own polkit agent, so stop the GNOME one first.
systemctl --user stop polkit-gnome.service
pkill -f '^noctalia( |$)'   # the process shows up as ".noctalia-wrapped" on NixOS
# Wait for it to exit: its single-instance lock makes a new one quit otherwise.
for _ in {1..30}; do pgrep -f '^noctalia( |$)' >/dev/null || break; sleep 0.1; done
setsid -f noctalia >/dev/null 2>&1

pkill -x swayidle
setsid -f "$HOME/.config/umbriel/scripts/swayidle_runner.sh" >/dev/null 2>&1
