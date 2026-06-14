#!/usr/bin/env bash

# --- cover art cache (square only) ---
COVER_BASE="/tmp/mpris-cover"       # base path (no extension)
COVER_IMG="${COVER_BASE}.png"       # simple square cover
COVER_BLUR="${COVER_BASE}-blur.png" # blurred square cover
COVER_INFO="${COVER_BASE}.inf"      # stores last artUrl to avoid needless writes

# Optional: command to run after cover updates (leave empty to disable)
POST_UPDATE_CMD="pkill -USR2 hyprlock" # e.g. POST_UPDATE_CMD="pkill -USR2 hyprlock"
# Optional: set to 0 to skip blurred generation
GENERATE_BLUR=0
# Optional: pixel size for square output (both simple and blurred)
COVER_SIZE="512x512"

# --- Prefer the player that is actually Playing ---
LAST_PLAYER_FILE="/tmp/mpris-last-player"

# Find the active player (prefer one that's Playing)
players=$(playerctl -l 2>/dev/null)

# If no players, exit

if [ -z "$players" ]; then
  # ensure a cover exists even with no players
  rm -f $COVER_IMG $COVER_BLUR $COVER_INFO
  exit 0
fi

current_player=""
player_status=""

# Prefer the player that is actually Playing
for p in $players; do
  st=$(playerctl -p "$p" status 2>/dev/null)
  if [ "$st" = "Playing" ]; then
    current_player="$p"
    player_status="$st"
    # Save the active player for future reference
    echo "$p" >"$LAST_PLAYER_FILE"
    break
  fi
done

# --- If none are Playing, use last used player or first available ---
if [ -z "$current_player" ]; then
  last_player=$(cat "$LAST_PLAYER_FILE" 2>/dev/null)
  if echo "$players" | grep -qx "$last_player"; then
    current_player="$last_player"
  else
    current_player=$(echo "$players" | head -n1)
  fi
  player_status=$(playerctl -p "$current_player" status 2>/dev/null)
fi

# Set default status icons (play / pause / stop)
case "$player_status" in
Playing)
  player_status_icon="" # Play icon
  ;;
Paused)
  player_status_icon="" # Pause icon
  ;;
Stopped)
  player_status_icon="" # Stop icon
  ;;
*)
  player_status_icon="󱟛" # Unknown / idle
  ;;
esac

# Get player name (lowercase for consistency)
player_name=$(playerctl -p "$current_player" metadata --format '{{lc(playerName)}}' 2>/dev/null)

# Choose player-specific icon
case $player_name in
spotify)
  player_icon="" # Spotify
  ;;
chromium | chrome | google-chrome)
  player_icon="" # YouTube (via Chrome)
  ;;
firefox)
  player_icon="" # Firefox
  ;;
vlc)
  player_icon="󰕼" # VLC
  ;;
mpv)
  player_icon="" # MPV
  ;;
*)
  player_icon="" # Default music icon
  ;;
esac

# Get song/video info
title=$(playerctl -p "$current_player" metadata title 2>/dev/null)
artist=$(playerctl -p "$current_player" metadata artist 2>/dev/null)

maxlen=20
# Truncate if longer than maxlen
short_title="$title"
short_artist="$artist"
[ ${#title} -gt $maxlen ] && short_title="${title:0:$maxlen}…"
[ ${#artist} -gt $maxlen ] && short_artist="${artist:0:$maxlen}…"

# Fetch the music cover
fetch_cover() {
  # Need a player selected first
  if [ -z "$current_player" ]; then
    rm -f $COVER_IMG $COVER_BLUR $COVER_INFO
    return 0
  fi

  # Get art URL
  artUrl=$(playerctl -p "$current_player" metadata --format '{{mpris:artUrl}}' 2>/dev/null)
  if [ -z "$artUrl" ]; then
    rm -f "$COVER_IMG" "$COVER_BLUR" "$COVER_INFO"
    return 0
  fi

  # Download image if it changes
  if [ "$artUrl" != "$(cat "$COVER_INFO" 2>/dev/null)" ]; then
    printf '%s\n' "$artUrl" >"$COVER_INFO"
    tmp_dl="${COVER_BASE}.dl"
    curl -fsSL "$artUrl" -o "$tmp_dl" || return 0

    # Normalize: crop & resize to square PNG (centered)
    magick "$tmp_dl" -auto-orient -resize "${COVER_SIZE:-512x512}^" \
      -gravity center -extent "${COVER_SIZE:-512x512}" \
      -strip -quality 92 PNG24:"$COVER_IMG"

    rm -f "$tmp_dl"
  fi

  # Optional: blurred version
  if [ "${GENERATE_BLUR:-1}" -eq 1 ] && [ -f "$COVER_IMG" ]; then
    magick "$COVER_IMG" -blur 0x20 -strip PNG24:"$COVER_BLUR"
  fi
  return 0
}

# if [ -n "$POST_UPDATE_CMD" ]; then
#   eval "$POST_UPDATE_CMD" >/dev/null 2>&1 || true
# fi

usage() {
  echo "Usage: $0 [OPTION]

Options:
  --title             Show only the current track title
  --artist            Show only the current track artist
  --short-title       Show only the current track title in short
  --short-artist      Show only the current track artist in short
  --status            Show playback status (Playing/Paused/Stopped)
  --status-icon       Show playback status icon (Playing/Paused/Stopped)
  --player            Show the current player's name
  --player-real-name  Show the current player's real name
  --player-icon       Show the current player's icon
  --cover-path        Show the cover path of the current player
  --cover-blur-path   Show the blurred cover path of the current player
  --all               Show full formatted output (icon + status + title - artist)
  --help, -h          Show this help message
  (no option)         Same as --all
"
}

# Handle flags: --title | --artist | --status | --player-icon (default = --all)
mode="${1:---all}"

case "$mode" in
--title)
  [ -n "$title" ] && echo "$title"
  exit 0
  ;;
--short-title)
  [ -n "$title" ] && echo "$short_title"
  exit 0
  ;;
--artist)
  [ -n "$artist" ] && echo "$artist"
  exit 0
  ;;
--short-artist)
  [ -n "$artist" ] && echo "$short_artist"
  exit 0
  ;;
--status)
  echo "$player_status"
  exit 0
  ;;
--status-icon)
  echo "$player_status_icon"
  exit 0
  ;;
--player)
  echo "$player_name"
  exit 0
  ;;
--player-real-name)
  echo "$current_player"
  exit 0
  ;;
--player-icon)
  echo "$player_icon"
  exit 0
  ;;
--cover-path)
  # Update cover art cache (only if art changed)
  fetch_cover
  echo "$COVER_IMG"
  exit 0
  ;;
--cover-blur-path)
  if [ "${GENERATE_BLUR:-1}" -eq 1 ]; then
    # Update cover art cache (only if art changed)
    fetch_cover
    echo "$COVER_BLUR"
  fi
  exit 0
  ;;
--help | -h)
  usage
  exit 0
  ;;
--all)
  # No argument passed — continue to full output
  ;;
*)
  echo "Error: Unknown option '$mode'"
  usage
  exit 1
  ;;
esac

# Format output (icon + play/pause + title - artist)
if [ -n "$title" ]; then
  if [ -n "$artist" ]; then
    echo "$player_icon $player_status_icon | $title - $artist"
  else
    echo "$player_icon $player_status_icon | $title"
  fi
else
  echo "$player_icon $player_status_icon | No title detected"
fi
