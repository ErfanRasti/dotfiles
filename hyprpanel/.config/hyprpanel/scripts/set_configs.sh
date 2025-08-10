#!/bin/bash

# Function to display help
display_help() {
  echo "Usage: $0 WALLPAPER_PATH [OPTIONS]"
  echo
  echo "Options:"
  echo "  -m, --mode MODE      Set color mode (dark/light) [default: dark]"
  echo "  -t, --type TYPE      Set scheme type [default: scheme-tonal-spot]"
  echo "                       Possible values: scheme-content, scheme-expressive,"
  echo "                       scheme-fidelity, scheme-fruit-salad, scheme-monochrome,"
  echo "                       scheme-neutral, scheme-rainbow, scheme-tonal-spot"
  echo "  -h, --help           Display this help message"
  exit 0
}

# Default values
mode="dark"
type="scheme-tonal-spot"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -m | --mode)
    mode="$2"
    # Validate mode
    if [[ "$mode" != "dark" && "$mode" != "light" ]]; then
      echo "Error: Invalid mode '$mode'. Must be 'dark' or 'light'"
      exit 1
    fi
    shift 2
    ;;
  -t | --type)
    type="$2"
    # Validate type (you can add more validation if needed)
    shift 2
    ;;
  -h | --help)
    display_help
    ;;
  *)
    if [[ -z "$wallpaper" ]]; then
      wallpaper="$1"
    else
      echo "Error: Unknown argument '$1'"
      display_help
      exit 1
    fi
    shift
    ;;
  esac
done

# Check if wallpaper path was provided
if [[ -z "$wallpaper" ]]; then
  echo "Error: Wallpaper path is required"
  display_help
  exit 1
fi

# Check if wallpaper file exists
if [[ ! -f "$wallpaper" ]]; then
  echo "Error: Wallpaper file '$wallpaper' not found"
  exit 1
fi

# Your original function with modifications
update_hyprpanel_wallpaper() {
  HYPRPANEL_MAIN_FILE="$HOME/.config/hyprpanel/hyprpanel-main.json"
  HYPRPANEL_OUTPUT_FILE="$HOME/.config/hyprpanel/config.json"
  export HYPRLPANEL_WALLPAPER_PATH="$wallpaper"
  export HYPRPANEL_AVATAR_PATH="$HOME/Pictures/MyImages/ERS.jpg"
  export HYPRPANEL_COLOR_MODE="$mode"
  # Ignore scheme at the first part
  export HYPRPANEL_COLOR_TYPE="${type:7}"

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

# Apply matugen configurations
matugen image $wallpaper -m $mode -t $type

# Restart hyprpolkitagent.service to apply qt themes on it
systemctl --user restart hyprpolkitagent.service

# Apply spicetify themes
spicetify config current_theme matugen
spicetify config color_scheme matugen
spicetify apply

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
