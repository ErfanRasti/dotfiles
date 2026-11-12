#!/usr/bin/env bash
# Noctalia has no battery widget for the lockscreen, so the lockscreen shows a
# "label" widget (lockscreen-battery in settings.toml) and this script rewrites
# its text. Noctalia runs it from its battery/started/session_unlocked hooks.
# `config-set` writes to the state-dir override file, not the dotfiles repo.
#
# It also fits the lockscreen layout to this machine's screen. The dotfiles
# layout is one design on a 1536x864 canvas (placement_width/height). Noctalia
# on its own only moves widget centers proportionally (x and y by different
# factors on another aspect ratio) and keeps box sizes, so the card stack and
# login box drift apart. Instead, the state override gets the design scaled
# uniformly by min(W/1536, H/864), boxes included, and centered on the W x H
# logical screen, which keeps its aspect ratio on any resolution or scale.
# W x H comes from noctalia itself: every save of the lockscreen table stamps
# placement_width/height with the output's logical size.
#
# The login box is the exception: noctalia draws its panel at a fixed height
# (its content's, which is what the design's box_height is set to), centered on
# the box, with the "press enter" hint bar a fixed HINT_GAP above it, and only
# its width follows box_width. So the login box keeps its design height, the
# widgets that hug its panel (LOGIN_HUG) keep their design margins to it, scaled,
# and the widgets resting on the hint bar (ON_HINT) are placed from its top edge.
LOGIN_HUG="lockscreen-login-back"
ON_HINT="lockscreen-visualizer lockscreen-kitty lockscreen-kitty-caption"
HINT_GAP=49.6 # hint bar top above the login panel top, logical px (measured)
FIT_VERSION=2 # bump when the fitting rules change, to refit existing machines
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
text="$title|$BAT_STATUS"

config="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.toml"
state="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
stamp="$cache/lockscreen-layout.sha" # "<dotfiles layout hash> <W> <H>" of the fitted layout
last="${XDG_RUNTIME_DIR:-$cache}/noctalia-lock-battery"

# Prints the [lockscreen_widgets] table (with its subtables) of a settings file.
section() { awk '/^\[/ { in_ls = ($0 ~ /^\[lockscreen_widgets[].]/) } in_ls' "$1"; }
# Sets $hash to a fingerprint of the dotfiles layout and the fitting rules.
layout_hash() {
  hash="$({ echo "fit-v$FIT_VERSION $HINT_GAP $LOGIN_HUG $ON_HINT"; section "$config"; } | sha256sum)"
  hash="${hash%% *}"
}
# Rewrites a settings file without its [lockscreen_widgets] table.
strip_section() {
  local tmp
  tmp="$(mktemp)"
  awk '/^\[/ { in_ls = ($0 ~ /^\[lockscreen_widgets[].]/) } !in_ls' "$1" >"$tmp" && mv "$tmp" "$1"
}

# config-set copies the whole [lockscreen_widgets] table into the state overrides,
# which would then shadow later layout edits in the dotfiles. So when the dotfiles
# layout changed since the last run, that copy gets replaced below. The mtime test
# is a builtin, so the hashing only runs after settings.toml was edited.
resync=0
old="" fitW="" fitH=""
[[ -f "$stamp" ]] && read -r old fitW fitH <"$stamp"
if [[ ! -f "$stamp" || "$config" -nt "$stamp" || "${BASH_SOURCE[0]}" -nt "$stamp" || -z "$fitH" ]]; then
  layout_hash
  if [[ "$old" == "$hash" && -n "$fitH" ]]; then
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

# Several hooks fire for one event; only one instance edits the state file at a time.
mkdir -p "$cache"
exec 9>"$cache/lock-battery.lock"
flock 9

if ((resync)); then
  if [[ -f "$state" ]]; then
    strip_section "$state"
    # No explicit config-reload: noctalia watches this file and reloads by itself,
    # and a second overlapping reload crashed it.
    sleep 1 # let the watcher's reload land before config-set
  fi
  fitW="" fitH="" # force a refit after config-set restamps the size
  prev=""
fi

