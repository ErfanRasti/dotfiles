#!/usr/bin/env bash
# Move the focused window one step in a direction (Mod+Ctrl+H/J/K/L and arrows).
#   floating windows (incl. every window in the stacking layout): nudge by STEP % of the
#     output, stopping at the screen edge; pushing up/down again while already at the top/bottom
#     edge sends the window to the previous/next workspace (like tiled windows do)
#   tiled windows: the usual column/window move (to the next output/workspace at the edge)
# Usage: move_window.sh <left|right|up|down>

STEP=5 # percent of the output width (left/right) or height (up/down)

dir="$1"
read -r floating output y h tb < <(umbriel focused-window --json 2>/dev/null |
  jq -r '"\(.floating) \(.output) \(.y) \(.h) \(.title_bar)"')

if [[ "$floating" != "true" ]]; then
  case "$dir" in
    left)  umbriel msg window-move-or-output-left ;;
    right) umbriel msg window-move-or-output-right ;;
    up)    umbriel msg window-move-or-workspace-up ;;
    down)  umbriel msg window-move-or-workspace-down ;;
  esac >/dev/null 2>&1
  exit 0
fi

read -r ow oh uy uh < <(umbriel outputs --json | jq -r --arg o "$output" '.[] | select(.name == $o)
  | "\(.logical_size.width) \(.logical_size.height) \(.usable_area.y) \(.usable_area.height)"')
dx=$((ow * STEP / 100)) dy=$((oh * STEP / 100))

# A title bar sits above the window's reported position: keep it on screen too.
bar=0
if [[ "$tb" == "true" ]]; then
  bar=$(awk '/^\[appearance.title_bar\]/{s=1;next} /^\[/{s=0} s&&$1=="height"{print $3; exit}' \
    "$HOME/.config/umbriel/config/appearance.toml")
fi
top=$((uy + ${bar:-0})) bottom=$((uy + uh))

case "$dir" in
  left)  umbriel msg window-move-by "-$dx" 0 ;;
  right) umbriel msg window-move-by "$dx" 0 ;;
  up)
    room=$((y - top))
    if ((room <= 1)); then umbriel msg column-move-to-workspace-previous
    else umbriel msg window-move-by 0 "-$((room < dy ? room : dy))"; fi ;;
  down)
    room=$((bottom - y - h))
    if ((room <= 1)); then umbriel msg column-move-to-workspace-next
    else umbriel msg window-move-by 0 "$((room < dy ? room : dy))"; fi ;;
esac >/dev/null 2>&1
