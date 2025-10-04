#!/usr/bin/env bash
# ~/.local/bin/capslock-waybar.sh
# Tiny, low-CPU Caps Lock indicator for Waybar.
# Prints a JSON line only when the state changes.

set -Eeuo pipefail

shopt -s nullglob

find_caps_file() {
  for f in /sys/class/leds/*::capslock/brightness; do
    [[ -e "$f" ]] && {
      printf '%s\n' "$f"
      return 0
    }
  done
  return 1
}

emit_json() {
  local state="$1"
  if [[ "$state" == "on" ]]; then
    # Nerd Font icon when ON; empty when OFF (so it disappears)
    printf '{"text":"󰪛","alt":"on","tooltip":"Caps Lock is ON","class":["caps","on"]}\n'
  else
    printf '{"text":"","alt":"off","tooltip":"Caps Lock is OFF","class":["caps","off"]}\n'
  fi
}

read_state() {
  local file="$1" v="0"
  # Read without forking `cat`
  if read -r v <"$file"; then
    [[ "$v" -eq 1 ]] && printf 'on\n' || printf 'off\n'
  else
    printf 'off\n'
  fi
}

caps_file=""
prev=""

while :; do
  # (Re)discover caps file if needed
  if [[ -z "${caps_file:-}" || ! -e "$caps_file" ]]; then
    caps_file="$(find_caps_file || true)"
    if [[ -z "${caps_file:-}" ]]; then
      # Only emit the error once per missing period
      if [[ "${prev:-}" != "error" ]]; then
        printf '{"text":"","alt":"error","tooltip":"No Caps Lock LED found","class":["caps","error"]}\n'
        prev="error"
      fi
      sleep 2
      continue
    fi
    # New device found: force initial emit
    prev=""
  fi

  curr="$(read_state "$caps_file")"
  if [[ "$curr" != "$prev" ]]; then
    emit_json "$curr"
    prev="$curr"
  fi

  # Gentle poll; bump to 1.0s if you want even less wakeups
  sleep 0.5
done
