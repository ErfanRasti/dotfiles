#!/usr/bin/env bash
# Reload every kitty (SIGUSR1) so it re-reads themes/matugen.conf.
conf="$(readlink -f "${XDG_CONFIG_HOME:-$HOME/.config}/kitty/kitty.conf")"

# `kitty +kitten themes` appends a block including a frozen current-theme.conf
# after the matugen include, pinning kitty to one theme. Remove it.
sed -i '/^# BEGIN_KITTY_THEME/,/^# END_KITTY_THEME/d' "$conf"

# On NixOS the process is named ".kitty-wrapped".
pkill -USR1 -x 'kitty|\.kitty-wrapped'
exit 0
