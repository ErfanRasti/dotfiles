#!/usr/bin/env bash

# This script toggles app between special:scratchpad and current workspace
# Handles inputs like:
#   class:org.gnome.Nautilus
#   class:(org.gnome.Nautilus)
#   class:^(org.gnome.SystemMonitor)$

# ./focus_or_launch.sh "class:org.gnome.Nautilus" "nautilus"

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <window_class> <command>"
  exit 1
fi

APP_CLASS="$1"
APP_CMD="$2"

# Get currently focused window's class
FOCUSED_CLASS=$(hyprctl activewindow -j | jq -r '.class' 2>/dev/null)

# Get the class name without "class:" prefix if needed
APP_CLASS_CLEAN=$(echo "$APP_CLASS" | sed -E 's/^class[:(]*\^?//; s/\$?\)*$//')

# If the focused window matches, do nothing
if [ "$FOCUSED_CLASS" = "$APP_CLASS_CLEAN" ]; then
  hyprctl dispatch movetoworkspacesilent special:scratchpad,"$APP_CLASS"
else
  hyprctl dispatch plugin:xtd:moveorexec "$APP_CLASS","$APP_CMD"
fi
