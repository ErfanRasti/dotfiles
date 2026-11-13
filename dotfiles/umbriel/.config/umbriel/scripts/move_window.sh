#!/usr/bin/env bash
# Move the focused window one step (Mod+Ctrl+H/J/K/L and arrows). Usage: move_window.sh <left|right|up|down>
#   tiled: the usual move, to the next output (left/right) or workspace (up/down) at the edge
#   floating (incl. the stacking layout): nudge by STEP % of the output, stopping at the top/bottom
#     edge (never leaving the workspace; Mod+Alt+J/K does that)

STEP=5
dir=$1
read -r floating output y h tb < <(umbriel focused-window --json 2>/dev/null |
  jq -r '"\(.floating) \(.output) \(.y) \(.h) \(.title_bar)"')

if [[ $floating != true ]]; then
  [[ $dir == up || $dir == down ]] && to=workspace || to=output
  exec umbriel msg "window-move-or-$to-$dir" >/dev/null 2>&1
fi

read -r ow oh uy uh < <(umbriel outputs --json | jq -r --arg o "$output" '.[] | select(.name == $o)
  | "\(.logical_size.width) \(.logical_size.height) \(.usable_area.y) \(.usable_area.height)"')

# A title bar sits above the window's reported position: keep it on screen too.
bar=0
[[ $tb == true ]] && bar=$(awk '/^\[appearance.title_bar\]/{s=1;next} /^\[/{s=0} s&&$1=="height"{print $3; exit}' \
  ~/.config/umbriel/config/appearance.toml)

dx=$((ow * STEP / 100)) dy=$((oh * STEP / 100))
case $dir in
  left)  move="-$dx 0" ;;
  right) move="$dx 0" ;;
  up)    room=$((y - uy - ${bar:-0})) move="0 -$((room < dy ? room : dy))" ;;
  down)  room=$((uy + uh - y - h))    move="0 $((room < dy ? room : dy))" ;;
esac
((${room:-1} > 0)) && umbriel msg window-move-by $move >/dev/null 2>&1
