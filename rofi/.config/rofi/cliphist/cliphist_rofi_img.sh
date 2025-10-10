#!/usr/bin/env bash
# cliphist helper: exact-match select + lossless copy (preserves trailing newlines).
# - If an argument ($1) is given: find its exact entry in `cliphist list`, and copy.

tmp_dir="/tmp/cliphist"
rm -rf "$tmp_dir"

# If a search string is provided, resolve it to an exact cliphist entry and copy it.
if [[ -n "$1" ]]; then
  # Decode the entry and copy it
  cliphist decode "$1" | wl-copy
  exit
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

# Show the full annotated list for selection
cliphist list | gawk "$prog"
