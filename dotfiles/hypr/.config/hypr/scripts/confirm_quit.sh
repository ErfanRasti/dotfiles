#!/usr/bin/env bash
# SUPER+SHIFT+Q: ask before quitting Hyprland (like umbriel's session-quit), then quit gracefully.
# The prompt is rofi (theme: rofi/applets/styles/confirm.rasi), so it works with the keyboard:
# arrows/Tab + Enter, type to filter (q -> Quit), Escape cancels; the mouse works too.
# (hyprland-dialog was used before, but its buttons can only be clicked.)
# hyprshutdown asks every app to close (so they can save) before Hyprland exits.

theme="$HOME/.config/rofi/applets/styles/confirm.rasi"
quit="󰍃  Quit"
cancel="󰜺  Cancel"
title="<span size='x-large' weight='bold'>Quit Hyprland?</span>"
subtitle="<span alpha='70%'>Open apps will be asked to close first.</span>"

# rofi allows one instance at a time, so pressing the key again while it is open does nothing.
# -u 0 marks Quit as "urgent": the theme draws it in the error (destructive) colors.
answer="$(printf '%s\n%s\n' "$quit" "$cancel" | rofi -dmenu -i -no-custom \
  -u 0 \
  -mesg "$title"$'\n'"$subtitle" \
  -theme "$theme")"
[[ "$answer" == "$quit" ]] || exit 0

if command -v hyprshutdown >/dev/null 2>&1; then
  exec hyprshutdown
fi
exec hyprctl dispatch 'hl.dsp.exit()'
