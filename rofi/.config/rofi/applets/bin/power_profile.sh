#!/usr/bin/env bash

# Import Current Theme
source "$HOME"/.config/rofi/applets/shared/theme.bash
theme="${type}/${style}"

# Battery Info
charging_status="$(acpi -b | cut -d',' -f1 | cut -d':' -f2 | tr -d ' ')"
current_profile="$(powerprofilesctl get)"
percentage="$(acpi -b | cut -d',' -f2 | tr -d ' ',\%)"
time="$(acpi -b | cut -d',' -f3)"

if [[ -z "$time" ]]; then
  time=' Fully Charged'
fi

# Theme Elements
prompt="$current_profile"
mesg="${charging_status}, ${percentage}%, ${time}"

list_col='3'
list_row='1'
win_width='400px'

# Options
option_1="󰌪"
option_2=""
option_3="󰓅"

ICON_PROFILE="??"
if [[ "$current_profile" == "power-saver" ]]; then
  ICON_PROFILE=$option_1
elif [[ "$current_profile" == "balanced" ]]; then
  ICON_PROFILE=$option_2
elif [[ "$current_profile" == "performance" ]]; then
  ICON_PROFILE=$option_3
fi

# Rofi CMD
rofi_cmd() {
  rofi -theme-str "window {width: $win_width;}" \
    -theme-str "listview {columns: $list_col; lines: $list_row;}" \
    -theme-str "textbox-prompt-colon {str: \"$ICON_PROFILE\";}" \
    -dmenu \
    -p "$prompt" \
    -mesg "$mesg" \
    -markup-rows \
    -theme "${theme}"
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$option_1\n$option_2\n$option_3" | rofi_cmd
}

# Execute Command
run_cmd() {
  if [[ "$1" == '--opt1' ]]; then
    powerprofilesctl set power-saver
    notify-send -u normal -i battery "Power Profile Updated" "New: ${option_1} power-saver\n(Was: $ICON_PROFILE $current_profile)"
  elif [[ "$1" == '--opt2' ]]; then
    powerprofilesctl set balanced
    notify-send -u normal -i battery "Power Profile Updated" "New: ${option_2} balanced\n(Was: $ICON_PROFILE $current_profile)"
  elif [[ "$1" == '--opt3' ]]; then
    powerprofilesctl set performance
    notify-send -u normal -i battery "Power Profile Updated" "New: ${option_3} performance\n(Was: $ICON_PROFILE $current_profile)"
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
esac
