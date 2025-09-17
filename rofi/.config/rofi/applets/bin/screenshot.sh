#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.sh
theme="$type/$style"

# Theme Elements
prompt='Screenshot'
printf -v mesg " Save DIR: $(xdg-user-dir PICTURES)/Screenshots"

list_col='4'
list_row='1'
win_width='670px'

# Options
option_1=""
option_2="󰹑"
option_3=""
option_4=""

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme "$theme"
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4" | rofi_cmd
}

# Screenshot Configuration
time=$(date +%Y-%m-%d-%H-%M-%S)
geometry=$(hyprctl monitors | grep -A 10 "active: yes" | grep at | awk '{print $2,$3}' | tr ' ' 'x')
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}_${geometry}.png"

# Create directory if it doesn't exist
[[ ! -d "$dir" ]] && mkdir -p "$dir"

# Screenshot functions
shotnow() {
  pkill rofi
  sleep 0.2
  hyprshot -m output -z -o "$dir" -f "$file"
}

shotwin() {
  pkill rofi
  sleep 0.2
  hyprshot -m window -z -o "$dir" -f "$file"
}

shotarea() {
  pkill rofi
  sleep 0.2
  hyprshot -m region -z -o "$dir" -f "$file"
}

toggle_gpu_screen_recorder() {
  pkill rofi
  sleep 0.2
  # Press Alt+z to show gpu screen recorder
  ydotool key 56:1 44:1 44:0 56:0
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    shotarea
  elif [[ "$1" == '--opt2' ]]; then
    shotnow
  elif [[ "$1" == '--opt3' ]]; then
    shotwin
  elif [[ "$1" == '--opt4' ]]; then
    toggle_gpu_screen_recorder
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
