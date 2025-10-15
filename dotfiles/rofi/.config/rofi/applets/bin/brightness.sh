#!/usr/bin/env bash

# Import Current Theme
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/../shared/theme.sh"
theme="$type/$style"

# Brightness Info
backlight="$(brightnessctl -m | cut -d',' -f4 | tr -d '%')"
card="$(brightnessctl -m | cut -d',' -f2 | cut -d'/' -f3)"

if [[ $backlight -ge 0 ]] && [[ $backlight -le 29 ]]; then
  level="Low"
elif [[ $backlight -ge 30 ]] && [[ $backlight -le 49 ]]; then
  level="Optimal"
elif [[ $backlight -ge 50 ]] && [[ $backlight -le 69 ]]; then
  level="High"
elif [[ $backlight -ge 70 ]] && [[ $backlight -le 100 ]]; then
  level="Peak"
fi

# Theme Elements
prompt="${backlight}%"
mesg="Device: ${card}, Level: $level"

list_col='4'
list_row='1'
win_width='550px'

# Options
option_1="󱩎"
option_2="󱠂"
option_3="󰛨"
option_4="󱧣"

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme "${theme}"
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    brightnessctl set 5%-
  elif [[ "$1" == '--opt2' ]]; then
    brightnessctl set 25%
  elif [[ "$1" == '--opt3' ]]; then
    brightnessctl set 5%+
  elif [[ "$1" == '--opt4' ]]; then
    better-control --display
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
esac
