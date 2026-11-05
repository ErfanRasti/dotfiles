#!/usr/bin/env bash
# Move the focused window one step in a direction.
#   floating windows (incl. every window in the stacking layout): nudge by STEP % of the output
#   tiled windows: the usual column/window move (to the next output/workspace at the edge)
# Usage: move_window.sh <left|right|up|down>

STEP=5 # percent of the output width (left/right) or height (up/down)

dir="$1"
read -r floating output < <(umbriel focused-window --json 2>/dev/null | jq -r '"\(.floating) \(.output)"')

if [[ "$floating" == "true" ]]; then
  read -r ow oh < <(umbriel outputs --json | jq -r --arg o "$output" \
    '.[] | select(.name == $o) | "\(.logical_size.width) \(.logical_size.height)"')
  dx=$((ow * STEP / 100)) dy=$((oh * STEP / 100))
  case "$dir" in
    left)  umbriel msg window-move-by "-$dx" 0 ;;
    right) umbriel msg window-move-by "$dx" 0 ;;
    up)    umbriel msg window-move-by 0 "-$dy" ;;
    down)  umbriel msg window-move-by 0 "$dy" ;;
  esac
else
  case "$dir" in
    left)  umbriel msg window-move-or-output-left ;;
    right) umbriel msg window-move-or-output-right ;;
    up)    umbriel msg window-move-or-workspace-up ;;
    down)  umbriel msg window-move-or-workspace-down ;;
  esac
fi >/dev/null 2>&1
