#!/usr/bin/env bash

SAVE_DIR="$HOME/Pictures/Screenshots"
NOTIFY_EXPIRE=5000 # milliseconds

# Choose mode (region, output, or window)
MODE=""
case "$1" in
region) MODE="region" ;;
output) MODE="output" ;;
window) MODE="window" ;;
*)
  ~/.config/rofi/applets/bin/screenshot.sh && exit 0
  ;;
esac

# Take the screenshot
TIMESTAMP=$(date +'%Y-%m-%d-%H%M%S')
FILE_NAME="${TIMESTAMP}_hyprshot.png"
hyprshot -sm "$MODE" -z -o "$SAVE_DIR" -f "$FILE_NAME"
STATUS=$?
FILE=$SAVE_DIR/$FILE_NAME

# Handle exit conditions
sleep 0.1
if [ $STATUS -ne 0 ]; then
  # real error → show fail notification
  notify-send "󰹑  Screenshot failed" "No file saved."
  exit 1
elif [ ! -f "$FILE" ]; then
  # user cancelled (pressed Esc) → exit quietly
  exit 0
fi
sleep 1

# Send notification with an Open button (SwayNC supports this)
ACTION=$(
  notify-send -u critical -a Hyprshot "󰹑 Screenshot saved" \
    "Image saved in ~/Pictures/Screenshots/$FILE_NAME and copied to the clipboard." \
    --action=open_image=" Open Image" \
    --action=open_folder=" Open Folder" \
    --expire-time=$NOTIFY_EXPIRE \
    --icon="$FILE"
)
# Wait for button press from SwayNC
case "$ACTION" in
open_image)
  eog "$FILE" &
  disown
  ;;
open_folder)
  nautilus "$FILE" &
  disown
  ;;
esac
