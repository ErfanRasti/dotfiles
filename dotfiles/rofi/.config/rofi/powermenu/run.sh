#!/usr/bin/env bash

## Define variables
style="$HOME/.config/rofi/powermenu/style.rasi"

# CMDs
lastlogin="$(last "$USER" | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7)"
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Options
lock=''
suspend='󰤄'
logout='󰍃'
hibernate='󰒲'
reboot='󰜉'
shutdown=''
yes=''
no=''

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p " $USER@$host" \
    -mesg $'󰍂 Last Login: '"$lastlogin"$'\n Uptime: '"$uptime" \
    -theme "${style}"
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
    -theme-str 'mainbox {children: [ "message", "listview" ];}' \
    -theme-str 'listview {columns: 2; lines: 1;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'textbox {horizontal-align: 0.5;}' \
    -dmenu \
    -p 'Confirmation' \
    -mesg "${icon} Are you sure you want to ${action}?" \
    -theme "${style}"
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
  if [[ $1 == '--lock' ]]; then
    hyprlock
    return
  fi
  selected="$(confirm_exit "${1#--}")"
  if [[ "$selected" == "$yes" ]]; then
    if [[ $1 == '--suspend' ]]; then
      amixer set Master mute
      systemctl suspend
    elif [[ $1 == '--logout' ]]; then
      kill -9 -1
    elif [[ $1 == '--hibernate' ]]; then
      systemctl hibernate
    elif [[ $1 == '--reboot' ]]; then
      systemctl reboot
    elif [[ $1 == '--shutdown' ]]; then
      systemctl poweroff
    fi
  else
    exit 0
  fi
}

# If called with arguments, skip menu
if [[ -n "$1" ]]; then
  case "$1" in
  lock)
    run_cmd --lock
    exit 0
    ;;
  suspend)
    run_cmd --suspend
    exit 0
    ;;
  logout)
    run_cmd --logout
    exit 0
    ;;
  hibernate)
    run_cmd --hibernate
    exit 0
    ;;
  reboot)
    run_cmd --reboot
    exit 0
    ;;
  shutdown)
    run_cmd --shutdown
    exit 0
    ;;
  esac
fi

# Actions
chosen="$(run_rofi)"
case ${chosen} in
"$shutdown")
  run_cmd --shutdown
  ;;
"$reboot")
  run_cmd --reboot
  ;;
"$hibernate")
  run_cmd --hibernate
  ;;
"$lock")
  run_cmd --lock
  ;;
"$suspend")
  run_cmd --suspend
  ;;
"$logout")
  run_cmd --logout
  ;;
esac
