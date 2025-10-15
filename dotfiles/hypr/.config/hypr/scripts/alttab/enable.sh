#!/usr/bin/env bash
hyprctl -q --batch "keyword animations:enabled false ; dispatch exec footclient -a alttab ~/.config/hypr/scripts/alttab/alttab.sh $1 ; keyword unbind ALT, TAB ; keyword unbind ALT SHIFT, TAB ; dispatch submap alttab"
