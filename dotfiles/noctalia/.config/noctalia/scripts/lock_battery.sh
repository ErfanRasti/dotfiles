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
text="$BAT_ICON  $BAT_PERCENT%|$BAT_STATUS"

config="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.toml"
state="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
stamp="$cache/lockscreen-layout.sha"
last="${XDG_RUNTIME_DIR:-$cache}/noctalia-lock-battery"

# config-set copies the whole [lockscreen_widgets] table into the state overrides,
# which would then shadow later layout edits in the dotfiles. So when the dotfiles
# layout changed since the last run, that copy gets dropped below. The mtime test
# is a builtin, so the hashing only runs after settings.toml was edited.
resync=0
if [[ ! -f "$stamp" || "$config" -nt "$stamp" ]]; then
  section() { awk '/^\[/ { in_ls = ($0 ~ /^\[lockscreen_widgets[].]/) } in_ls' "$1"; }
  hash="$(section "$config" | sha256sum)"
  hash="${hash%% *}"
  old=""
  [[ -f "$stamp" ]] && read -r old <"$stamp"
  if [[ "$old" == "$hash" ]]; then
    touch "$stamp" # same layout, only refresh the mtime for the -nt test
  else
    resync=1
  fi
fi

prev=""
[[ -f "$last" ]] && read -r prev <"$last"
((resync == 0)) && [[ "$text" == "$prev" ]] && exit 0

status="$(noctalia msg status 2>/dev/null)" || exit 0 # noctalia not running
[[ "$status" == *'"locked": true'* ]] && exit 0       # retried on unlock

if ((resync)); then
  if [[ -f "$state" ]]; then
    tmp="$(mktemp)"
    awk '/^\[/ { in_ls = ($0 ~ /^\[lockscreen_widgets[].]/) } !in_ls' "$state" >"$tmp" && mv "$tmp" "$state"
    # No explicit config-reload: noctalia watches this file and reloads by itself,
    # and a second overlapping reload crashed it.
    sleep 1 # let the watcher's reload land before config-set
  fi
  mkdir -p "$cache"
  echo "$hash" >"$stamp"
  prev=""
fi

widget="lockscreen_widgets.widget.lockscreen-battery.settings"
noctalia msg config-set "$widget.title" "'$BAT_ICON  $BAT_PERCENT%'" >/dev/null &&
  noctalia msg config-set "$widget.description" "'$BAT_STATUS'" >/dev/null &&
  echo "$text" >"$last"
