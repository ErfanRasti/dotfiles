#!/usr/bin/env bash
# Mod+H/J/K/L (and the arrows): directional focus that also understands tabs and scratchpads.
#   shown scratchpad window -> nearest other scratchpad window in that direction (by centre)
#   tab group (left/right)  -> previous/next tab, then on to the neighbouring column
#   otherwise               -> the usual focus (left/right: or output; up/down: or workspace)
# Usage: focus.sh <left|right|up|down>

dir="$1"
read -r kind target < <(umbriel windows --json | jq -r --arg d "$dir" '
  (map(select(.focused or (.active and .scratchpad != "" and .visible))) | first) as $f
  | if $f == null then "none -"
    elif $f.scratchpad != "" then
      # scratchpad: candidates strictly in the direction; nearest by distance (off-axis x2)
      [ .[] | select(.scratchpad != "" and .visible and .id != $f.id)
        | {id, dx: ((.x + .w/2) - ($f.x + $f.w/2)), dy: ((.y + .h/2) - ($f.y + $f.h/2))}
        | select(if $d == "left" then .dx < 0 elif $d == "right" then .dx > 0
                 elif $d == "up" then .dy < 0 else .dy > 0 end)
        | .cost = (if $d == "left" or $d == "right" then (.dx|fabs) + 2*(.dy|fabs)
                   else (.dy|fabs) + 2*(.dx|fabs) end) ]
      | (sort_by(.cost) | first) as $t
      | "pad \($t.id // "-")"
    elif $f.tabbed and ($d == "left" or $d == "right") then
      ([ .[] | select(.workspace == $f.workspace and .column == $f.column and .tabbed) ] | length) as $n
      | if $d == "left" and $f.tab_index > 0 then "tab previous"
        elif $d == "right" and $f.tab_index < $n - 1 then "tab next"
        else "none -" end
    else "none -" end')

case "$kind" in
  pad) [[ "$target" != "-" ]] && exec umbriel msg window-focus "$target"; exit 0 ;;
  tab) exec umbriel msg "column-focus-tab-$target" ;;
esac
case "$dir" in
  left | right) exec umbriel msg "window-focus-or-output-$dir" ;;
  up | down)    exec umbriel msg "window-focus-or-workspace-$dir" ;;
esac
