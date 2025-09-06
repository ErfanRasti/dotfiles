#!/usr/bin/env bash

style="~/.config/rofi/cliphist/style.rasi"

case $1 in
d)
  if [ ! -z "$2" ]; then
    echo "$2" | cliphist delete
  fi
  ~/.config/rofi/cliphist/cliphist_rofi_img.sh
  # cliphist list
  ;;

w)
  if [ -z "$2" ]; then
    echo -e "Clear\nCancel"
  else

    if [ "$2" == "Clear" ]; then
      cliphist wipe
    fi
  fi
  ;;

*)
  rofi -config $style -show clipboard
  ;;
esac
