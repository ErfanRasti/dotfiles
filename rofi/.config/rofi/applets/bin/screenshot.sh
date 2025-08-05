#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="$type/$style"

# Theme Elements
prompt='Screenshot'
mesg=" DIR: $(xdg-user-dir PICTURES)/Screenshots"

list_col='5'
list_row='1'
win_width='670px'

# Options
option_1=""
option_2=""
option_3=""
option_4=""
option_5=""

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme ${theme}
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3\n$option_4\n$option_5" | rofi_cmd
}

# Screenshot Configuration
time=$(date +%Y-%m-%d-%H-%M-%S)
geometry=$(hyprctl monitors | grep -A 10 "active: yes" | grep at | awk '{print $2,$3}' | tr ' ' 'x')
dir="$(xdg-user-dir PICTURES)/Screenshots"
file="Screenshot_${time}_${geometry}.png"

# Create directory if it doesn't exist
[[ ! -d "$dir" ]] && mkdir -p "$dir"

# Notification function
notify_view() {
  if [[ -e "${dir}/${file}" ]]; then
    notify-send -u low "Screenshot Saved + Copied" "${file}"
    # viewnior "${dir}/${file}" 2>/dev/null &
  else
    notify-send -u critical "Screenshot Failed"
  fi
}

# Screenshot functions
shotnow() {
  hyprshot -m output -o "$dir" -f "$file"
  notify_view
}

shot5() {
  hyprshot -m output -o "$dir" -f "$file" -t 5000
  notify_view
}

shot10() {
  hyprshot -m output -o "$dir" -f "$file" -t 10000
  notify_view
}

shotwin() {
  hyprshot -m window -o "$dir" -f "$file"
  notify_view
}

shotarea() {
  hyprshot -m region -o "$dir" -f "$file"
  notify_view
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    shotnow
  elif [[ "$1" == '--opt2' ]]; then
    shotarea
  elif [[ "$1" == '--opt3' ]]; then
    shotwin
  elif [[ "$1" == '--opt4' ]]; then
    shot5
  elif [[ "$1" == '--opt5' ]]; then
    shot10
  fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
$option_1)
  run_cmd --opt1
  ;;
$option_2)
  run_cmd --opt2
  ;;
$option_3)
  run_cmd --opt3
  ;;
$option_4)
  run_cmd --opt4
  ;;
$option_5)
  run_cmd --opt5
  ;;
esac
