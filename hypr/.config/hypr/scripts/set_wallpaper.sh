#!/bin/bash

# Check if a file path was provided as an argument
if [ -z "$1" ]; then
  echo "Error: Please provide the wallpaper image path as an argument."
  echo "Usage: $0 /path/to/wallpaper.jpg"
  exit 1
fi

# Check if the provided file exists
if [ ! -f "$1" ]; then
  echo "Error: The specified wallpaper file '$1' does not exist."
  exit 1
fi

# Temp directory and wallpaper name
TMP_DIR="$HOME/.config/hypr/tmp"
TMP_WALLPAPER="$TMP_DIR/hyprland-wallpaper"

# Ensure temp directory exists
mkdir -p "$TMP_DIR"

# Copy wallpaper (ignore extension, keep raw data)
cp "$1" "$TMP_WALLPAPER"

# Reload hyprpaper
hyprctl hyprpaper reload ,$TMP_WALLPAPER

# Update hyprpanel wallpaper
update_hyprpanel_wallpaper() {
  HYPRPANEL_MAIN_FILE="$HOME/.config/hyprpanel/hyprpanel-main.json"
  HYPRPANEL_OUTPUT_FILE="$HOME/.config/hyprpanel/config.json"
  export HYPRLPANEL_WALLPAPER_PATH=$TMP_WALLPAPER
  export HYPRPANEL_AVATAR_PATH="$HOME/Pictures/MyImages/ERS.jpg"
  # Check if template exists
  if [ -f "$HYPRPANEL_MAIN_FILE" ]; then
    # Check if output file exists
    if [ ! -f "$HYPRPANEL_OUTPUT_FILE" ]; then
      echo "$HYPRPANEL_OUTPUT_FILE not found - creating from template..."
    else
      echo "$HYPRPANEL_OUTPUT_FILE already exists - updating to template ... "
    fi
    # Process template with environment variable substitution
    envsubst <"$HYPRPANEL_MAIN_FILE" >"$HYPRPANEL_OUTPUT_FILE"
    echo "Created $HYPRPANEL_OUTPUT_FILE from template with environment variables expanded"
  else
    echo "Error: Template file $HYPRPANEL_MAIN_FILE not found"
    exit 1
  fi
}

# Kill and restart hyprpanel
if pgrep hyprpanel >/dev/null; then
  hyprpanel -q
  update_hyprpanel_wallpaper
  hyprpanel &
  echo "Hyprpanel restarted."
else
  update_hyprpanel_wallpaper
  hyprpanel &
  echo "Hyprpanel started."
fi

# Only run rofi config update if the script exists and is executable
if [ -x "$HOME/.config/hypr/scripts/update_rofi_configs.sh" ]; then
  "$HOME/.config/hypr/scripts/update_rofi_configs.sh"
else
  echo "Error: update_rofi_configs.sh not found or not executable"
  exit 1
fi

echo "Wallpaper updated to: $TMP_WALLPAPER"
echo "Note: File has no extension but retains original image data."
