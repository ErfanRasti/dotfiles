#!/usr/bin/env bash
# Fits the desktop and lockscreen widget layouts to whatever monitor is in use.
#
# settings.toml designs both on a 1536x864 canvas (placement_width/height).
# Noctalia alone only moves widget centers proportionally (x and y apart on another
# aspect ratio) and keeps box sizes, so widgets drift apart and stay small. Instead,
# the state override gets each design scaled uniformly by s = min(W/1536, H/864),
# boxes included (widgets scale their text to the box), and every widget pinned to
# the monitor's output. Positions are scaled about an anchor:
#   desktop    : the nearest screen edges, so corners stay corners
#   lockscreen : the screen center, so the design keeps its aspect ratio
# or the one named in a comment on the cx/cy line, e.g. `cy = 512.0 # anchor: top`:
#   top, bottom, left, right, center
#   login : keeps its scaled distance to the login box. Noctalia draws the login
#           panel at a fixed height (the design's box_height), so on a box_height
#           line it keeps the design margin to that panel (the login box's own: fixed).
#   hint  : rests on the "press enter" hint bar, a fixed HINT_GAP above the panel
HINT_GAP=49.6 # hint bar top above the login panel top, logical px (measured)
#
# The monitor is the focused output, asked from the compositor (umbriel, niri,
# Hyprland). On others the outputs stay as designed and the size is the one noctalia
# stamped into placement_width/height on its last save of the tables.
# Runs from the started and session_unlocked hooks (there is no output-change hook;
# after switching monitors, the next unlock refits). Layouts edited in noctalia's
# editor are kept until the monitor, settings.toml's layouts or this script change.
#
# Never touches noctalia while the screen is locked: changing lockscreen widget
# config while locked crashes noctalia 5.4.1 (LockscreenWidgetsHost).

config="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.toml"
state="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/settings.toml"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
stamp="$cache/widgets-layout.sha" # "<layout hash> <output> <W> <H>" of the fitted layouts
battery="lockscreen_widgets.widget.lockscreen-battery.settings" # text set by lock_battery.sh

# Prints the widget tables (with subtables) of settings file $1 whose header matches
# $2 (default: both), or with $3 = 0 everything else. The state file indents subtables.
section() {
  awk -v re="^[[](${2:-desktop|lockscreen})_widgets[].]" -v want="${3:-1}" \
    '/^[ \t]*\[/ { h = $0; sub(/^[ \t]+/, "", h); in_w = (h ~ re) } in_w == want' "$1"
}
locked() { [[ "$(noctalia msg status 2>/dev/null)" != *'"locked": false'* ]]; } # or not running

locked && exit 0 # retried on unlock
[[ -f "$state" ]] || exit 0

# lock_battery.sh edits the same state file from the same hooks; take turns.
mkdir -p "$cache"
exec 9>"$cache/settings.lock"
flock 9

case "${XDG_CURRENT_DESKTOP,,}" in # "<output> <W> <H>", logical px
umbriel) mon="$(umbriel outputs --json | jq -r '.[] | select(.focused) |
  "\(.name) \(.logical_size.width) \(.logical_size.height)"')" ;;
niri) mon="$(niri msg -j focused-output | jq -r '"\(.name) \(.logical.width) \(.logical.height)"')" ;;
hyprland) mon="$(hyprctl -j monitors | jq -r '.[] | select(.focused) |
  (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end) as $wh |
  "\(.name) \($wh[0] / .scale | floor) \($wh[1] / .scale | floor)"')" ;;
esac 2>/dev/null
[[ "$mon" =~ ^[^\ ]+\ [0-9]+\ [0-9]+$ ]] || mon="- $(section "$state" | awk '
  $1 == "placement_width" && !w { w = $3 } $1 == "placement_height" && !h { h = $3 }
  END { if (w > 0 && h > 0) printf "%d %d", w, h }')"
read -r out W H <<<"$mon"
[[ -n "$H" ]] || exit 0 # no size known yet; the next hook run retries

hash="$({ cat "${BASH_SOURCE[0]}"; section "$config"; } | sha256sum)"
hash="${hash%% *}"
old=""
[[ -f "$stamp" ]] && read -r old <"$stamp"
[[ "$old" == "$hash $mon" ]] && exit 0 # already fitted (or edited since) for this monitor

