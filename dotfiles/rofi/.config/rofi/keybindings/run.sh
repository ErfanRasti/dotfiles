#!/usr/bin/env bash
set -euo pipefail

# --- config ---------------------------------------------------------------

FILE="${HOME}/.config/hypr/config/keybindings.conf"
FILE2="${HOME}/.config/hypr/config/hyprscrolling.conf"
FILE3="${HOME}/.config/hypr/config/hy3.conf"
FILE4="${HOME}/.config/hypr/config/noctalia.conf"
FILE5="${HOME}/.config/hypr/config/dms.conf"

# Nerd Font modifier glyphs (can override via env)
ALT_ICON="${ALT_ICON:-󰘵}"
CTRL_ICON="${CTRL_ICON:-󰘴}"
SUPER_ICON="${SUPER_ICON:-󰘳}"
SHIFT_ICON="${SHIFT_ICON:-⇧}" # Unicode, widely present in Nerd Fonts
# Rofi theme paths
STYLE="${STYLE:-${HOME}/.config/rofi/keybindings/style.rasi}"
STYLE_OVERVIEW="${STYLE_OVERVIEW:-${HOME}/.config/rofi/keybindings/style-overview.rasi}"

ROFI_CMD=${ROFI_CMD:-rofi}
ROFI_PROMPT=${ROFI_PROMPT:-Keybindings}
SEP=$'\x1f' # Unit Separator makes multi-line dmenu entries robust

# --- arg parsing (only -o/--overview for now) ------------------------------
OVERVIEW=0
SHOW_HELP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
  -o | --overview)
    OVERVIEW=1
    shift
    ;;
  -h | --help)
    SHOW_HELP=1
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 2
    ;;
  esac
done

if [[ $SHOW_HELP -eq 1 ]]; then
  cat <<EOF
Usage: $(basename "$0") [-o|--overview]

Options:
  -o, --overview   Use the overview style theme (style-overview.rasi)
  -h, --help       Show this help and exit
Environment overrides:
  STYLE=~/.config/rofi/keybindings/style.rasi
  STYLE_OVERVIEW=~/.config/rofi/keybindings/style-overview.rasi
EOF
  exit 0
fi

# --- checks ---------------------------------------------------------------

if ! command -v "$ROFI_CMD" >/dev/null 2>&1; then
  echo "Error: rofi not found. Please install rofi." >&2
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "Error: keybindings file not found at: $FILE" >&2
  exit 1
fi

if [[ ! -f "$FILE2" ]]; then
  echo "Error: keybindings file not found at: $FILE2" >&2
  exit 1
fi

if [[ ! -f "$FILE3" ]]; then
  echo "Error: keybindings file not found at: $FILE3" >&2
  exit 1
fi

if [[ ! -f "$FILE4" ]]; then
  echo "Error: keybindings file not found at: $FILE4" >&2
  exit 1
fi

if [[ ! -f "$FILE5" ]]; then
  echo "Error: keybindings file not found at: $FILE5" >&2
  exit 1
fi

# Pick the active theme based on the flag
if [[ $OVERVIEW -eq 1 ]]; then
  ACTIVE_THEME="$STYLE_OVERVIEW"
else
  ACTIVE_THEME="$STYLE"
fi

if [[ ! -f "$ACTIVE_THEME" ]]; then
  echo "Warning: style file not found at: $ACTIVE_THEME (continuing with rofi defaults)" >&2
fi

# --- builder --------------------------------------------------------------
# Keep only lines starting with "bind*" (bind, bindx, bindxy, ...) that also
# have a trailing "# comment".
# Produce two-line entries separated by $SEP:
#   line 1: icons + key (e.g., "󰘳 ⇧ P" or "󰘳 󰕾")
#   line 2: comment (e.g., "  Toggle pseudo window")

