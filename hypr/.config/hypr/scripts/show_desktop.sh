#!/usr/bin/env bash
# Toggle "show desktop" behavior in Hyprland:
# - Hides all windows from the current workspace to special:desktop, saving their addresses and focus
# - Restores them back later, returning focus to the previously active window if possible
# - Refreshes layout at the end to keep tiling consistent

# safer bash: exit on error (-e), unset vars (-u), or failed pipe (-o pipefail)
set -euo pipefail

# Temporary file base (per-workspace state will be stored here)
TMP_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprland-show-desktop"

# Remember the current layout (master/dwindle) so it can be restored later
CURRENT_LAYOUT=$(hyprctl getoption general:layout -j | jq -r '.str')

# Current active workspace name
CURRENT_WORKSPACE="$(hyprctl monitors -j | jq -r '.[].activeWorkspace.name')"

# State file for this workspace (stores hidden window addresses)
STATE_FILE="${TMP_FILE}-${CURRENT_WORKSPACE}"

# Separate file to remember which window had focus
FOCUS_FILE="${STATE_FILE}.focus"

# Accumulate batched hyprctl commands
CMDS=""

# If STATE_FILE exists and has content
if [[ -s "$STATE_FILE" ]]; then
  # === Restore windows ===

  # Read the saved list of window addresses (one per line) from STATE_FILE
  # into an array called ADDRESS_ARRAY
  mapfile -t ADDRESS_ARRAY <"$STATE_FILE"

  # If the FOCUS_FILE exists, read its single line (last focused window address)
  # into LAST_FOCUS; otherwise set LAST_FOCUS to an empty string
  [[ -f "$FOCUS_FILE" ]] && LAST_FOCUS="$(<"$FOCUS_FILE")" || LAST_FOCUS=""

  # Queue up move commands for each saved window
  for address in "${ADDRESS_ARRAY[@]}"; do
    [[ -n "$address" ]] || continue
    CMDS+="dispatch movetoworkspacesilent name:${CURRENT_WORKSPACE},address:${address};"
  done

  # Only run restore if there are windows to move back
  if [[ -n "$CMDS" ]]; then
    hyprctl --batch "$CMDS"

    # Switch back to the workspace we restored windows to
    hyprctl dispatch focusworkspace name:"${CURRENT_WORKSPACE}"

    # Re-scan windows now present on this workspace
    mapfile -t NOW_ADDRS < <(
      hyprctl clients -j |
        jq -r --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | .address'
    )

    # Prefer previously focused window if it still exists, otherwise first window
    TARGET=""
    if [[ -n "$LAST_FOCUS" ]] && printf '%s\n' "${NOW_ADDRS[@]}" | grep -qx "$LAST_FOCUS"; then
      TARGET="$LAST_FOCUS"
    elif [[ -n "${NOW_ADDRS[0]:-}" ]]; then
      TARGET="${NOW_ADDRS[0]}"
    fi

    # Focus the chosen target (if any), fallback if Hyprland reports none active
    if [[ -n "$TARGET" ]]; then
      hyprctl dispatch focuswindow address:"$TARGET" >/dev/null 2>&1 || true
      CUR="$(hyprctl activewindow -j | jq -r '.address // empty' 2>/dev/null || true)"
      if [[ -z "$CUR" && "${#NOW_ADDRS[@]}" -gt 0 ]]; then
        hyprctl dispatch focuswindow address:"${NOW_ADDRS[0]}" >/dev/null 2>&1 || true
      fi
    fi
  fi

  # Cleanup saved state
  rm -f -- "$STATE_FILE" "$FOCUS_FILE"

else
  # === Hide windows ===

  # Save currently focused window (to restore focus later)
  ACTIVE_ADDR="$(hyprctl activewindow -j | jq -r '.address // empty')"
  if [[ -n "$ACTIVE_ADDR" ]]; then
    printf '%s\n' "$ACTIVE_ADDR" >"$FOCUS_FILE"
  fi

  # Collect all windows on current workspace
  mapfile -t ADDRESS_ARRAY < <(
    hyprctl clients -j |
      jq -r --arg CW "$CURRENT_WORKSPACE" '.[] | select(.workspace.name == $CW) | .address'
  )

  # Loop over all windows on this workspace:
  # Save their addresses and queue commands to move them to the special "desktop" workspace
  TMP_ADDRESS=""
  for address in "${ADDRESS_ARRAY[@]}"; do
    [[ -n "$address" ]] || continue
    TMP_ADDRESS+="${address}"$'\n'
    CMDS+="dispatch movetoworkspacesilent special:desktop,address:${address};"
  done

  # Move them to the special "desktop" workspace
  if [[ -n "$CMDS" ]]; then
    hyprctl --batch "$CMDS"
  fi

  # Save list of hidden window addresses
  if [[ -n "${TMP_ADDRESS}" ]]; then
    printf '%s' "$TMP_ADDRESS" | sed -e '/^$/d' >"$STATE_FILE"
  fi
fi

# === Refresh tiling layout (forces redraw/cleanup) ===
if [[ "$CURRENT_LAYOUT" == "master" ]]; then
  hyprctl keyword general:layout dwindle
  hyprctl keyword general:layout master
elif [[ "$CURRENT_LAYOUT" == "dwindle" ]]; then
  hyprctl keyword general:layout master
  hyprctl keyword general:layout dwindle
fi
