#!/usr/bin/env bash
# Noctalia's [shell.screenshot] pipe_command. Noctalia's own "Screenshot saved"
# toast has no buttons and can't be turned off on its own, so settings.toml sets
# save_to_file = false and this script saves the capture and shows its own toast
# with "Open" and "Show in Folder" buttons instead.
#
# Noctalia passes the PNG on stdin and exports NOCTALIA_SCREENSHOT_PATH, the file
# it would have saved to (directory + filename_pattern + format extension). With
# the region overlay's explicit "save" key Noctalia still writes the file itself
# (and shows its plain toast too), so an existing file is left alone.

path=$NOCTALIA_SCREENSHOT_PATH
if [ -z "$path" ]; then
	cat >/dev/null
	exit 1
fi

if [ -s "$path" ]; then
	cat >/dev/null
else
	mkdir -p "${path%/*}"
	if ! cat >"$path" || [ ! -s "$path" ]; then
		rm -f "$path"
		notify-send -u critical -a Noctalia "Screenshot failed" "Could not write $path"
		exit 1
	fi
fi

uri() { # file:// URI with everything but unreserved characters and / escaped
	local s=$1 out="" c i
	for ((i = 0; i < ${#s}; i++)); do
		c=${s:i:1}
		case $c in
		[a-zA-Z0-9._~/-]) out+=$c ;;
		*) out+=$(printf '%%%02X' "'$c") ;;
		esac
	done
	printf 'file://%s' "$out"
}

# Let Noctalia's pipe thread finish right away; wait for the click in the background.
(
	action=$(notify-send -a Screenshot -i "$path" -h "string:image-path:$path" \
		--expire-time=8000 \
		--action=default=Open \
		--action=open=Open \
		--action=folder="Show in Folder" \
		"Screenshot saved" "${path/#$HOME/\~}")
	case $action in
	default | open)
		setsid -f xdg-open "$path" >/dev/null 2>&1
		;;
	folder)
		# FileManager1 opens the folder with the file selected (Nautilus, Dolphin, ...).
		gdbus call --session --dest org.freedesktop.FileManager1 \
			--object-path /org/freedesktop/FileManager1 \
			--method org.freedesktop.FileManager1.ShowItems "['$(uri "$path")']" "" >/dev/null 2>&1 ||
			setsid -f nautilus --select "$path" >/dev/null 2>&1
		;;
	esac
) </dev/null >/dev/null 2>&1 &
disown
