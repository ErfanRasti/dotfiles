#!/bin/bash

# Default wallpapers root used by -r when no path is provided
DEFAULT_WALLPAPER_DIR="$HOME/wallpapers"

print_help() {
  cat <<'EOF'
Usage:
  set_wallpaper.sh /path/to/wallpaper.jpg
    Set the wallpaper to the specified image file.

  set_wallpaper.sh -r
    Pick a random image from $HOME/wallpapers (recursively) and set it.

  set_wallpaper.sh -r <FOLDER_PATH>
    Pick a random image from <FOLDER_PATH> (recursively) and set it.

  set_wallpaper.sh -h | --help
    Show this help message.

Notes:
- Random selection searches common image extensions recursively: jpg, jpeg, png, webp, bmp, tiff, gif.
- The image is copied to: ~/.config/hypr/tmp/hyprland-wallpaper (no extension).
EOF
}

# Pick a random image (recursively) from a directory
pick_random_image() {
  local root="$1"
  # Follow symlinks so "$HOME/wallpapers" works even if it's a symlink.
  find -L "$root" -type f \( \
    -iname '*.jpg' -o -iname '*.jpeg' -o \
    -iname '*.png' -o -iname '*.webp' -o \
    -iname '*.bmp' -o -iname '*.tif' -o -iname '*.tiff' -o \
    -iname '*.gif' \
    \) 2>/dev/null | shuf -n 1
}

# ---- Argument parsing ----
if [ $# -eq 0 ]; then
  echo "Error: Please provide an image path or a flag."
  echo "Try: $0 -h"
  exit 1
fi

case "$1" in
-h | --help)
  print_help
  exit 0
  ;;
-r)
  TARGET_DIR="${2:-$DEFAULT_WALLPAPER_DIR}"
  if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
  fi
  SELECTED="$(pick_random_image "$TARGET_DIR")"
  if [ -z "$SELECTED" ]; then
    echo "Error: No images found under '$TARGET_DIR'."
    exit 1
  fi
  WALLPAPER_PATH="$SELECTED"
  echo "Randomly selected wallpaper: $WALLPAPER_PATH"
  ;;
*)
  WALLPAPER_PATH="$1"
  ;;
esac

# ---- Validation for explicit or selected file ----
if [ ! -f "$WALLPAPER_PATH" ]; then
  echo "Error: The specified wallpaper file '$WALLPAPER_PATH' does not exist."
  exit 1
fi

# ---- Prepare temp path ----
TMP_DIR="$HOME/.config/hypr/tmp"
TMP_WALLPAPER="$TMP_DIR/hyprland-wallpaper"

# Copy wallpaper (ignore extension, keep raw data)
mkdir -p "$TMP_DIR"
cp "$WALLPAPER_PATH" "$TMP_WALLPAPER"

# ---- Hyprpaper reload ----
hyprctl hyprpaper reload ,$TMP_WALLPAPER

# ---- Hyprpanel update ----
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
      echo "$HYPRPANEL_OUTPUT_FILE already exists - updating to template ..."
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
  # killall "$(pgrep hyprpanel)"
  hyprpanel -q
  update_hyprpanel_wallpaper
  hyprpanel &
  echo "Hyprpanel restarted."
else
  update_hyprpanel_wallpaper
  hyprpanel &
  echo "Hyprpanel started."
fi

# ---- Rofi configs (optional helper) ----
if [ -x "$HOME/.config/hypr/scripts/update_rofi_configs.sh" ]; then
  "$HOME/.config/hypr/scripts/update_rofi_configs.sh"
else
  echo "Error: update_rofi_configs.sh not found or not executable"
  exit 1
fi

echo "Wallpaper updated to: $TMP_WALLPAPER"
echo "Note: File has no extension but retains original image data."
