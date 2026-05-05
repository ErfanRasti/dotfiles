#!/usr/bin/env bash

TMP="/tmp/last_player"

players=$(playerctl -l 2>/dev/null)

# 1) If no players exist → save empty and exit
if [[ -z "$players" ]]; then
  echo -n "" >"$TMP"
  exit 0
fi

# Read tmp value (may be empty)
saved=$(cat "$TMP" 2>/dev/null)

# 2) Otherwise, if a player is currently playing → save it
current_playing=""
while read -r p; do
  if [[ $(playerctl --player="$p" status 2>/dev/null) == "Playing" ]]; then
    current_playing="$p"
    break
  fi
done <<<"$players"

if [[ -n "$current_playing" ]]; then
  echo "$current_playing" >"$TMP"
  exit 0
fi

# 3) If saved is not empty AND saved is still a valid player → do nothing
if [[ -n "$saved" ]] && printf "%s\n" "$players" | grep -q "^$saved$"; then
  exit 0
fi

# 4) If no currently playing player AND saved is empty → save last player in list
if [[ -z "$current_playing" && -z "$saved" ]]; then
  # save last player in list
  last=$(printf "%s\n" "$players" | tail -n 1)
  echo "$last" >"$TMP"
  exit 0
fi
