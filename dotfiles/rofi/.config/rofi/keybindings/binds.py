#!/usr/bin/env python3
"""Rofi rows (-sep '\\x1f' -eh 2 -markup-rows) of the running compositor's keybinds, for run.sh.

  Hyprland  `hyprctl binds -j`: binds with a description.
  niri      ~/.config/niri/config.kdl + includes: binds with a hotkey-overlay-title.
  umbriel   ~/.config/umbriel/config.toml + includes, [keybinds]: the bind's trailing
            "# comment", else a description built from `umbriel msg --help` or the command.
COMPOSITOR=hyprland|niri|umbriel overrides the detection.
"""

import os
import re
import shlex
import subprocess
import sys
from functools import cache
from html import escape
from pathlib import Path

SUPER, CTRL, ALT, SHIFT = "\U000f0633", "\U000f0634", "\U000f0635", "⇧"
ORDER = (SUPER, CTRL, ALT, SHIFT)
MODS = {"mod": SUPER, "super": SUPER, "win": SUPER, "meta": SUPER,
        "ctrl": CTRL, "control": CTRL, "alt": ALT, "shift": SHIFT}
# Keys are lowercased with "_" and "scroll" removed (Page_Up -> pageup, WheelScrollUp -> wheelup).
KEYS = {
    "up": "", "down": "", "left": "", "right": "",
    "return": "\U000f0311", "enter": "\U000f0311", "esc": "\U000f12b7", "escape": "\U000f12b7",
    "tab": "⇥", "backspace": "\U000f006e", "delete": "\U000f0e7e", "space": "␣", "home": "⤒",
    "end": "⤓", "pageup": "⇞", "prior": "⇞", "pagedown": "⇟", "next": "⇟", "insert": "⌲",
    "print": "\U000f0e51", "caps": "\U000f0632", "capslock": "\U000f0632",
    "backslash": "\\", "slash": "/", "period": ".", "comma": ",", "semicolon": ";",
    "apostrophe": "'", "bracketleft": "[", "bracketright": "]", "grave": "`",
    "equal": "", "minus": "",
    "xf86audiolowervolume": "\U000f057f", "xf86audioraisevolume": "\U000f057e",
    "xf86audiomute": "\U000f0581", "xf86audiomicmute": "", "xf86audioplay": "\U000f040a",
    "xf86audiostop": "\U000f04db", "xf86audiopause": "\U000f03e4", "xf86audioprev": "\U000f04ae",
    "xf86audionext": "\U000f04ad", "xf86monbrightnessup": "\U000f00e0",
    "xf86monbrightnessdown": "\U000f00de", "xf86poweroff": "⏻", "xf86calculator": "",
    "mouse:272": "\U000f037d LMB", "mouse:273": "\U000f037d RMB", "mouse:274": "\U000f037d MMB",
    "mouseup": "\U000f1551", "wheelup": "\U000f1551", "mousedown": "\U000f1550",
    "wheeldown": "\U000f1550", "wheelleft": "\U000f037d ←", "wheelright": "\U000f037d →",
    **{f"f{i}": chr(0xF12AA + i) for i in range(1, 13)},
}
CONF = Path.home() / ".config"
rows = []


def row(mods, key, desc):
    desc = " ".join(desc.split())
    if not desc:
        return
    glyph = KEYS.get(key.lower().replace("_", "").replace("scroll", "")) or (key.upper() if len(key) == 1 else key or "(tap)")
    head = " ".join([m for m in ORDER if m in mods] + [glyph])
    rows.append(f"{head}\n  {escape(desc, quote=False)}")


def chord_row(chord, desc):
    parts = chord.split("+")
    row({MODS[p.lower()] for p in parts if p.lower() in MODS},
        next((p for p in parts if p.lower() not in MODS), ""), desc[:1].upper() + desc[1:])


def hyprland():
    import json
    for b in json.loads(subprocess.run(["hyprctl", "binds", "-j"], capture_output=True, text=True).stdout):
        if b.get("description") and b.get("key") and not b.get("submap"):
            m = b["modmask"]
            row({g for bit, g in ((64, SUPER), (4, CTRL), (8, ALT), (1, SHIFT)) if m & bit}, b["key"], b["description"])


def niri(path=CONF / "niri/config.kdl", seen=set()):
    if path in seen or not path.exists():
        return
    seen.add(path)
    for line in path.read_text().splitlines():
        if m := re.match(r'^\s*include\b.*?"([^"]+)"', line):
            niri((path.parent / os.path.expanduser(m[1])).resolve(), seen)
        elif m := re.match(r'^\s*([^\s/{"]+)\s[^{]*?hotkey-overlay-title="((?:[^"\\]|\\.)*)"', line):
            chord_row(m[1], m[2].replace('\\"', '"'))


