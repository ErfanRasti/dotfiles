#!/usr/bin/env bash

# Remember the current layout (master/dwindle) so it can be restored later
CURRENT_LAYOUT=$(hyprctl getoption general:layout -j | jq -r '.str')

# Current active workspace name
CURRENT_WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.id')

# Expose all windows to an special window
pypr expose

# === Refresh tiling layout (forces redraw/cleanup) ===
if [[ "$CURRENT_LAYOUT" == "master" ]]; then
  hyprctl keyword general:layout dwindle
  hyprctl keyword general:layout master
elif [[ "$CURRENT_LAYOUT" == "dwindle" ]]; then
  hyprctl keyword general:layout master
  hyprctl keyword general:layout dwindle
fi

# Switch back to the previous workspace if exists
if hyprctl workspaces -j | jq -e --argjson id "$CURRENT_WORKSPACE" '.[] | select(.id == $id)' >/dev/null; then
  hyprctl dispatch workspace "${CURRENT_WORKSPACE}"
fi
