#!/usr/bin/env bash

# File to save state
STATE_FILE="$HOME/.cache/hypridle-devices.state"

# Wait until a Bluetooth adapter exists (max 5s)
wait_for_bt() {
  local timeout=10
  while ((timeout > 0)); do
    if bluetoothctl show >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
    ((timeout--))
  done
  # return 1
}

case "$1" in
save)
  # Save network state
  if [[ $(nmcli radio wifi) == "enabled" ]]; then
    echo "network:on" >"$STATE_FILE"
  else
    echo "network:off" >"$STATE_FILE"
  fi

  # Save bluetooth state
  if bluetoothctl show | grep -qF "Powered: yes"; then
    echo "bluetooth:on" >>"$STATE_FILE"
  else
    echo "bluetooth:off" >>"$STATE_FILE"
  fi

  # Save output state
  if pactl get-sink-mute @DEFAULT_SINK@ | grep -q "no"; then
    echo "sink:on" >>"$STATE_FILE"
  else
    echo "sink:off" >>"$STATE_FILE"
  fi

  # Save input state
  if pactl get-source-mute @DEFAULT_SOURCE@ | grep -q "no"; then
    echo "source:on" >>"$STATE_FILE"
  else
    echo "source:off" >>"$STATE_FILE"
  fi

  # Save input and output volumes
  echo "sinkvol:$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1 {print $5}')" >>"$STATE_FILE"
  echo "sourcevol:$(pactl get-source-volume @DEFAULT_SOURCE@ | awk 'NR==1 {print $5}')" >>"$STATE_FILE"

  ;;

restore)
  if [[ -f "$STATE_FILE" ]]; then
    wait_for_bt || echo "No Bluetooth adapter found"
    while read -r line; do
      case "$line" in
      network:on)
        rfkill unblock wifi
        nmcli radio wifi on
        ;;
      network:off) nmcli radio wifi off ;;
      bluetooth:on)
        rfkill unblock bluetooth
        bluetoothctl power on
        ;;
      bluetooth:off) bluetoothctl power off ;;
      sink:on) pactl set-sink-mute @DEFAULT_SINK@ 0 ;;
      sink:off) pactl set-sink-mute @DEFAULT_SINK@ 1 ;;
      source:on) pactl set-source-mute @DEFAULT_SOURCE@ 0 ;;
      source:off) pactl set-source-mute @DEFAULT_SOURCE@ 1 ;;
      sinkvol:*) pactl set-sink-volume @DEFAULT_SINK@ "${line#sinkvol:}" ;;
      sourcevol:*) pactl set-source-volume @DEFAULT_SOURCE@ "${line#sourcevol:}" ;;
      esac
    done <"$STATE_FILE"
  fi
  ;;
esac
