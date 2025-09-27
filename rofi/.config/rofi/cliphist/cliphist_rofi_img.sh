#!/usr/bin/env bash

tmp_dir="/tmp/cliphist"
current_clipboard="/tmp/cliphist-current"
rm -rf "$tmp_dir"

if [[ -n "$1" ]]; then
  # Decode input
  id=$(cliphist list | grep -F "$1" | awk '{print $1; exit}')
  decoded=$(cliphist decode "$id")

  # Copy to clipboard
  wl-copy <<<"$decoded"

  # If on paste mode write the clipboard to the current_clipboard file
  if [[ "${CLIPHIST_PASTE-}" = "1" ]]; then
    echo -n "$decoded" >"$current_clipboard"
  fi
  exit
else
  if [[ -f "/tmp/cliphist-current" ]]; then
    rm "$current_clipboard"
  fi
fi

mkdir -p "$tmp_dir"

read -r -d '' prog <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }
match(\$0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/, grp) {
    system("echo " grp[1] "\\\\\t | cliphist decode >$tmp_dir/"grp[1]"."grp[3])
    print \$0"\0icon\x1f$tmp_dir/"grp[1]"."grp[3]
    next
}
1
EOF
if [[ "${CLIPHIST_PASTE-}" = "1" ]]; then

  cliphist list | gawk "$prog" | cut -f2-
else
  cliphist list | gawk "$prog"
fi
