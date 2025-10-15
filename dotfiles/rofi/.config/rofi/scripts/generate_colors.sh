#!/usr/bin/env bash

# Read wallpaper path from hyprpanel config
export WALLPAPER=$(jq -r '."wallpaper.image"' ~/.config/hyprpanel/config.json 2>/dev/null || grep -oP '"wallpaper.image":\s*"\K[^"]+' ~/.config/hyprpanel/config.json)

# Exit if wallpaper not found
if [[ -z "$WALLPAPER" || "$WALLPAPER" == "null" ]]; then
  notify-send "⚠️ Error" "Wallpaper path not found in config!"
  exit 1
fi

# Fast color extraction
COLORS=($(magick "$WALLPAPER" \
  -resize 600x600 \
  -dither None \
  -colors 6 \
  -define histogram:unique-colors=true \
  -format "%c" histogram:info: |
  sort -nr |
  awk 'NR<=6 {print $3}' |
  sort -h))

# Fast luminance calculation
luminance() {
  read r g b <<<$(echo "${1#"#"}" | sed 's/../0x& /g')
  echo "$(((r * 2126 + g * 7152 + b * 722) / 10000))"
}

# Create luminance map
declare -A lum_map
for color in "${COLORS[@]}"; do
  lum_map["$color"]=$(luminance "$color")
done

# Find extremes
min_lum=1000
max_lum=0
for color in "${!lum_map[@]}"; do
  lum=${lum_map["$color"]}
  ((lum < min_lum)) && {
    min_lum=$lum
    COLOR_BACKGROUND="$color"
  }
  ((lum > max_lum)) && {
    max_lum=$lum
    COLOR_FOREGROUND="$color"
  }
done

# Remove used colors
COLORS=("${COLORS[@]/$COLOR_BACKGROUND/}")
COLORS=("${COLORS[@]/$COLOR_FOREGROUND/}")
COLORS=("${COLORS[@]}")

# Sort remaining colors
readarray -t sorted_colors < <(for color in "${COLORS[@]}"; do
  echo "${lum_map["$color"]} $color"
done | sort -n | awk '{print $2}')

# Function to add transparency based on color role
get_alpha() {
  case "$1" in
  "BACKGROUND") echo "EE" ;;     # 80% opacity
  "BACKGROUND_ALT") echo "FF" ;; # 60% opacity
  "FOREGROUND") echo "FF" ;;     # 100% opaque
  "SELECTED") echo "B3" ;;       # 70% opacity
  "ACTIVE") echo "E6" ;;         # 90% opacity
  "URGENT") echo "80" ;;         # 50% opacity
  *) echo "FF" ;;
  esac
}

# Export colors with transparency
export COLOR_BACKGROUND="$COLOR_BACKGROUND$(get_alpha "BACKGROUND")"
export COLOR_BACKGROUND_ALT="${sorted_colors[0]}$(get_alpha "BACKGROUND_ALT")"
export COLOR_FOREGROUND="$COLOR_FOREGROUND$(get_alpha "FOREGROUND")"
export COLOR_SELECTED="${sorted_colors[2]}$(get_alpha "SELECTED")"
export COLOR_ACTIVE="${sorted_colors[3]}$(get_alpha "ACTIVE")"
export COLOR_URGENT="${sorted_colors[1]}$(get_alpha "URGENT")"
