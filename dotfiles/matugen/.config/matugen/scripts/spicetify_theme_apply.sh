#!/usr/bin/env bash
# Reload Spotify via Ctrl+Shift+R, then return to the previous window

# if hyprland doesn't exist apply and exit
if ! pgrep -x "Hyprland" >/dev/null 2>&1; then
  spicetify config current_theme matugen color_scheme Base
  spicetify refresh -s
  # spicetify apply
  exit 0
fi

theme=$(spicetify config current_theme)
scheme=$(spicetify config color_scheme)

# spicetify update

# If the matugen theme is not applied
if [[ "$theme" != "matugen" || "$scheme" != "Base" ]]; then
  spicetify config current_theme matugen color_scheme Base
  spicetify apply enable-devtools
else
  # Get the currently active window address
  ACTIVE_WINDOW=$(hyprctl activewindow -j | jq -r '.address' 2>/dev/null)

  # Find Spotify window class (first match)
  SPOTIFY_WINDOW=$(hyprctl clients -j | jq -r '.[] | select(.class | test("Spotify"; "i")) | .address' | head -n 1)

  spicetify refresh -s

  if [ -z "$SPOTIFY_WINDOW" ]; then
    echo "Spotify window not found."
    exit 0
  fi

  # Focus Spotify
  hyprctl dispatch focuswindow address:"$SPOTIFY_WINDOW"

  # Send Ctrl+Shift+R to Spotify
  ydotool key 29:1 42:1 19:1 19:0 42:0 29:0

  # Return to previously focused window
  if [ -n "$ACTIVE_WINDOW" ]; then
    hyprctl dispatch focuswindow address:"$ACTIVE_WINDOW"
  fi
fi
