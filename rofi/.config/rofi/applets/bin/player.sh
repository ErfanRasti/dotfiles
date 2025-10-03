#!/usr/bin/env bash

# Import Current Theme
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/../shared/theme.sh"
theme="$type/$style"

# Theme Elements
status="$(playerctl status)"
mesg=$("$HOME"/.config/hypr/scripts/song_detail.sh)

list_col='6'
list_row='1'

# Options
if [[ ${status} == "Playing" ]]; then
  option_1=""
else
  option_1=""
fi
option_2=""
option_3="󰙣"
option_4="󰙡"
option_5="󰒞"
option_6="󰑗"

# Toggle Actions
active=""
urgent=""

# Random
random_status=$(playerctl shuffle)
if [[ ${random_status} == "On" ]]; then
  option_5=""
  active="-a 4"
elif [[ ${random_status} == "Off" ]]; then
  option_5="󰒞"
  urgent="-u 4"
fi

# Repeat
repeat_status=$(playerctl loop)
repeat_next_state="Playlist"
if [[ ${repeat_status} == "Track" ]]; then
  option_6="󰑘"
  [ -n "$active" ] && active+=",5" || active="-a 5"
  repeat_next_state="Playlist"
elif [[ ${repeat_status} == "Playlist" ]]; then
  option_6=""
  repeat_next_state="None"
elif [[ ${repeat_status} == "None" ]]; then
  option_6="󰑗"
  [ -n "$urgent" ] && urgent+=",5" || urgent="-u 5"
  repeat_next_state="Track"
fi

# Rofi CMD
rofi_cmd() {
  # shellcheck disable=SC2086
  rofi -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "$status" \
    -mesg "$mesg" \
    ${active} ${urgent} \
    -markup-rows \
    -theme "${theme}"
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5\n$option_6" | rofi_cmd
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    playerctl play-pause
  elif [[ "$1" == '--opt2' ]]; then
    playerctl stop
  elif [[ "$1" == '--opt3' ]]; then
    playerctl previous
  elif [[ "$1" == '--opt4' ]]; then
    playerctl next
  elif [[ "$1" == '--opt5' ]]; then
    playerctl shuffle "Toggle"
  elif [[ "$1" == '--opt6' ]]; then
    playerctl loop "${repeat_next_state}"
  fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
"$option_1")
  run_cmd --opt1
  ;;
"$option_2")
  run_cmd --opt2
  ;;
"$option_3")
  run_cmd --opt3
  ;;
"$option_4")
  run_cmd --opt4
  ;;
"$option_5")
  run_cmd --opt5
  ;;
"$option_6")
  run_cmd --opt6
  ;;
esac
