#!/usr/bin/env bash
# Converts file://$HOME/... or file://~/... lines into absolute GTK3 bookmark entries.

BOOKMARKS_FILE="$HOME/.config/gtk-3.0/bookmarks"
INPUT_FILE="${1:-/dev/stdin}"

mkdir -p "$(dirname "$BOOKMARKS_FILE")"
: >"$BOOKMARKS_FILE" # clear it

while IFS= read -r line; do
  # skip empty lines or comments
  [[ -z "$line" || "$line" =~ ^# ]] && continue

  uri="${line%% *}"                    # part before space
  label="${line#* }"                   # part after space (may be same if no label)
  [[ "$uri" == "$label" ]] && label="" # no label

  # expand $HOME or ~
  expanded="${uri//\$HOME/$HOME}"
  expanded="${expanded//\~/$HOME}"

  # encode spaces
  encoded="${expanded// /%20}"

  # write "file:///..." with optional label
  if [[ -n "$label" ]]; then
    echo "$encoded $label" >>"$BOOKMARKS_FILE"
  else
    echo "$encoded" >>"$BOOKMARKS_FILE"
  fi
done <"$INPUT_FILE"

echo "✅ Updated GTK3 bookmarks at: $BOOKMARKS_FILE"
