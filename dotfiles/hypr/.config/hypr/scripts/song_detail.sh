#!/usr/bin/env bash

# Get player status (Playing/Paused/Stopped)
player_status=$(playerctl -p spotify status 2>/dev/null)

# If no player is running, exit gracefully
if [ -z "$player_status" ]; then
  exit 0
fi

# Get player name (lowercase for consistency)
player_name=$(playerctl -p spotify metadata --format '{{lc(playerName)}}' 2>/dev/null)

# Set default play/pause icons
if [ "$player_status" = "Playing" ]; then
  play_pause_icon="" # Playing icon ()
else
  play_pause_icon="" # Paused icon ()
fi

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
title=$(playerctl -p spotify metadata title 2>/dev/null)
artist=$(playerctl -p spotify metadata artist 2>/dev/null)

# Format output (icon + play/pause + title - artist)
if [ -n "$title" ]; then
  if [ -n "$artist" ]; then
    echo "$player_icon $play_pause_icon $title - $artist"
  else
    echo "$player_icon $play_pause_icon $title"
  fi
else
  echo "$player_icon $play_pause_icon No title detected"
fi
