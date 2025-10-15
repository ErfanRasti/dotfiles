#!/usr/bin/env bash

# Import Current Theme
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/../shared/theme.sh"
theme="$type/$style"

# Theme Elements
prompt='Applications as root'
mesg='Select an application to run as root'

list_col='4'
list_row='1'
win_width='670px'

# Options

option_1="󰊠"
option_2=""
option_3=""
option_4=""

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
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

run_pkexec() {
  pkexec env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" WAYLAND_DISPLAY="$WAYLAND_DISPLAY" "$1"
}

# Execute Command
run_cmd() {
  # Ensure the necessary environment variables are available

  case "$1" in
  '--opt1')

    run_pkexec /usr/bin/ghostty
    ;;
  '--opt2')
    nautilus admin:///root/
    ;;
  '--opt3')
    run_pkexec /usr/bin/nvim
    ;;
  '--opt4')
    run_pkexec /usr/bin/yazi
    ;;
  *)
    echo "Invalid option"
    return 1
    ;;
  esac
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
