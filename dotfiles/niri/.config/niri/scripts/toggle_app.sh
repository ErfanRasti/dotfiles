#!/usr/bin/env bash

# This script toggles an app between the current workspace and the "Scratchpad" workspace in niri.
#
# Usage:
#   toggle_app.sh [OPTIONS] <command>
#
# Examples:
#   toggle_app.sh --class org.gnome.Nautilus nautilus
#   toggle_app.sh --class org.wezfurlong.wezterm --title "notes" 'wezterm start --class org.wezfurlong.wezterm'
#
# Special behavior:
#   - If run with no arguments, the script moves the currently focused window to the "Scratchpad"
#
# Semantics:
#   - If the focused window matches the requested app-id/class (and title, if provided),
#     send it to workspace "Scratchpad".
#   - Otherwise:
#       - If a matching window already exists, bring it to the current workspace and focus it.
#       - Else, spawn the given command.

# Force all the variables to define
set -euo pipefail

define_parameters() {
  APP_ID=""
  TITLE=""
  APP_CMD=""

  SCRATCH_WS_NAME="Scratchpad"

  # --- Focused window info ---
  FOCUSED_WIN_ID="$(niri msg -j focused-window | jq -r '.id // empty')"

  # all windows
  WINDOWS_JSON="$(niri msg -j windows)"
}

handle_arguments() {
  # If no arguments are given, move the currently focused window to the Scratchpad
  if [[ $# -eq 0 ]]; then
    # if there is a focused window hide it
    if [[ -n "$FOCUSED_WIN_ID" ]]; then
      niri msg action move-window-to-workspace --window-id "$FOCUSED_WIN_ID" "$SCRATCH_WS_NAME" --focus=false
    fi
    exit 0
  else
    # Parse command-line arguments
    while [[ $# -gt 0 ]]; do
      case "$1" in
      -c | --class)
        APP_ID="$2"
        shift 2
        ;;
      -t | --title)
        TITLE="$2"
        shift 2
        ;;
      -h | --help)
        echo "Usage: $0 [OPTIONS] <command>"
        echo "       $0"
        echo
        echo "Toggle an app between the current workspace and the \"Scratchpad\" workspace in niri."
        echo
        echo "If run with no arguments, the script moves the currently focused window to the \"Scratchpad\""
        echo
        echo "Options:"
        echo "  -c, --class    Set the app-id/window class to match"
        echo "  -t, --title    Match the window title as well (optional)"
        echo "  -h, --help     Show this help message and exit"
        echo
        echo "Arguments:"
        echo "  <command>      Command to spawn if no matching window exists"

        exit 0
        ;;
      *)
        if [ -z "$APP_CMD" ]; then
          APP_CMD="$1"
        else
          echo "Error: Unexpected argument $1" >&2
          exit 1
        fi
        shift
        ;;
      esac
    done
    # Check that the class is provided
    if [ -z "$APP_ID" ]; then
      echo "Error: --class <window_class> is required" >&2
      exit 1
    fi

    # If no command is provided, show error
    if [ -z "$APP_CMD" ]; then
      echo "Error: Command to spawn is required" >&2
      exit 1
    fi

    # If no title is provided, select the window with the matching app-id
    if [ -z "$TITLE" ]; then
      TITLE=$(echo "$WINDOWS_JSON" | jq -r --arg app "$APP_ID" '.[] | select(.app_id == $app) | .title' | head -n1)
    fi
  fi
}
get_workspaces_info() {

  # --- Get workspace info (current + scratch) ---
  WORKSPACES_JSON="$(niri msg -j workspaces)"

  # Current workspace idx.
  CURRENT_WS_REF="$(echo "$WORKSPACES_JSON" | jq -r '.[] | select(.is_focused == true) | .idx')"

  # ID of scratch workspace (must exist and be named "SCRATCH_WS_NAME").
  SCRATCH_WS_ID="$(echo "$WORKSPACES_JSON" | jq -r --arg ws "$SCRATCH_WS_NAME" \
    '.[] | select(.name == $ws) | .id' | head -n1)"

  if [[ -z "$SCRATCH_WS_ID" ]]; then
    echo "Error: no workspace named \"$SCRATCH_WS_NAME\" found. Define it in niri/config.kdl:" >&2
    echo "  workspace \"$SCRATCH_WS_NAME\"" >&2
    exit 1
  fi
}

hide_or_show() {
  # Find window id based on its app-id and title
  WIN_ID="$(
    echo "$WINDOWS_JSON" | jq -r \
      --arg app "$APP_ID" \
      --arg title "$TITLE" \
      '.[] | select(.app_id == $app and (.title | contains($title))) | .id' |
      head -n1
  )"
  # --- If focused window already matches -> hide it to scratch ---
  if [[ -n "$FOCUSED_WIN_ID" && "$FOCUSED_WIN_ID" == "$WIN_ID" ]]; then
    niri msg action move-window-to-workspace --window-id "$FOCUSED_WIN_ID" "$SCRATCH_WS_NAME" --focus=false
    exit 0
  fi

  # --- Otherwise, show existing window or launch new one ---

  # If no matching window is found, spawn a new one.
  if [ -z "$WIN_ID" ] && [ -n "$APP_CMD" ]; then
    echo "I'M READY TO LAUNCH"
    niri msg action spawn -- sh -c "$APP_CMD"
    exit 0
  fi

  # Bring window to the current workspace and focus it.
  niri msg action move-window-to-workspace --window-id "$WIN_ID" "$CURRENT_WS_REF" --focus=false
  # niri msg action move-window-to-floating --id "$WIN_ID"
  niri msg action focus-window --id "$WIN_ID"
}

main() {
  define_parameters
  handle_arguments "$@"
  get_workspaces_info
  hide_or_show
}

main "$@"
