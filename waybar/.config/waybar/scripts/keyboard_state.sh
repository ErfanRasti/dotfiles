#!/usr/bin/env bash
# ~/.local/bin/capslock-waybar.sh
# Continuously report Caps Lock state to Waybar as single-line JSON.
# Uses inotify when available (efficient, event-driven), otherwise falls back to polling.

set -u # Treat unset variables as errors

# --------------------------------------------------------------------
# Find the first Caps Lock LED brightness file in /sys
# (This file shows 1 when Caps Lock is ON, 0 when OFF)
find_caps_file() {
  for f in /sys/class/leds/*::capslock/brightness; do
    [[ -e "$f" ]] && {
      printf '%s\n' "$f"
      return
    }
  done
}

# --------------------------------------------------------------------
# Emit JSON for Waybar (one line) with text, tooltip, class, etc.
# Waybar expects JSON objects with "text", "alt", "tooltip", "class"
emit_json() {
  local state="$1"
  local icon_on="󰪛" # Nerd Font icon for Caps Lock ON
  local icon_off="" # Show nothing when OFF
  local text alt tooltip class

  if [[ "$state" == "on" ]]; then
    text="$icon_on"
    alt="on"
    tooltip="Caps Lock is ON"
    class='["caps","on"]'
  else
    text="$icon_off"
    alt="off"
    tooltip="Caps Lock is OFF"
    class='["caps","off"]'
  fi

  # Print JSON (single line) for Waybar
  printf '{"text":"%s","alt":"%s","tooltip":"%s","class":%s}\n' \
    "$text" "$alt" "$tooltip" "$class"
}

# --------------------------------------------------------------------
# Detect if inotifywait is available (preferred method)
have_inotify=0
if command -v inotifywait >/dev/null 2>&1; then
  have_inotify=1
fi

prev="" # Remember last Caps Lock state (0 or 1)

# --------------------------------------------------------------------
# Main loop: keeps running forever
while :; do
  # Try to find the caps lock sysfs file
  caps_file="$(find_caps_file)"

  # If not found (e.g. keyboard unplugged), print error JSON
  if [[ -z "${caps_file:-}" ]]; then
    printf '{"text":"","alt":"error","tooltip":"No Caps Lock LED found","class":["caps","error"]}\n'
    prev=""
    sleep 1 # Wait a bit, then retry
    continue
  fi

  # Emit initial state once
  curr="$(<"$caps_file")"
  if [[ "${curr:-0}" -eq 1 ]]; then
    emit_json "on"
    prev="1"
  else
    emit_json "off"
    prev="0"
  fi

  # ----------------------------------------------------------------
  # If inotify is available, use event-driven mode (efficient)
  if [[ $have_inotify -eq 1 ]]; then
    # Watch the caps file for changes/deletion
    # Process substitution (< <(...)) avoids an extra subshell
    while IFS= read -r _; do
      # If the file vanished, break out to rediscover
      [[ -e "$caps_file" ]] || break

      curr="$(<"$caps_file")"
      if [[ "$curr" != "$prev" ]]; then
        if [[ "$curr" -eq 1 ]]; then
          emit_json "on"
        else
          emit_json "off"
        fi
        prev="$curr"
      fi
    done < <(inotifywait -mq \
      -e modify -e close_write -e delete_self -e move_self \
      --format "%e" "$caps_file")

    # Reset state after file disappears or watcher stops
    prev=""

  else
    # ----------------------------------------------------------------
    # Fallback: polling mode (less efficient, uses sleep)
    while [[ -e "$caps_file" ]]; do
      sleep 0.2 # Check every 200ms
      curr="$(<"$caps_file")"
      if [[ "$curr" != "$prev" ]]; then
        if [[ "$curr" -eq 1 ]]; then
          emit_json "on"
        else
          emit_json "off"
        fi
        prev="$curr"
      fi
    done
    prev=""
  fi
done