awk \
  -v alt="$ALT_ICON" -v ctrl="$CTRL_ICON" -v super="$SUPER_ICON" -v shift="$SHIFT_ICON" \
  -v sep="$SEP" '
  BEGIN {
    IGNORECASE = 1

    # Map many common key tokens to Nerd Font/Unicode glyphs
    # Arrows
    keymap["UP"] = ""; keymap["DOWN"] = ""; keymap["LEFT"] = ""; keymap["RIGHT"] = "";

    # Navigation / editing
    keymap["RETURN"] = "󰌑"; keymap["ENTER"] = "󰌑";
    keymap["ESC"] = "󱊷"; keymap["ESCAPE"] = "󱊷";
    keymap["TAB"] = "⇥"; keymap["BACKSPACE"] = "󰁮"; keymap["DELETE"] = "󰹾";
    keymap["SPACE"] = "␣"; keymap["HOME"] = "⤒"; keymap["END"] = "⤓";
    keymap["PAGEUP"] = "⇞"; keymap["PAGEDOWN"] = "⇟"; keymap["INSERT"] = "⌲";
    keymap["PRINT"] = "󰹑";
    keymap["CAPS"] = "󰘲"; keymap["CAPS_LOCK"] = "󰘲";

    # Punctuation often used as keys
    keymap[","] = ","; keymap["."] = "."; keymap[";"] = ";"; keymap["/"] = "/";
    keymap["-"] = "-"; keymap["="] = "="; keymap["["] = "["; keymap["]"] = "]";
    keymap["BACKSLASH"] = "\\";

    # XF86 media / brightness keys
    keymap["XF86AUDIOLOWERVOLUME"] = "󰕿";
    keymap["XF86AUDIORAISEVOLUME"] = "󰕾";
    keymap["XF86AUDIOMUTE"]        = "󰖁";
    keymap["XF86AUDIOMICMUTE"]     = "";
    keymap["XF86AUDIOPLAY"]        = "󰐊";
    keymap["XF86AUDIOSTOP"]        = "󰓛";
    keymap["XF86AUDIOPAUSE"]       = "󰏤";
    keymap["XF86AUDIOPREV"]        = "󰒮";
    keymap["XF86AUDIONEXT"]        = "󰒭";
    keymap["XF86MONBRIGHTNESSUP"]   = "󰃠";
    keymap["XF86MONBRIGHTNESSDOWN"] = "󰃞";
    keymap["XF86POWEROFF"] = "⏻";
    keymap["XF86CALCULATOR"] = "";

    # Function keys
    keymap["F1"] = "󱊫";
    keymap["F2"] = "󱊬";
    keymap["F3"] = "󱊭";
    keymap["F4"] = "󱊮";
    keymap["F5"] = "󱊯";
    keymap["F6"] = "󱊰";
    keymap["F7"] = "󱊱";
    keymap["F8"] = "󱊲";
    keymap["F9"] = "󱊳";
    keymap["F10"] = "󱊴";
    keymap["F11"] = "󱊵";
    keymap["F12"] = "󱊶";

    # Mouse buttons often used in Hyprland binds
    keymap["MOUSE:272"] = "󰍽 LMB";
    keymap["MOUSE:273"] = "󰍽 RMB";
    keymap["MOUSE:274"] = "󰍽 MMB";
    keymap["MOUSE_UP"] = "󱕑";
    keymap["MOUSE_DOWN"] = "󱕐";

    # Other keys
    keymap["GRAVE"] = "`";
    keymap["EQUAL"] = "";
    keymap["MINUS"] = "";

    # Common symbolic modifiers to glyphs (used if they appear within a key token)
    modglyph["SUPER"] = super;
    modglyph["ALT"]   = alt;
    modglyph["CTRL"]  = ctrl;
    modglyph["CONTROL"] = ctrl;
    modglyph["SHIFT"] = shift;
  }

  # Helper: trim
  function trim(s){ sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }

  # Helper: prettify a single key token into a glyph (best-effort)
  function pretty_key(k,   u, base, g) {
    u = toupper(k)
    # Exact map first
    if (u in keymap) return keymap[u]

    # Function keys like F1..F24 — keep as-is
    if (u ~ /^F[0-9]{1,2}$/) return u

    # Mouse generic pattern
    if (u ~ /^MOUSE:[0-9]+$/) return "󰍽 " u

    # If token includes textual modifiers (rare), swap them for glyphs
    for (base in modglyph) {
      if (u ~ base) {
        g = k
        gsub(base, modglyph[base], g)
        return g
      }
    }

    # Single printable char: keep uppercase
    if (length(k) == 1) return toupper(k)

    # Fallback: return original token
    return k
  }

  # Match lines starting with "bind" + optional letters, then "=", and containing a comment.
  /^[[:space:]]*bind[[:alpha:]]*[[:space:]]*=/ && /#/ {
    # comment
    cpos = index($0, "#"); if (cpos == 0) next
    comment = substr($0, cpos + 1); comment = trim(comment)

    # left of comment
    pre = substr($0, 1, cpos - 1)
    sub(/^[[:space:]]*bind[[:alpha:]]*[[:space:]]*=[[:space:]]*/, "", pre)

    # split fields by comma
    n = split(pre, f, /[[:space:]]*,[[:space:]]*/); if (n < 2) next

    mods = f[1]; key = f[2]
    gsub(/[[:space:]]+/, "", key)

    # Build icon string from modifiers (order: super, ctrl, alt, shift)
    low = tolower(mods)
    icons = ""
    if (low ~ /\$mainmod/ || low ~ /(^|[^a-z])super([^a-z]|$)/) { icons = (icons ? icons " " : "") super }
    if (low ~ /(^|[^a-z])(ctrl|control)([^a-z]|$)/)              { icons = (icons ? icons " " : "") ctrl  }
    if (low ~ /(^|[^a-z])alt([^a-z]|$)/)                         { icons = (icons ? icons " " : "") alt   }
    if (low ~ /(^|[^a-z])shift([^a-z]|$)/)                       { icons = (icons ? icons " " : "") shift }

    # Beautify the key token
    pk = pretty_key(key)

    # If no modifiers detected, just show the key
    head = (icons == "" ? pk : icons " " pk)

    # Two-line entry -> separated by SEP for rofi
    printf "%s\n  %s%s", head, comment, sep
  }
' <(cat "$FILE" "$FILE2" "$FILE3" "$FILE4" "$FILE5") | {

  # Build rofi command with your theme only (no radius overrides)
  rofi_args=(
    -dmenu
    -sep "$SEP"
    -eh 2
    -markup-rows
    -p "$ROFI_PROMPT"
    -i
  )

  if [[ -f "$ACTIVE_THEME" ]]; then
    rofi_args+=(-theme "$ACTIVE_THEME")
  fi

  exec "$ROFI_CMD" "${rofi_args[@]}"
}