widget="lockscreen_widgets.widget.lockscreen-battery.settings"
noctalia msg config-set "$widget.title" "'$title'" >/dev/null &&
  noctalia msg config-set "$widget.description" "'$BAT_STATUS'" >/dev/null &&
  echo "$text" >"$last" || exit 0

# The save above stamped the lockscreen table with the output's logical size.
# Refit when that differs from what the current fit was made for (first run,
# dotfiles layout edited, another screen or scale).
size="$(section "$state" | awk '
  $1 == "placement_width"  && !w { w = $3 }
  $1 == "placement_height" && !h { h = $3 }
  END { if (w > 0 && h > 0) printf "%d %d", w, h }')"
[[ -n "$size" ]] || exit 0
read -r W H <<<"$size"
[[ "$W" == "$fitW" && "$H" == "$fitH" ]] && exit 0

[[ -n "$hash" ]] || layout_hash

fitted="$(section "$config" | awk -v W="$W" -v H="$H" -v title="$title" -v desc="$BAT_STATUS" \
  -v hug=" $LOGIN_HUG " -v onhint=" $ON_HINT " -v gap="$HINT_GAP" '
  function q(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return "\"" s "\"" }
  function key(l) { sub(/[ \t]*=.*/, "", l); return l }
  function num(l) { sub(/^[^=]*=[ \t]*/, "", l); sub(/[ \t]*#.*/, "", l); return l + 0 }
  # Widget name of a [lockscreen_widgets.widget.<name>] header, "" for other tables.
  function wname(h) {
    if (h !~ /^\[lockscreen_widgets\.widget\./ || h ~ /\.settings\]$/) return ""
    sub(/^\[lockscreen_widgets\.widget\./, "", h); sub(/\]$/, "", h); gsub(/"/, "", h)
    return h
  }
  { L[++N] = $0 }
  END {
    # Pass 1: design geometry of every widget.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) { n = wname(L[i]); continue }
      if (n == "") continue
      k = key(L[i])
      if (k == "type") { if (L[i] ~ /"login_box"/ && login == "") login = n }
      else g[n, k] = num(L[i])
    }
    if (login != "") {
      pw = g[login, "placement_width"]; ph = g[login, "placement_height"]
      s = (W / pw < H / ph) ? W / pw : H / ph
      lcy = g[login, "cy"]; lh = g[login, "box_height"]
      lcy2 = H / 2 + (lcy - ph / 2) * s       # fitted login box center
      hint = lcy - lh / 2 - gap               # hint bar top, design
      hint2 = lcy2 - lh / 2 - gap             # hint bar top, fitted
    }
    # Pass 2: emit with fitted geometry.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) { n = wname(L[i]); hdr = L[i]; print L[i]; continue }
      if (hdr ~ /^\[lockscreen_widgets\.widget\.lockscreen-battery\.settings\]$/) {
        if (L[i] ~ /^title[ \t]*=/) L[i] = "title = " q(title)
        else if (L[i] ~ /^description[ \t]*=/) L[i] = "description = " q(desc)
      }
      k = key(L[i]); pw = g[n, "placement_width"]; ph = g[n, "placement_height"]
      if (n == "" || !(pw > 0 && ph > 0) ||
          k !~ /^(cx|cy|box_width|box_height|placement_width|placement_height)$/) { print L[i]; continue }
      s = (W / pw < H / ph) ? W / pw : H / ph
      v = g[n, k]
      if (k == "cx") v = W / 2 + (v - pw / 2) * s
      else if (k == "cy") {
        if (login != "" && index(hug, " " n " ")) v = lcy2 + (v - lcy) * s
        else if (login != "" && index(onhint, " " n " ")) v = hint2 + (v - hint) * s
        else v = H / 2 + (v - ph / 2) * s
      }
      else if (k == "box_width") v = v * s
      else if (k == "box_height") {
        if (n == login) v = v                  # panel height is fixed by noctalia
        else if (login != "" && index(hug, " " n " ")) v = lh + (v - lh) * s
        else v = v * s
      }
      else if (k == "placement_width") v = W
      else v = H
      print k " = " sprintf("%.1f", v)
    }
  }')"
[[ -n "$fitted" ]] || exit 0

strip_section "$state"
printf '\n%s\n' "$fitted" >>"$state" # noctalia's watcher reloads it
echo "$hash $W $H" >"$stamp"
