#!/usr/bin/env bash
# Keep wifi, bluetooth, speaker/mic mute and volume the same across suspend, re-login and reboot.
#   watch    at login: restore the saved state, then save it every 2s when it changes
#   save     before suspend: save and pause the watcher until the next restore
#   restore  after resume: put the saved state back and unpause the watcher

STATE_FILE="$HOME/.cache/devices.state"
HOLD_FILE="$XDG_RUNTIME_DIR/devices.state.hold"

# Run "$@" until it succeeds, for at most $1 seconds
wait_for() {
  local tries=$(($1 * 2))
  shift
  until "$@" >/dev/null 2>&1; do
    ((--tries > 0)) || return 1
    sleep 0.5
  done
}

bt_adapter() { busctl tree org.bluez 2>/dev/null | grep -om1 '/org/bluez/hci[0-9]*'; }

# "key:value", or the saved value when the device can't be read right now
field() { echo "$1:${2:-$(sed -n "s/^$1://p" "$STATE_FILE" 2>/dev/null)}"; }

onoff() {
  case "$1" in
  enabled | "b true" | "Mute: no") echo on ;;
  disabled | "b false" | "Mute: yes") echo off ;;
  esac
}

volume() { pactl "get-$1-volume" "@DEFAULT_${1^^}@" 2>/dev/null | grep -o '[0-9]*%' | head -n1; }

save_state() {
  # Services power devices off while the system goes down; don't record that
  [[ $(systemctl is-system-running) == stopping ]] && return
  local adapter new
  adapter=$(bt_adapter)
  new=$(
    field network "$(onoff "$(nmcli radio wifi 2>/dev/null)")"
    field bluetooth "$(onoff "$([[ -n $adapter ]] && busctl get-property org.bluez "$adapter" org.bluez.Adapter1 Powered 2>/dev/null)")"
    field sink "$(onoff "$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)")"
    field source "$(onoff "$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)")"
    field sinkvol "$(volume sink)"
    field sourcevol "$(volume source)"
  )
  [[ $new == "$(cat "$STATE_FILE" 2>/dev/null)" ]] && return
  # Write and rename, so an interrupted write never leaves a broken file
  echo "$new" >"$STATE_FILE.tmp" && mv -f "$STATE_FILE.tmp" "$STATE_FILE"
}

restore_state() {
  if [[ -f $STATE_FILE ]]; then
    # At login these services may still be starting
    wait_for 15 pactl info
    wait_for 15 nmcli general status
    grep -qx bluetooth:on "$STATE_FILE" && rfkill unblock bluetooth
    wait_for 15 bt_adapter

    while read -r line; do
      case "$line" in
      network:on) rfkill unblock wifi && nmcli radio wifi on ;;
      network:off) nmcli radio wifi off ;;
      bluetooth:on) bluetoothctl power on ;;
      bluetooth:off) bluetoothctl power off ;;
      sink:on) pactl set-sink-mute @DEFAULT_SINK@ 0 ;;
      sink:off) pactl set-sink-mute @DEFAULT_SINK@ 1 ;;
      source:on) pactl set-source-mute @DEFAULT_SOURCE@ 0 ;;
      source:off) pactl set-source-mute @DEFAULT_SOURCE@ 1 ;;
      sinkvol:?*) pactl set-sink-volume @DEFAULT_SINK@ "${line#*:}" ;;
      sourcevol:?*) pactl set-source-volume @DEFAULT_SOURCE@ "${line#*:}" ;;
      esac
    done <"$STATE_FILE" >/dev/null
  fi
  rm -f "$HOLD_FILE"
}

case "$1" in
watch)
  # Replace a watcher left over from an earlier session
  PID_FILE="$XDG_RUNTIME_DIR/devices.state.pid"
  kill "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
  echo $$ >"$PID_FILE"
  restore_state
  while true; do
    [[ -e $HOLD_FILE ]] || save_state
    sleep 2
  done
  ;;
save)
  save_state
  touch "$HOLD_FILE"
  ;;
restore) restore_state ;;
esac
