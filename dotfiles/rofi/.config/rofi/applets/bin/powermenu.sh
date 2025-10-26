#!/usr/bin/env bash

# Import Current Theme
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/../shared/theme.sh"
theme="$type/$style"

# Theme Elements
prompt="$(hostname)"
mesg="Uptime : $(uptime -p | sed -e 's/up //g')"

list_col='6'
list_row='1'

# Options
lock=""
suspend="󰤄"
logout="󰍃"
hibernate="󰒲"
reboot="󰜉"
shutdown=""
yes=''
no=''

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme "${theme}"
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$lock\n$suspend\n$logout\n$hibernate\n$reboot\n$shutdown" | rofi_cmd
}

# Confirmation CMD
confirm_cmd() {
  local action=$1
  local icon=$2

  rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 400px;}' \
    -theme-str 'mainbox {orientation: vertical; children: [ "message", "listview" ];}' \
    -theme-str 'listview {columns: 2; lines: 1;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'textbox {horizontal-align: 0.5;}' \
    -dmenu \
    -p 'Confirmation' \
    -mesg "${icon} Are you sure you want to ${action}?" \
    -theme "${theme}"
}

# Ask for confirmation
confirm_exit() {
  local action=$1
  local icon=""

  case "$action" in
  lock) icon="$lock" ;;
  suspend) icon="$suspend" ;;
  logout) icon="$logout" ;;
  hibernate) icon="$hibernate" ;;
  reboot) icon="$reboot" ;;
  shutdown) icon="$shutdown" ;;
  esac

  echo -e "$yes\n$no" | confirm_cmd "$action" "$icon"
}

# Execute Command
run_cmd() {
  selected="$(confirm_exit "${1#--}")"
  if [[ "$selected" == "$yes" ]]; then
    if [[ "$1" == '--lock' ]]; then
      hyprlock
    elif [[ "$1" == '--suspend' ]]; then
      amixer set Master mute
      systemctl suspend
    elif [[ "$1" == '--logout' ]]; then
      kill -9 -1
    elif [[ "$1" == '--hibernate' ]]; then
      systemctl hibernate
    elif [[ "$1" == '--reboot' ]]; then
      systemctl reboot
    elif [[ "$1" == '--shutdown' ]]; then
      systemctl poweroff
    fi
  else
    exit 0
  fi

}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
"$lock")
  run_cmd --lock
  ;;
"$suspend")
  run_cmd --suspend
  ;;
"$logout")
  run_cmd --logout
  ;;
"$hibernate")
  run_cmd --hibernate
  ;;
"$reboot")
  run_cmd --reboot
  ;;
"$shutdown")
  run_cmd --shutdown
  ;;
esac
