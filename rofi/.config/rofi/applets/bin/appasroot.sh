#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.sh
theme="$type/$style"

# Theme Elements
prompt='Applications as root'
mesg='Select an application to run as root'

list_col='5'
list_row='1'
win_width='670px'

# Options

option_1="󰊠"
option_2=""
option_3=""
option_4=""
option_5=""

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str 'textbox-prompt-colon {str: "";}' \
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

# Execute Command
run_cmd() {
  # Ensure the necessary environment variables are available
  local polkit_cmd="pkexec env PATH=\"$PATH\" \
        DISPLAY=\"$DISPLAY\" \
        XAUTHORITY=\"$XAUTHORITY\" \
        WAYLAND_DISPLAY=\"$WAYLAND_DISPLAY\" \
        HYPRLAND_INSTANCE_SIGNATURE=\"$HYPRLAND_INSTANCE_SIGNATURE\" \
        XDG_CURRENT_DESKTOP=\"$XDG_CURRENT_DESKTOP\""

  case "$1" in
  '--opt1')
    sudo -i /usr/bin/ghostty
    ;;
  '--opt2')
    nautilus admin:///root/
    ;;
  '--opt3')
    ${polkit_cmd} /usr/bin/code
    ;;
  '--opt4')
    ${polkit_cmd} /usr/bin/yazi
    ;;
  '--opt5')
    ${polkit_cmd} /usr/bin/nvim
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
