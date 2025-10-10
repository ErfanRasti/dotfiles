#!/usr/bin/env bash

style="$HOME/.config/rofi/cliphist/style.rasi"

systemctl --user set-environment CLIPHIST_PASTE=0

case $1 in
c)
  systemctl --user set-environment CLIPHIST_PASTE=1

  ~/.config/rofi/cliphist/cliphist_rofi_img.sh "$2"
  ;;
d)
  if [ ! -z "$2" ]; then
    echo "$2" | cliphist delete
  fi
  ~/.config/rofi/cliphist/cliphist_rofi_img.sh
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
  rofi -config "$style" -show " clipboard"

  if [[ $(systemctl --user show-environment | grep '^CLIPHIST_PASTE=' | cut -d= -f2) == 1 ]]; then
    ydotool key 29:1 42:1 47:1 47:0 42:0 29:0
  fi
  ;;
esac
