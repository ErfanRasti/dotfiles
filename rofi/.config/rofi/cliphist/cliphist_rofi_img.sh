#!/usr/bin/env bash
# cliphist helper: exact-match select + lossless copy (preserves trailing newlines).
# - If an argument ($1) is given: find its exact entry in `cliphist list`, decode, and copy.
# - If CLIPHIST_PASTE=1: also mirror the exact bytes to /tmp/cliphist-current.
# - Otherwise (no arg): prep preview list; clean state; render icons for image entries.

tmp_dir="/tmp/cliphist"
current_clipboard="/tmp/cliphist-current"
rm -rf "$tmp_dir"

# If a search string is provided, resolve it to an exact cliphist entry and copy it.
if [[ -n "$1" ]]; then
  # Exact-match the content portion (after the leading "<id><space>") to $1, then capture its ID.
  id=$(cliphist list | awk -v s="$1" '{
    content=$0
    sub(/^[0-9]+[[:space:]]+/,"",content)
    if (content==s) { print $1; exit }
  }')

  # If a valid ID was found, copy losslessly; in paste mode, also write to current_clipboard.
  if [[ -n "$id" ]]; then
    if [[ "${CLIPHIST_PASTE-}" = "1" ]]; then
      cliphist decode "$id" | tee >(wl-copy) >"$current_clipboard"
    else
      cliphist decode "$id" | wl-copy
    fi
  fi
  exit
else
  # No argument: we’re in “listing/preview” mode.
  # If a previous paste-session file exists, remove it to avoid stale content.
  if [[ -f "$current_clipboard" ]]; then
    rm "$current_clipboard"
  fi
fi

mkdir -p "$tmp_dir"

# Build a gawk program that:
# - Skips HTML entries,
# - For binary image items, decodes them to temp files and annotates list rows with icon paths,
# - Passes through other rows unchanged.
read -r -d '' prog <<'EOF'
/^[0-9]+\s<meta http-equiv=/ { next }
match($0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/, grp) {
    system("cliphist decode " grp[1] " >" "/tmp/cliphist/" grp[1] "." grp[3])
    print $0 "\0icon\x1f" "/tmp/cliphist/" grp[1] "." grp[3]
    next
}
1
EOF

# If in paste mode, strip the leading ID column (e.g., for menus that only need content).
if [[ "${CLIPHIST_PASTE-}" = "1" ]]; then
  cliphist list | gawk "$prog" | cut -f2-
else
  # Otherwise, show the full annotated list for selection UIs that expect the ID column.
  cliphist list | gawk "$prog"
fi
