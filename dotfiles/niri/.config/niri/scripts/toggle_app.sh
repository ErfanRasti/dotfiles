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
#   - By default, after bringing a window to the current workspace, auto-hides it to Scratchpad
#     when focus moves to another window.  Use --no-auto-hide to disable.
#
# Semantics:
#   - If the focused window matches the requested app-id/class (and title, if provided),
#     send it to workspace "Scratchpad".
#   - Otherwise:
#       - If a matching window already exists, bring it to the current workspace and focus it.
#       - Else, spawn the given command.
#   - Unless --no-auto-hide is used, the script blocks after showing the window and
#     watches for focus changes.  When focus moves to a different regular window, the
#     tracked window is automatically sent back to the Scratchpad.

set -euo pipefail

define_parameters() {
  APP_ID=""
  TITLE=""
  APP_CMD=""
  AUTO_HIDE=true

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
      --no-auto-hide)
        AUTO_HIDE=false
        shift
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
        echo "  -c, --class           Set the app-id/window class to match"
        echo "  -t, --title           Match the window title as well (optional)"
        echo "  --no-auto-hide        Disable auto-hide when focus leaves the app"
        echo "  -h, --help            Show this help message and exit"
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
    echo "Error: no workspace named \"$SCRATCH_WS_NAME\" defined in niri/config.kdl:" >&2
    echo "  workspace \"$SCRATCH_WS_NAME\"" >&2
    exit 1
  fi
}

# --- Auto-hide monitor ---
# Blocks reading niri's event-stream until focus moves to a different
# regular window, then sends the tracked window to the scratchpad.
auto_hide_monitor() {
  local tracked_id="$1"
  local scratch_ws="$2"

  while IFS= read -r line; do
    # Tracked window was closed by the user — nothing to do
    if echo "$line" | jq -e --argjson id "$tracked_id" '.WindowClosed | select(.id == $id)' >/dev/null 2>&1; then
      exit 0
    fi

    # A regular window (non-null id) gained focus and it isn't ours — hide ours
    new_focus=$(echo "$line" | jq -r '.WindowFocusChanged.id // empty' 2>/dev/null)
    if [[ -n "$new_focus" && "$new_focus" != "$tracked_id" ]]; then
      niri msg action move-window-to-workspace --window-id "$tracked_id" "$scratch_ws" --focus=false
      niri msg action move-window-to-tiling --id "$tracked_id"
      exit 0
    fi
  done < <(niri msg --json event-stream)
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
    #  --focus <FOCUS>  Whether the focus should follow the moved window.
    niri msg action move-window-to-workspace --window-id "$FOCUSED_WIN_ID" "$SCRATCH_WS_NAME" --focus=false
    niri msg action move-window-to-tiling --id "$WIN_ID"
    exit 0
  fi

  # --- Otherwise, show existing window or launch new one ---

  # If no matching window is found, spawn a new one.
  if [ -z "$WIN_ID" ] && [ -n "$APP_CMD" ]; then
    echo "I'M READY TO LAUNCH"
    niri msg action spawn -- sh -c "$APP_CMD"

    if [[ "$AUTO_HIDE" == true ]]; then
      # Poll for the window to appear (up to ~15 s, every 0.5 s)
      local timeout=30
      while [ $timeout -gt 0 ]; do
        sleep 0.5
        WIN_ID=$(niri msg -j windows | jq -r \
          --arg app "$APP_ID" \
          --arg title "$TITLE" \
          '.[] | select(.app_id == $app and (.title | contains($title))) | .id' |
          head -n1)
        if [[ -n "$WIN_ID" ]]; then
          auto_hide_monitor "$WIN_ID" "$SCRATCH_WS_NAME"
          exit 0
        fi
        timeout=$((timeout - 1))
      done
      # Window didn't appear in time — just exit
    fi
    exit 0
  fi

  # Bring window to the current workspace and focus it.
  niri msg action move-window-to-floating --id "$WIN_ID"
  niri msg action move-window-to-workspace --window-id "$WIN_ID" "$CURRENT_WS_REF" --focus=false
  niri msg action focus-window --id "$WIN_ID"

  if [[ "$AUTO_HIDE" == true ]]; then
    auto_hide_monitor "$WIN_ID" "$SCRATCH_WS_NAME"
  fi
}

main() {
  define_parameters
  handle_arguments "$@"
  get_workspaces_info
  hide_or_show
}

main "$@"