@cache
def action_help():
    """umbriel action -> description, from `umbriel msg --help`."""
    out = subprocess.run(["umbriel", "msg", "--help"], capture_output=True, text=True).stdout
    return dict(reversed(re.findall(r"(?m)^  ([a-z0-9-]+)(?: [^ ].*?)?\s{2,}(\S.*)$", out)))


def pretty(word):
    return word.replace("plugin:", "").replace("-", " ").replace("_", " ")


def describe(action):
    if not action.startswith("spawn "):
        name, _, args = action.partition(" ")
        desc = action_help().get(name)
        if not desc:
            return pretty(action)
        if not args:
            return desc
        return desc.replace("the selected workspace", f"workspace {args}") if "the selected workspace" in desc else f"{desc} ({args})"

    try:
        words = shlex.split(action[6:])
    except ValueError:
        words = action[6:].split()
    while words and (words[0] == "env" or "=" in words[0]):
        words.pop(0)
    if not words:
        return action
    path, args = words[0], words[1:]
    exe = os.path.basename(path)
    plain = [a for a in args if a[0] != "-"]
    arg = plain[0] if plain else ""
    match exe:
        case "set_layout.py":
            if "--scratchpad" in args:
                return "Show / hide the scratchpad"
            scope = " (all workspaces)" if "--all" in args else ""
            return f"Toggle the previous layout{scope}" if plain[-1] == "toggle" else f"Layout: {plain[-1]}{scope}"
        case "toggle_app.py" if arg:
            return "Toggle " + arg.split(".")[-1]
        case "focus.sh" if arg:
            return "Focus " + arg
        case "move_window.sh" if arg:
            return "Move the window " + arg
        case "noctalia" if arg == "msg":
            rest = [pretty(a) for a in plain[1:]]
            return "Noctalia: " + " ".join(rest[rest[0] == "panel toggle":])
        case "kitty":
            for flag in ("--title", "--app-id", "--class"):
                if flag in args[:-1]:
                    return "Terminal: " + args[args.index(flag) + 1]
            return "Open the terminal"
    stem = re.sub(r"\.(sh|py)$", "", exe)
    if "/rofi/" in path:
        return "Rofi: " + pretty((os.path.basename(os.path.dirname(path)) if exe == "run.sh" else stem).replace("toggle_", "").replace("rofi_", ""))
    if "/" in path:
        return " ".join([pretty(stem)] + plain)
    return "Run " + " ".join(words)


def umbriel():
    import tomllib
    root = CONF / "umbriel/config.toml"
    inc = tomllib.loads(root.read_text()).get("include", {})
    files = [root.parent / f for f in inc.get("files", []) + inc.get("optional", {}).get("files", [])]
    binds, comments = {}, {}
    for f in [root] + files:
        try:
            text = f.read_text()
            binds.update(tomllib.loads(text).get("keybinds", {}))
        except FileNotFoundError:
            continue
        except (OSError, tomllib.TOMLDecodeError) as e:
            print(f"binds.py: skipping {f}: {e}", file=sys.stderr)
            continue
        table = ""
        for line in text.splitlines():
            s = line.strip()
            if s[:1] == "[":
                table = s.strip("[] ")
            elif table == "keybinds" and "#" in s and (m := re.match(r'^"((?:[^"\\]|\\.)*)"\s*=\s*(.*)$|^([\w+-]+)\s*=\s*(.*)$', s)):
                rest = m[2] if m[1] is not None else m[4]
                for i in (i for i, ch in enumerate(rest) if ch == "#"):  # first '#' outside the value
                    try:
                        tomllib.loads("x = " + rest[:i])
                    except tomllib.TOMLDecodeError:
                        continue
                    comments[m[1] if m[1] is not None else m[3]] = rest[i + 1:].strip()
                    break

    for chord, val in binds.items():
        if isinstance(val, dict):
            if val.get("submap"):
                continue
            val = val.get("action")
        if val and isinstance(val, str):
            comment = comments.get(chord, "")
            # comments that are only a niri action name ("maximize-column") describe little
            chord_row(chord, describe(val) if not comment or re.fullmatch(r"[a-z0-9-]+", comment) else comment)


env = os.environ
name = env.get("COMPOSITOR") or next(
    (n for v, n in (("HYPRLAND_INSTANCE_SIGNATURE", "hyprland"), ("NIRI_SOCKET", "niri"), ("UMBRIEL_SOCKET", "umbriel")) if v in env),
    env.get("XDG_CURRENT_DESKTOP", "").lower())
source = next((f for n, f in (("hyprland", hyprland), ("niri", niri), ("umbriel", umbriel)) if n in name), None)
if not source:
    sys.exit(f"binds.py: unsupported compositor '{name}' (set COMPOSITOR=hyprland|niri|umbriel)")
source()
sys.stdout.write("\x1f".join(rows))
