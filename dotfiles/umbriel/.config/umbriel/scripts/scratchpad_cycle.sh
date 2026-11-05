#!/usr/bin/env bash
# Cycle between the windows of whichever scratchpad is currently shown.
#
# Usage: scratchpad_cycle.sh [focus|show]
#   focus (default): focus the next window of the shown scratchpad (all stay visible)
#   show:            show only the next window of the shown scratchpad (one at a time)
# With no scratchpad shown it falls back to switching between floating and tiled windows.

action="${1:-focus}"

pad="$(umbriel windows --json | jq -r '
  [ .[] | select(.scratchpad != "" and .visible) ] | first | .scratchpad // empty')"

if [[ -z "$pad" ]]; then
  umbriel msg window-focus-switch-floating >/dev/null 2>&1
  exit 0
fi

case "$action" in
  show) umbriel msg scratchpad-window-show-next "$pad" >/dev/null 2>&1 ;;
  *)    umbriel msg scratchpad-focus-next "$pad" >/dev/null 2>&1 ;;
esac
