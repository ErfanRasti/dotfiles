#!/usr/bin/env bash

## Define variables
style="~/.config/rofi/powermenu/style.rasi"

# CMDs
lastlogin="$(last $USER | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7)"
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Options
hibernate='󰒲'
shutdown=''
reboot='󰜉'
lock=''
suspend='󰤄'
logout='󰍃'
yes=''
no=''

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p " $USER@$host" \
    -mesg $'󰍂 Last Login: '"$lastlogin"$'\n Uptime: '"$uptime" \
    -theme ${style}
}

# Confirmation CMD
confirm_cmd() {
  rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
    -theme-str 'mainbox {children: [ "message", "listview" ];}' \
    -theme-str 'listview {columns: 2; lines: 1;}' \
    -theme-str 'element-text {horizontal-align: 0.5;}' \
    -theme-str 'textbox {horizontal-align: 0.5;}' \
    -dmenu \
    -p 'Confirmation' \
    -mesg 'Are you Sure?' \
    -theme ${style}
}

# Ask for confirmation
confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$lock\n$suspend\n$logout\n$hibernate\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "$yes" ]]; then
    if [[ $1 == '--shutdown' ]]; then
      systemctl poweroff
    elif [[ $1 == '--reboot' ]]; then
      systemctl reboot
    elif [[ $1 == '--hibernate' ]]; then
      systemctl hibernate
    elif [[ $1 == '--suspend' ]]; then
      amixer set Master mute
      systemctl suspend
    elif [[ $1 == '--logout' ]]; then
      confirm_run 'kill -9 -1'
    fi
  else
    exit 0
  fi
}

# If called with arguments, skip menu
if [[ -n "$1" ]]; then
  case "$1" in
  shutdown)
    run_cmd --shutdown
    exit 0
    ;;
  reboot)
    run_cmd --reboot
    exit 0
    ;;
  hibernate)
    run_cmd --hibernate
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
  lock)
    hyprlock
    exit 0
    ;;
  esac
fi

# Actions
chosen="$(run_rofi)"
case ${chosen} in
$shutdown)
  run_cmd --shutdown
  ;;
$reboot)
  run_cmd --reboot
  ;;
$hibernate)
  run_cmd --hibernate
  ;;
$lock)
  hyprlock
  ;;
$suspend)
  run_cmd --suspend
  ;;
$logout)
  run_cmd --logout
  ;;
esac
