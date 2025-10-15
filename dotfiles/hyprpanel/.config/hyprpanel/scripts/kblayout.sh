#!/usr/bin/env bash
# Prints a short label for the active layout/variant

# Get active keymaps from hyprctl (text mode is fine)
raw="$(hyprctl devices | awk '/active keymap/ {print $3,$4,$5,$6,$7,$8}')"

# Examples you might see: "US", "Persian", "Persian (Windows)"
tag="??"
case "$raw" in
*"Persian (Windows)"* | *"Persian (Winkeys)"* | *"ir (winkeys)"*)
  tag="IR"
  ;;
*"Persian"*)
  tag="IR"
  ;;
*"US"*)
  tag="US"
  ;;
esac

echo "{\"state\": \"${tag}\"}"
