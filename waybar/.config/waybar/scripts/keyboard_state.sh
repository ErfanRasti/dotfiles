#!/usr/bin/env bash
# ~/.local/bin/capslock-waybar.sh
# Continuously report Caps Lock state to Waybar as single-line JSON.

set -u

# Find the first Caps Lock LED brightness file
find_caps_file() {
  ls /sys/class/leds/input*::capslock/brightness 2>/dev/null | head -n 1
}

caps_file="$(find_caps_file)"

# Small helper to emit JSON in one line
emit_json() {
  local state="$1"
  local icon_on="󰪛" # Nerd Font icon for Caps Lock ON
  local icon_off="" # Show nothing when OFF
  local alt tooltip class

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

  printf '{"text":"%s","alt":"%s","tooltip":"%s","class":%s}\n' \
    "$text" "$alt" "$tooltip" "$class"
}

# If no LED found, print an error JSON and exit
if [[ -z "${caps_file:-}" ]]; then
  printf '{"text":"","alt":"error","tooltip":"No Caps Lock LED found","class":["caps","error"]}\n'
  exit 1
fi

prev=""

# Optional: prefer inotify if available (fast + efficient), fall back to polling
have_inotify=0
if command -v inotifywait >/dev/null 2>&1; then
  # Some sysfs files don’t trigger MODIFY; CLOSE_WRITE tends to work better
  have_inotify=1
fi

# Emit once at startup
curr="$(<"$caps_file")"
if [[ "${curr:-0}" -eq 1 ]]; then
  emit_json "on"
  prev="1"
else
  emit_json "off"
  prev="0"
fi

# Main loop: wait for changes and emit updates
while :; do
  # Re-detect the file if it disappeared (e.g., keyboard unplugged/replugged)
  if [[ ! -e "$caps_file" ]]; then
    caps_file="$(find_caps_file)"
    if [[ -z "$caps_file" ]]; then
      # Keep informing Waybar; it will update the tooltip and class
      printf '{"text":"","alt":"error","tooltip":"No Caps Lock LED found","class":["caps","error"]}\n'
      sleep 1
      continue
    fi
    # Newly found file; force an update on next iteration
    prev=""
  fi

  # Wait for a change
  if [[ $have_inotify -eq 1 ]]; then
    # inotifywait exits after one event; suppress output
    inotifywait -qq -e modify -e close_write --format "" "$caps_file" || sleep 0.2
  else
    # Lightweight polling fallback
    sleep 0.2
  fi

  # Read current value and emit only if it changed
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
