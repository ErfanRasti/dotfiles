#!/usr/bin/env bash
# Weather script for Arch Linux using wttr.in
set -euo pipefail

UNITS="metric"
LOCATION=""
EMOJI=1
SIMPLE=0

show_help() {
  cat <<EOF
Usage: $(basename "$0") [options] [location]

Options:
  -u, --units [metric|imperial]  Use metric (°C) or imperial (°F) units
  -n, --no-emoji                 Disable weather emojis
  -s, --simple                   Show a compact summary (e.g. " 15°C (feels like 16°C), Clear")
  -h, --help                     Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") "Helsinki"
  $(basename "$0") --simple "Paris"
  $(basename "$0") -u imperial "New York"
EOF
}

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
  -u | --units)
    shift
    UNITS="${1:-metric}"
    ;;
  -n | --no-emoji)
    EMOJI=0
    ;;
  -s | --simple)
    SIMPLE=1
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  -*)
    echo "Unknown option: $1"
    echo "Try --help for usage."
    exit 1
    ;;
  *)
    LOCATION="$*"
    break
    ;;
  esac
  shift || true
done

# Build URL
BASE_URL="https://wttr.in"
ENC_LOC="$(printf '%s' "$LOCATION" | sed 's/ /%20/g')"
URL="$BASE_URL/${ENC_LOC}?format=j1"

# Fetch JSON
JSON="$(curl -fsSL "$URL")"

# Extract fields
desc=$(jq -r '.current_condition[0].weatherDesc[0].value' <<<"$JSON")
icon_code=$(jq -r '.current_condition[0].weatherCode' <<<"$JSON")

if [[ "$UNITS" == "imperial" ]]; then
  temp=$(jq -r '.current_condition[0].temp_F' <<<"$JSON")
  feels=$(jq -r '.current_condition[0].FeelsLikeF' <<<"$JSON")
  unit_temp="°F"
else
  temp=$(jq -r '.current_condition[0].temp_C' <<<"$JSON")
  feels=$(jq -r '.current_condition[0].FeelsLikeC' <<<"$JSON")
  unit_temp="°C"
fi

# Emoji mapping
emoji=""
if [[ $EMOJI -eq 1 ]]; then
  case "$icon_code" in
  113) emoji="" ;;                                                                                                 # Clear/Sunny
  116) emoji="" ;;                                                                                                 # Partly cloudy
  119 | 122) emoji="" ;;                                                                                           # Cloudy/Overcast
  176 | 263 | 266 | 293 | 296 | 299 | 302 | 305 | 308 | 353 | 356 | 359) emoji="" ;;                               # Rain
  179 | 182 | 185 | 227 | 230 | 317 | 320 | 323 | 326 | 329 | 332 | 335 | 338 | 368 | 371 | 374 | 377) emoji="" ;; # Snow/Ice
  200) emoji="" ;;                                                                                                 # Thunder
  248 | 260) emoji="󰖑" ;;                                                                                           # Fog/Mist
  *) emoji="" ;;
  esac
fi

# Simple output
if [[ $SIMPLE -eq 1 ]]; then
  printf "%s %s%s (feels like %s%s), %s\n" "$emoji" "$temp" "$unit_temp" "$feels" "$unit_temp" "$desc"
  exit 0
fi

# Full output (same as before)
area=$(jq -r '.nearest_area[0].areaName[0].value' <<<"$JSON")
region=$(jq -r '.nearest_area[0].region[0].value' <<<"$JSON")
country=$(jq -r '.nearest_area[0].country[0].value' <<<"$JSON")
humidity=$(jq -r '.current_condition[0].humidity' <<<"$JSON")
wind_kmph=$(jq -r '.current_condition[0].windspeedKmph' <<<"$JSON")
wind_mph=$(jq -r '.current_condition[0].windspeedMiles' <<<"$JSON")
wind_dir=$(jq -r '.current_condition[0].winddir16Point' <<<"$JSON")
precip_mm=$(jq -r '.current_condition[0].precipMM' <<<"$JSON")
vis_km=$(jq -r '.current_condition[0].visibility' <<<"$JSON")
cloud=$(jq -r '.current_condition[0].cloudcover' <<<"$JSON")
obs_time=$(jq -r '.current_condition[0].localObsDateTime' <<<"$JSON")

if [[ "$UNITS" == "imperial" ]]; then
  unit_wind="mph"
  unit_vis="mi"
  vis=$(awk -v km="$vis_km" 'BEGIN{printf "%.1f", km*0.621371}')
  wind="$wind_mph"
else
  unit_wind="km/h"
  unit_vis="km"
  vis="$vis_km"
  wind="$wind_kmph"
fi

place="$area"
[[ -z "$place" || "$place" == "null" ]] && place="${LOCATION:-(auto location)}"
if [[ "$region" != "null" && "$country" != "null" ]]; then
  place="$place, $region, $country"
fi

printf "%s %s\n" "$emoji" "$place"
printf "%s\n" "Observed: $obs_time"
printf "Now: %s%s (feels like %s%s), %s\n" "$temp" "$unit_temp" "$feels" "$unit_temp" "$desc"
printf "Humidity: %s%%  |  Wind: %s %s %s  |  Visibility: %s %s  |  Cloud: %s%%  |  Precip (1h): %s mm\n" \
  "$humidity" "$wind" "$unit_wind" "$wind_dir" "$vis" "$unit_vis" "$cloud" "$precip_mm"
