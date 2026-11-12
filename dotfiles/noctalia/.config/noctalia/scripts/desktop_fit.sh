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
#
# W x H comes from noctalia itself: when a widget's placement size differs from
# its output's logical size, noctalia remaps it and saves the desktop table to
# the state file stamped with that size. That is read back here and replaced.
# When the screen matches the design nothing is saved and nothing is done.
#
# Run from the started and session_unlocked hooks (there is no output-change hook;
# after plugging in a monitor, the next unlock refits). Desktop widgets edited in
# noctalia's editor are kept until settings.toml's layout changes again.
FIT_VERSION=1 # bump when the fitting rules change, to refit existing machines

config="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.toml"
state="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
stamp="$cache/desktop-layout.sha" # "<dotfiles layout hash> <screen sizes hash>" of the fitted layout

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
# Prints "<widget> <placement_width> <placement_height>" for every widget of a section.
sizes() {
  awk '
    /^[ \t]*\[/ {
      n = $0; sub(/^[ \t]+/, "", n)
      if (n !~ /^\[desktop_widgets\.widget\./ || n ~ /\.settings\]/) { n = ""; next }
      sub(/^\[desktop_widgets\.widget\./, "", n); sub(/\][ \t]*$/, "", n); gsub(/"/, "", n)
      next
    }
    n != "" && $1 == "placement_width"  { w[n] = $3 + 0 }
    n != "" && $1 == "placement_height" { h[n] = $3 + 0 }
    END { for (n in w) if (w[n] > 0 && h[n] > 0) printf "%s %d %d\n", n, w[n], h[n] }' | sort
}

status="$(noctalia msg status 2>/dev/null)" || exit 0 # noctalia not running
[[ "$status" == *'"locked": true'* ]] && exit 0       # retried on unlock
[[ -f "$state" ]] || exit 0

# lock_battery.sh edits the same state file from the same hooks; take turns.
mkdir -p "$cache"
exec 9>"$cache/lock-battery.lock"
flock 9

screen="$(section "$state" | sizes)"
[[ -n "$screen" ]] || exit 0 # nothing saved: the screen matches the design

hash="$({ echo "fit-v$FIT_VERSION"; section "$config"; } | sha256sum)"
hash="${hash%% *}"
sig="$(sha256sum <<<"$screen")"
sig="${sig%% *}"
old=""
[[ -f "$stamp" ]] && read -r old <"$stamp"
[[ "$old" == "$hash $sig" ]] && exit 0 # already fitted (or edited since) for this screen

fitted="$(awk 'NR == FNR { SW[$1] = $2; SH[$1] = $3; next }
  function key(l) { sub(/^[ \t]+/, "", l); sub(/[ \t]*=.*/, "", l); return l }
  function num(l) { sub(/^[^=]*=[ \t]*/, "", l); sub(/[ \t]*#.*/, "", l); return l + 0 }
  # Widget name of a [desktop_widgets.widget.<name>] header, "" for other tables.
  function wname(h) {
    if (h !~ /^\[desktop_widgets\.widget\./ || h ~ /\.settings\]$/) return ""
    sub(/^\[desktop_widgets\.widget\./, "", h); sub(/\]$/, "", h); gsub(/"/, "", h)
    return h
  }
  # Scaled position along one axis, anchored to the nearer edge of the canvas.
  function place(v, design, actual, s) {
    if (v < design / 2) return v * s
    if (v > design / 2) return actual - (design - v) * s
    return actual / 2
  }
  { L[++N] = $0 }
  END {
    # Pass 1: design geometry of every widget.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) { n = wname(L[i]); continue }
      if (n != "" && L[i] ~ /=/) g[n, key(L[i])] = num(L[i])
    }
    # Pass 2: emit with fitted geometry.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) { n = wname(L[i]); print L[i]; continue }
      k = key(L[i]); pw = g[n, "placement_width"]; ph = g[n, "placement_height"]
      if (n == "" || !(pw > 0 && ph > 0) || !(n in SW) ||
          k !~ /^(cx|cy|box_width|box_height|placement_width|placement_height)$/) { print L[i]; continue }
      W = SW[n]; H = SH[n]
      s = (W / pw < H / ph) ? W / pw : H / ph
      v = g[n, k]
      if (k == "cx") v = place(v, pw, W, s)
      else if (k == "cy") v = place(v, ph, H, s)
      else if (k == "box_width" || k == "box_height") v = v * s
      else if (k == "placement_width") v = W
      else v = H
      print k " = " sprintf("%.1f", v)
    }
  }' <(echo "$screen") <(section "$config"))"
[[ -n "$fitted" ]] || exit 0

sleep 1 # let a reload from lock_battery.sh land first; overlapping reloads crashed noctalia
strip_section "$state"
printf '\n%s\n' "$fitted" >>"$state" # noctalia's watcher reloads it
echo "$hash $sig" >"$stamp"
