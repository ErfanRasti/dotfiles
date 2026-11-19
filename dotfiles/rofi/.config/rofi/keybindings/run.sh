#!/usr/bin/env bash
# Keybindings menu (Hyprland / niri / umbriel; rows from binds.py). -o: overview grid, no search.
# Pressing the bind again closes it (any open rofi, like the toggle_rofi_* scripts).
pkill -x rofi && exit
dir=${0%/*}
style=$dir/style.rasi
[[ ${1:-} == -o ]] && style=$dir/style-overview.rasi
"$dir/binds.py" | exec rofi -dmenu -sep $'\x1f' -eh 2 -markup-rows -i -p Keybindings -theme "$style"
