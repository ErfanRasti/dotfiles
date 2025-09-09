#!/usr/bin/env bash
set -euo pipefail

TMP_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprland-show-desktop"

# Get the current layout from hyprctl
CURRENT_LAYOUT=$(hyprctl getoption general:layout -j | jq -r '.str')

# Current workspace name (unquoted string)
CURRENT_WORKSPACE="$(hyprctl monitors -j | jq -r '.[].activeWorkspace.name')"

STATE_FILE="${TMP_FILE}-${CURRENT_WORKSPACE}"

# Accumulate hyprctl --batch commands here
CMDS=""

if [[ -s "$STATE_FILE" ]]; then
  # We have a saved list of addresses to restore to the current workspace
  mapfile -t ADDRESS_ARRAY <"$STATE_FILE"

  for address in "${ADDRESS_ARRAY[@]}"; do
    [[ -n "$address" ]] || continue
    CMDS+="dispatch movetoworkspacesilent name:${CURRENT_WORKSPACE},address:${address};"
  done

  # Only call hyprctl if we actually queued commands
  if [[ -n "$CMDS" ]]; then
    hyprctl --batch "$CMDS"
  fi

  rm -f -- "$STATE_FILE"
else
  # Collect all client addresses on the current workspace
  # jq -r outputs raw strings (no quotes), one per line
  mapfile -t ADDRESS_ARRAY < <(
    hyprctl clients -j |
      jq -r --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | .address'
  )

  TMP_ADDRESS=""
  for address in "${ADDRESS_ARRAY[@]}"; do
    [[ -n "$address" ]] || continue
    TMP_ADDRESS+="${address}"$'\n'
    CMDS+="dispatch movetoworkspacesilent special:desktop,address:${address};"
  done

  if [[ -n "$CMDS" ]]; then
    hyprctl --batch "$CMDS"
  fi

  # Save the list of addresses (without empty lines)
  if [[ -n "${TMP_ADDRESS}" ]]; then
    printf '%s' "$TMP_ADDRESS" | sed -e '/^$/d' >"$STATE_FILE"
  fi
fi

# Return to the previous layout
if [[ "$CURRENT_LAYOUT" == "master" ]]; then
  # Quick switch
  hyprctl keyword general:layout dwindle
  hyprctl keyword general:layout master
elif [[ "$CURRENT_LAYOUT" == "dwindle" ]]; then
  # Quick switch
  hyprctl keyword general:layout master
  hyprctl keyword general:layout dwindle
fi
