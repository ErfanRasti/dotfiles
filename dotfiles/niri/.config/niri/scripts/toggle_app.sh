#!/usr/bin/env bash

# This script toggles an app between a scratch workspace and the current workspace in niri.
#
# Usage:
#   toggle_app.sh "class:org.gnome.Nautilus" "nautilus"
#
# Semantics (similar to your Hyprland script):
#   - If the focused window has this class/app-id -> send it to workspace "scratchpad" (hide it).
#   - Else:
#       - If a window with that class exists (prefer one on "scratch") -> bring it to current workspace & focus.
#       - Else -> spawn the given command.

set -euo pipefail

# Initialize variables
APP_ID=""
APP_CMD=""
TITLE=""

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
    echo "Toggle an app between a scratch workspace and the current workspace in niri."
    echo
    echo "Options:"
    echo "  -c, --class    Set the window class for the app (required)"
    echo "  -t, --title    Set the window title for extra check (optional)"
    echo "  -h, --help     Show this help message and exit"
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

SCRATCH_WS_NAME="scratchpad"

# --- Get workspace info (current + scratch) ---

WORKSPACES_JSON="$(niri msg -j workspaces)"

# Current workspace: prefer name, fallback to idx.
CURRENT_WS_NAME="$(echo "$WORKSPACES_JSON" | jq -r '.[] | select(.is_focused == true) | .name // empty')"
if [ -n "$CURRENT_WS_NAME" ]; then
  CURRENT_WS_REF="$CURRENT_WS_NAME"
else
  CURRENT_WS_REF="$(echo "$WORKSPACES_JSON" | jq -r '.[] | select(.is_focused == true) | .idx')"
fi

# ID of scratch workspace (must exist and be named "SCRATCH_WS_NAME").
SCRATCH_WS_ID="$(echo "$WORKSPACES_JSON" | jq -r --arg ws "$SCRATCH_WS_NAME" \
  '.[] | select(.name == $ws) | .id' | head -n1)"

if [ -z "$SCRATCH_WS_ID" ]; then
  echo "Error: no workspace named \"$SCRATCH_WS_NAME\" found. Define it in niri.config.kdl:" >&2
  echo "  workspace \"$SCRATCH_WS_NAME\"" >&2
  exit 1
fi

# --- Focused window info ---

FOCUSED_JSON="$(niri msg -j focused-window 2>/dev/null || echo '')"

FOCUSED_APP_ID="$(echo "$FOCUSED_JSON" | jq -r '.app_id // empty')"
FOCUSED_ID="$(echo "$FOCUSED_JSON" | jq -r '.id // empty')"

# --- If focused window already matches -> hide it to scratch ---

if [ -n "$FOCUSED_APP_ID" ] && [ "$FOCUSED_APP_ID" = "$APP_ID" ]; then
  if [ -n "$TITLE" ]; then
    FOCUSED_TITLE="$(niri msg -j windows | jq -r --arg id "$FOCUSED_ID" 'map(select(.id == ($id | tonumber))) | .[0].title // empty')"

    if [[ "$FOCUSED_TITLE" == "$TITLE" ]]; then
      # Title doesn't match, skip hiding the window
      niri msg action move-window-to-workspace --window-id "$FOCUSED_ID" "$SCRATCH_WS_NAME" --focus=false
      exit 0
    fi
  else
    niri msg action move-window-to-workspace --window-id "$FOCUSED_ID" "$SCRATCH_WS_NAME" --focus=false
    exit 0
  fi
fi
# --- Otherwise, show existing window or launch new one ---

WINDOWS_JSON="$(niri msg -j windows)"

# Prefer a window on the scratch workspace with the matching class and title (if provided).
SCRATCH_WIN_JSON="$(
  echo "$WINDOWS_JSON" | jq --arg app "$APP_ID" --argjson wsid "$SCRATCH_WS_ID" --arg title "$TITLE" '
    map(select(.app_id == $app and .workspace_id == $wsid and (.title | contains($title // "")))) | first
  '
)"

WIN_ID=""

if [ "$SCRATCH_WIN_JSON" != "null" ] && [ -n "$SCRATCH_WIN_JSON" ]; then
  WIN_ID="$(echo "$SCRATCH_WIN_JSON" | jq -r '.id')"
else
  # Fallback: any window with this app-id.
  OTHER_WIN_JSON="$(
    echo "$WINDOWS_JSON" | jq --arg app "$APP_ID" '
      map(select(.app_id == $app)) | first
    '
  )"

  if [ "$OTHER_WIN_JSON" != "null" ] && [ -n "$OTHER_WIN_JSON" ]; then
    WIN_ID="$(echo "$OTHER_WIN_JSON" | jq -r '.id')"
  fi
fi

if [ -z "${WIN_ID:-}" ] || { [ -n "$TITLE" ] && [ "$SCRATCH_WIN_JSON" = "null" ]; }; then
  # No existing window with matching class and title -> spawn new instance.
  niri msg action spawn -- sh -c "$APP_CMD"
  exit 0
fi

# Bring window to current workspace, make it floating, focus it.
niri msg action move-window-to-workspace --window-id "$WIN_ID" "$CURRENT_WS_REF" --focus=false
# niri msg action move-window-to-floating --id "$WIN_ID"
niri msg action focus-window --id "$WIN_ID"
