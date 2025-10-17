#!/usr/bin/env bash
set -uo pipefail

# Run command and capture output exactly as printed
mapfile -t lines < <(hyprctl dispatch hy3:debugnodes)

# Must be exactly two lines
if [[ ${#lines[@]} -ne 2 ]]; then
  exit
fi

line1="${lines[0]}"
line2="${lines[1]}"

# Regexes (POSIX ERE for [[ =~ ]])
# 1) group(0xHEX) [splith] size ratio: 1, ephemeral
re1='^group\(0x[0-9a-fA-F]+\) \[tabs\] size ratio: 1, ephemeral$'

# 2) |-window(0xHEX) [hypr 0xHEX] size ratio: 1
#    allow optional spaces after "|-"
re2='^\|-[[:space:]]*window\(0x[0-9a-fA-F]+\) \[hypr 0x[0-9a-fA-F]+\] size ratio: 1$'

if [[ $line1 =~ $re1 && $line2 =~ $re2 ]]; then
  hyprctl dispatch hy3:changegroup untab
else
  hyprctl dispatch hy3:makegroup tab,toggle,force_ephemeral
fi
