#!/usr/bin/env bash
# Noctalia has no battery widget for the lockscreen, so the lockscreen shows a
# "label" widget (lockscreen-battery in settings.toml) and this script rewrites
# its text. Noctalia runs it from its battery/started/session_unlocked hooks.
# `config-set` writes to the state-dir override file, not the dotfiles repo.
#
# Never touches noctalia while the screen is locked: changing lockscreen widget
# config while locked crashes noctalia 5.4.1 (LockscreenWidgetsHost). The text is
# kept current while unlocked, so it is right at lock time; the session_unlocked
# hook catches up on whatever changed while locked.
#
# Kept cheap since it runs on every battery event: battery data comes from
# battery.sh's sysfs helpers (no forks), and noctalia is only messaged when
# something actually changed (several hooks often fire for one event).

source "$HOME/scripts/battery.sh" # sysfs helpers shared with hyprlock (scripts stow package)
battery_read || exit 0
BAT_PERCENT="${NOCTALIA_BATTERY_PERCENT:-$BAT_PERCENT}"
BAT_PERCENT="${BAT_PERCENT%%.*}"
battery_icon

case "$BAT_STATUS" in
"Not charging") BAT_STATUS="Plugged in" ;;
esac
title="$BAT_ICON  $BAT_PERCENT%"

cache="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
last="${XDG_RUNTIME_DIR:-$cache}/noctalia-lock-battery"
prev=""
[[ -f "$last" ]] && read -r prev <"$last"
[[ "$title|$BAT_STATUS" == "$prev" ]] && exit 0

# Several hooks fire for one event, and widgets_fit.sh edits the same state file;
# take turns, then check the lock (it may have come while waiting).
mkdir -p "$cache"
exec 9>"$cache/settings.lock"
flock 9
[[ "$(noctalia msg status 2>/dev/null)" == *'"locked": false'* ]] || exit 0 # retried on unlock

widget="lockscreen_widgets.widget.lockscreen-battery.settings"
noctalia msg config-set "$widget.title" "'$title'" >/dev/null &&
  noctalia msg config-set "$widget.description" "'$BAT_STATUS'" >/dev/null &&
  echo "$title|$BAT_STATUS" >"$last"
