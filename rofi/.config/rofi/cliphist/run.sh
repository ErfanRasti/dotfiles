#!/usr/bin/env bash

style="~/.config/rofi/cliphist/style.rasi"

case $1 in
d)
  cliphist list | rofi -dmenu -replace -config $style | cliphist delete
  ;;

w)
  if [ $(echo -e "Clear\nCancel" | rofi -dmenu -config $style) == "Clear" ]; then
    cliphist wipe
  fi
  ;;

*)
  rofi -modi clipboard:~/.config/rofi/cliphist/cliphist-rofi-img.sh -show clipboard -show-icons -config $style
  ;;
esac
