#!/usr/bin/env bash
# Fits the desktop widgets layout to this machine's screen.
#
# The dotfiles layout ([desktop_widgets] in settings.toml) is one design on a
# 1536x864 canvas (placement_width/height). Noctalia on its own only moves widget
# centers proportionally (x and y by different factors on another aspect ratio)
# and keeps box sizes, so on a bigger screen the widgets drift toward the middle
# and stay small, and on another aspect ratio cards that belong together split.
# Instead, the state override gets the design scaled uniformly by
# min(W/1536, H/864), boxes included, with every widget keeping its scaled
# distance to the screen edges it is nearest to (left/right of the canvas
# center, above/below it). Corners stay corners and groups stay together.
# A widget that belongs to a group on the other side of the middle (the forecast
# under the calendar) names its edge in a comment on its cx/cy line instead:
# `cy = 484.0 # anchor: top` (top/bottom/left/right, or center to scale about
# the middle).
#
# W x H is the output's logical size as noctalia sees it. Noctalia never saves
# the desktop table on its own (config-set on a desktop key writes only that key),
# but every save of the lockscreen table stamps its placement_width/height with
# the output's size, and lock_battery.sh (run just before this from the same
# hooks) makes that save. That stamp is read back here, so this works on any
# compositor and needs no query of its own. A desktop table noctalia saved itself
# (its editor) is the fallback.
#
# Run from the started and session_unlocked hooks (there is no output-change hook;
# after plugging in a monitor, the next unlock refits). Desktop widgets edited in
# noctalia's editor are kept until settings.toml's layout changes again.
FIT_VERSION=3 # bump when the fitting rules change, to refit existing machines

config="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.toml"
state="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
stamp="$cache/desktop-layout.sha" # "<dotfiles layout hash> <W> <H>" of the fitted layout

# Prints the [desktop_widgets] table (with its subtables) of a settings file.
# Noctalia indents subtables in the state file, so headers may be indented.
section() {
  awk '/^[ \t]*\[/ { h = $0; sub(/^[ \t]+/, "", h); in_dw = (h ~ /^\[desktop_widgets[].]/) } in_dw' "$1"
}
# Rewrites a settings file without its [desktop_widgets] table.
strip_section() {
  local tmp
  tmp="$(mktemp)"
  awk '/^[ \t]*\[/ { h = $0; sub(/^[ \t]+/, "", h); in_dw = (h ~ /^\[desktop_widgets[].]/) } !in_dw' "$1" >"$tmp" &&
    mv "$tmp" "$1"
}
# Prints "<W> <H>": the first placement_width/height of a settings table.
size_of() {
  awk '$1 == "placement_width" && !w { w = $3 } $1 == "placement_height" && !h { h = $3 }
    END { if (w > 0 && h > 0) printf "%d %d", w, h }'
}
# Prints the [lockscreen_widgets] table of a settings file (subtables may be indented).
lock_section() {
  awk '/^[ \t]*\[/ { h = $0; sub(/^[ \t]+/, "", h); in_ls = (h ~ /^\[lockscreen_widgets[].]/) } in_ls' "$1"
}

status="$(noctalia msg status 2>/dev/null)" || exit 0 # noctalia not running
[[ "$status" == *'"locked": true'* ]] && exit 0       # retried on unlock
[[ -f "$state" ]] || exit 0

# lock_battery.sh edits the same state file from the same hooks; take turns.
mkdir -p "$cache"
exec 9>"$cache/lock-battery.lock"
flock 9

size="$(lock_section "$state" | size_of)"
[[ -n "$size" ]] || size="$(section "$state" | size_of)"
[[ -n "$size" ]] || exit 0 # no size known yet; the next hook run retries
read -r W H <<<"$size"

hash="$({ echo "fit-v$FIT_VERSION"; section "$config"; } | sha256sum)"
hash="${hash%% *}"
old=""
[[ -f "$stamp" ]] && read -r old <"$stamp"
[[ "$old" == "$hash $W $H" ]] && exit 0 # already fitted (or edited since) for this screen

fitted="$(section "$config" | awk -v W="$W" -v H="$H" '
  function key(l) { sub(/^[ \t]+/, "", l); sub(/[ \t]*=.*/, "", l); return l }
  function num(l) { sub(/^[^=]*=[ \t]*/, "", l); sub(/[ \t]*#.*/, "", l); return l + 0 }
  # Widget name of a [desktop_widgets.widget.<name>] header, "" for other tables.
  function wname(h) {
    if (h !~ /^\[desktop_widgets\.widget\./ || h ~ /\.settings\]$/) return ""
    sub(/^\[desktop_widgets\.widget\./, "", h); sub(/\]$/, "", h); gsub(/"/, "", h)
    return h
  }
  # Edge named by an "anchor: <edge>" comment on the line, "" when there is none.
  function anchor(l) {
    if (!match(l, /#.*anchor:[ \t]*[a-z]+/)) return ""
    l = substr(l, RSTART, RLENGTH); sub(/.*anchor:[ \t]*/, "", l)
    return l
  }
  # Scaled position along one axis, anchored to the named edge, else the nearer one.
  function place(v, design, actual, s, a) {
    if (a == "top" || a == "left") return v * s
    if (a == "bottom" || a == "right") return actual - (design - v) * s
    if (a == "center") return actual / 2 + (v - design / 2) * s
    if (v < design / 2) return v * s
    if (v > design / 2) return actual - (design - v) * s
    return actual / 2
  }
  { L[++N] = $0 }
  END {
    # Pass 1: design geometry of every widget.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) { n = wname(L[i]); continue }
      if (n != "" && L[i] ~ /=/) { g[n, key(L[i])] = num(L[i]); a[n, key(L[i])] = anchor(L[i]) }
    }
    # Pass 2: emit with fitted geometry.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) { n = wname(L[i]); print L[i]; continue }
      k = key(L[i]); pw = g[n, "placement_width"]; ph = g[n, "placement_height"]
      if (n == "" || !(pw > 0 && ph > 0) ||
          k !~ /^(cx|cy|box_width|box_height|placement_width|placement_height)$/) { print L[i]; continue }
      s = (W / pw < H / ph) ? W / pw : H / ph
      v = g[n, k]
      if (k == "cx") v = place(v, pw, W, s, a[n, k])
      else if (k == "cy") v = place(v, ph, H, s, a[n, k])
      else if (k == "box_width" || k == "box_height") v = v * s
      else if (k == "placement_width") v = W
      else v = H
      print k " = " sprintf("%.1f", v)
    }
  }')"
[[ -n "$fitted" ]] || exit 0

sleep 1 # let a reload from lock_battery.sh land first; overlapping reloads crashed noctalia
strip_section "$state"
printf '\n%s\n' "$fitted" >>"$state" # noctalia's watcher reloads it
echo "$hash $W $H" >"$stamp"
