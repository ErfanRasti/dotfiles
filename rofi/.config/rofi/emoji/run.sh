#!/usr/bin/env bash

style=~/.config/rofi/emoji/style.rasi

# rofi -modi emoji -show emoji -theme ${style} -emoji-format '{emoji}'
rofimoji --selector-args="-theme $style" --hidden-descriptions