# Input: the state's battery text (kept), then the dotfiles layouts (fitted).
fitted="$({ section "$state" lockscreen | awk -v bhdr="[$battery]" '
    /^[ \t]*\[/ { in_b = ($1 == bhdr); next } in_b && ($1 == "title" || $1 == "description")'
  echo "# --- layouts"
  section "$config"
} | awk -v W="$W" -v H="$H" -v out="$out" -v gap="$HINT_GAP" -v bhdr="[$battery]" '
  function trim(l) { sub(/^[ \t]+/, "", l); return l }
  function key(l) { l = trim(l); sub(/[ \t]*=.*/, "", l); return l }
  function num(l) { sub(/^[^=]*=[ \t]*/, "", l); sub(/[ \t]*#.*/, "", l); return l + 0 }
  # Widget id of a [<table>.widget.<id>] header, "" for other tables.
  function wname(h) {
    if (h !~ /^\[[a-z]+_widgets\.widget\./ || h ~ /\.settings\]$/) return ""
    sub(/^\[[a-z]+_widgets\.widget\./, "", h); sub(/\]$/, "", h); gsub(/"/, "", h)
    return h
  }
  # Anchor named by an "anchor: <name>" comment on the line, "" when there is none.
  function anchor(l) {
    if (!match(l, /#.*anchor:[ \t]*[a-z]+/)) return ""
    l = substr(l, RSTART, RLENGTH); sub(/.*anchor:[ \t]*/, "", l)
    return l
  }
  # Scaled position along one axis about the anchor, else the nearer edge.
  function place(v, design, actual, s, a) {
    if (a == "login") return lcy2 + (v - lcy) * s
    if (a == "hint") return hint2 + (v - hint) * s
    if (a == "top" || a == "left") return v * s
    if (a == "bottom" || a == "right") return actual - (design - v) * s
    if (a == "center" || v == design / 2) return actual / 2 + (v - design / 2) * s
    return v < design / 2 ? v * s : actual - (design - v) * s
  }
  !body { if ($0 == "# --- layouts") body = 1; else keep[key($0)] = trim($0); next }
  { L[++N] = $0 }
  END {
    # Pass 1: design geometry and anchors of every widget, the login box.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) { n = wname(L[i]); lock = (L[i] ~ /^\[lockscreen/); continue }
      if (n == "" || L[i] !~ /=/) continue
      k = key(L[i]); g[n, k] = num(L[i]); a[n, k] = anchor(L[i])
      if (a[n, k] == "" && lock) a[n, k] = "center"
      if (k == "type" && L[i] ~ /"login_box"/) login = n
    }
    if (login != "") {
      pw = g[login, "placement_width"]; ph = g[login, "placement_height"]
      s = (W / pw < H / ph) ? W / pw : H / ph
      lcy = g[login, "cy"]; lh = g[login, "box_height"]
      lcy2 = H / 2 + (lcy - ph / 2) * s # fitted login box center
      hint = lcy - lh / 2 - gap; hint2 = lcy2 - lh / 2 - gap # hint bar top, design and fitted
    }
    # Pass 2: emit with fitted geometry and output, the battery text kept.
    for (i = 1; i <= N; i++) {
      if (L[i] ~ /^\[/) {
        n = wname(L[i]); b = (L[i] == bhdr); print L[i]
        if (n != "" && out != "-") print "output = \"" out "\""
        continue
      }
      k = key(L[i]); pw = g[n, "placement_width"]; ph = g[n, "placement_height"]
      if (b && (k in keep)) { print keep[k]; continue }
      if (n != "" && k == "output" && out != "-") continue
      if (n == "" || !(pw > 0 && ph > 0) ||
          k !~ /^(cx|cy|box_width|box_height|placement_width|placement_height)$/) { print L[i]; continue }
      s = (W / pw < H / ph) ? W / pw : H / ph
      v = g[n, k]; an = a[n, k]
      if (k == "cx") v = place(v, pw, W, s, an)
      else if (k == "cy") v = place(v, ph, H, s, an)
      else if (k == "box_height" && an == "login") v = lh + (v - lh) * s
      else if (k == "box_width" || k == "box_height") v = v * s
      else if (k == "placement_width") v = W
      else v = H
      print k " = " sprintf("%.1f", v)
    }
  }')"
[[ -n "$fitted" ]] || exit 0

sleep 1 # let a reload from lock_battery.sh land first; overlapping reloads crashed noctalia
locked && exit 0
tmp="$(mktemp)"
section "$state" "" 0 >"$tmp" && printf '\n%s\n' "$fitted" >>"$tmp" && mv "$tmp" "$state" # noctalia reloads it
echo "$hash $mon" >"$stamp"
