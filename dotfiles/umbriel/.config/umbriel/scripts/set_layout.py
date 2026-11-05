#!/usr/bin/env -S python3 -I -B
"""Switch workspace layouts, persist them, notify, and cascade windows in stacking.

Usage:
  set_layout.py [--all] <scrolling|stacking|dwindle|master|toggle>
  set_layout.py --cascade [ws-id]   re-cascade the focused workspace if it is in stacking
                                    (with ws-id: only if that workspace is still focused)
  set_layout.py --init              create config/workspaces.state.toml from the defaults
  set_layout.py --scratchpad NAME   toggle a scratchpad; when it opens with 2+ windows they are
                                    cascaded, centered on the screen

toggle cycles scrolling -> stacking -> dwindle -> master (Mod+F1..F4 order) from the focused
workspace's layout. --all applies to every workspace: the focused one is cascaded now, the
others are marked pending and cascaded by stacking_watch.py on first visit.

Layouts are written to config (workspaces.state.toml) instead of `workspace-set-layout`,
because a runtime layout override is reset by ANY config reload, and the stacking title bars
(config/titlebar.toml) need one. Layout + title bars are written together -> a single reload.

Everything talks to umbriel's IPC socket directly (scripts/umbriel_ipc.py): no `umbriel`/`jq`
processes per query, no fixed sleeps (it polls the socket until the compositor is ready), and
windows that already have the cascade size are only moved, not focused/resized again.
"""

import fcntl
import os
import re
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
import umbriel_ipc as ipc  # noqa: E402

CFG = os.path.expanduser("~/.config/umbriel/config")
STATE = f"{CFG}/workspaces.state.toml"
DEFAULTS = f"{CFG}/workspaces.defaults.toml"
TITLEBAR = f"{CFG}/titlebar.toml"
RUN = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
PENDING = f"{RUN}/umbriel-cascade-pending"
LOCK = f"{RUN}/umbriel-set-layout.lock"
CYCLE = ["scrolling", "stacking", "dwindle", "master"]

CASCADE_W = 0.60  # window width  as a fraction of the output
CASCADE_H = 0.65  # window height as a fraction of the output
CASCADE_X = 48    # first window offset from the usable area's top-left (logical px)
CASCADE_Y = 56
CASCADE_STEP = 34  # diagonal step between windows (clears the title bar)
SIZE_TOL = 0.02    # accepted size error (fraction of the output)
POS_TOL = 6        # accepted position error (px)

NOTIFY = {
    "scrolling": ("view-paged-symbolic", "Scrollable columns (niri-like)"),
    "stacking": ("window-duplicate-symbolic", "Cascaded windows with title bars (Mod+F2 again to re-arrange)"),
    "dwindle": ("view-grid-symbolic", "Binary-split tiling (Mod+Alt+T flips a split)"),
    "master": ("view-dual-symbolic", "Master + stack (Mod+Ctrl+=/- change masters)"),
}


def wait_until(pred, timeout=1.5, step=0.03):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if pred():
            return True
        time.sleep(step)
    return False


def write_atomic(path, text):
    with open(path + ".tmp", "w") as f:
        f.write(text)
    os.replace(path + ".tmp", path)


# ------------------------------------------------------------------ state file
def update_state(text, targets, layout):
    """Set layout.mode in the [[workspace]] entry of each target (by name, or index if unnamed)."""
    head, *blocks = re.split(r"(?m)^\[\[workspace\]\][ \t]*$", text)
    for t in targets:
        key = f'name = "{t["name"]}"' if t["named"] else f'index = {t["index"]}'
        for i, b in enumerate(blocks):
            if re.search(rf"(?m)^{re.escape(key)}[ \t]*$", b):
                if re.search(r"(?m)^layout\.mode[ \t]*=", b):
                    b = re.sub(r"(?m)^layout\.mode[ \t]*=.*$", f'layout.mode = "{layout}"', b)
                else:
                    b = b.rstrip("\n") + f'\nlayout.mode = "{layout}"\n\n'
                blocks[i] = b
                break
        else:
            if blocks and not blocks[-1].endswith("\n\n"):
                blocks[-1] = blocks[-1].rstrip("\n") + "\n\n"
            blocks.append(f'\n{key}\nlayout.mode = "{layout}"\n')
    return head + "".join("[[workspace]]" + b for b in blocks)


# ------------------------------------------------------------------ cascade
def workspace_windows(ws_id, windows=None):
    windows = windows if windows is not None else ipc.query("windows")
    return [w for w in windows
            if w["workspace"] == ws_id and not w["scratchpad"] and not w["pinned"]
            and not w["minimized"] and not w["fullscreen"] and not w["parent"]]


def ordered(wins, focused_id):
    """Previous left-to-right order (tiled by column/row, then floating by position);
    the focused window last so it ends on top."""
    wins = sorted(wins, key=lambda w: (w["floating"], w["column"], w["row"], w["x"], w["y"]))
    return [w["id"] for w in wins if w["id"] != focused_id] + \
           [w["id"] for w in wins if w["id"] == focused_id]


def clear_pending(ws_id):
    try:
        os.remove(f"{PENDING}/{ws_id}")
    except FileNotFoundError:
        pass


def cascade(output, order, focused_id, ws_id=None, centered=False):
    """Cascade the windows in `order` on `output`: from the top-left of the usable area, or
    centered on it (scratchpads). With ws_id, first wait for that workspace's layout to float
    its windows, and clear its pending flag afterwards."""
    out = next((o for o in ipc.query("outputs") if o["name"] == output), None)
    if not out or not order:
        if ws_id and not order:  # nothing to arrange: no longer pending
            clear_pending(ws_id)
        return
    ow, oh = out["logical_size"]["width"], out["logical_size"]["height"]
    ua = out["usable_area"]
    ux, uy = ua["x"], ua["y"]

    if ws_id:  # wait for the layout to float every window (no fixed sleep)
        wait_until(lambda: all(w["floating"] for w in workspace_windows(ws_id)))

    if centered:
        span = (len(order) - 1) * CASCADE_STEP
        x0 = ux + max(0, (ua["width"] - CASCADE_W * ow - span) // 2)
        y0 = uy + max(0, (ua["height"] - CASCADE_H * oh - span) // 2)
    else:
        x0, y0 = ux + CASCADE_X, uy + CASCADE_Y

    def target(slot):
        return int(x0 + slot * CASCADE_STEP), int(y0 + slot * CASCADE_STEP)

    def size_ok(w):
        return abs(w["w"] / ow - CASCADE_W) < SIZE_TOL and abs(w["h"] / oh - CASCADE_H) < SIZE_TOL

    def place(w, slot):
        if not size_ok(w):  # only focus + resize when needed (avoids redraw churn)
            ipc.action("window-focus", window=w["id"])
            if w.get("maximized_to_edges"):
                ipc.action("window-toggle-maximize-to-edges")
            if w.get("maximized"):
                ipc.action("window-toggle-maximize")
            dw, dh = CASCADE_W - w["w"] / ow, CASCADE_H - w["h"] / oh
            if abs(dw) > 1e-3:
                ipc.action("window-modify-width-right", delta=round(max(-0.9, min(0.9, dw)), 4))
            if abs(dh) > 1e-3:
                ipc.action("window-modify-height-down", delta=round(max(-0.9, min(0.9, dh)), 4))
        x, y = target(slot)
        ipc.action("window-move-to", anchor="top_left", x=x - ux, y=y - uy, window=w["id"])

    def mismatched():
        by_id = {w["id"]: w for w in ipc.query("windows")}
        bad = []
        for slot, wid in enumerate(order):
            w = by_id.get(wid)
            if not w:
                continue
            x, y = target(slot)
            if not size_ok(w) or abs(w["x"] - x) > POS_TOL or abs(w["y"] - y) > POS_TOL:
                bad.append((w, slot))
        return bad

    # First pass, then verify + retry only what's off (requests can be dropped mid-animation).
    for w, slot in mismatched():
        place(w, slot)
    for _ in range(4):
        if wait_until(lambda: not mismatched(), timeout=0.35):
            break
        for w, slot in mismatched():
            place(w, slot)

    if focused_id:
        ipc.action("window-focus", window=focused_id)
    if ws_id:
        clear_pending(ws_id)


def scratchpad(name):
    """Toggle a scratchpad; when it opens with 2+ windows, cascade them centered on screen."""
    def members():
        return [w for w in ipc.query("windows") if w["scratchpad"] == name]

    was_shown = any(w["visible"] for w in members())
    ipc.action("scratchpad-toggle", scratchpad=name)
    if was_shown or not wait_until(lambda: any(w["visible"] for w in members()), timeout=0.6):
        return  # it was hidden (or is empty)
    shown = [w for w in members() if w["visible"]]
    if len(shown) < 2:
        return
    try:  # inside a shown scratchpad the keyboard-focused window is reported as "active"
        fid = ipc.query("focused-window")["id"]
    except (RuntimeError, TypeError, KeyError):
        fid = ""
    ids = {w["id"] for w in shown}
    focused = fid if fid in ids else next((w["id"] for w in shown if w["active"]), shown[-1]["id"])
    order = [w["id"] for w in sorted(shown, key=lambda w: (w["x"], w["y"])) if w["id"] != focused] + [focused]
    cascade(shown[0]["output"], order, focused, centered=True)


# ------------------------------------------------------------------ main
def main(argv):
    if not os.path.exists(STATE):
        with open(DEFAULTS) as f:
            write_atomic(STATE, f.read())
    if argv[:1] == ["--init"]:
        return 0
    os.makedirs(PENDING, exist_ok=True)

    # One run at a time (fast key presses / watcher cascades would fight over focus/sizes).
    lock = open(LOCK, "w")
    fcntl.flock(lock, fcntl.LOCK_EX)

    if argv[:1] == ["--scratchpad"] and len(argv) > 1:
        scratchpad(argv[1])
        return 0

    all_ws = cascade_only = False
    cascade_target = ""
    if argv[:1] == ["--all"]:
        all_ws, argv = True, argv[1:]
    elif argv[:1] == ["--cascade"]:
        cascade_only, cascade_target, argv = True, (argv[1] if len(argv) > 1 else ""), []
    mode = argv[0] if argv else "toggle"

    workspaces = ipc.query("workspaces")
    ws = next(w for w in workspaces if w["focused"])
    focused = None
    try:
        focused = ipc.query("focused-window")
    except RuntimeError:
        pass
    focused_id = focused["id"] if focused else ""
    order = ordered(workspace_windows(ws["id"]), focused_id)

    if cascade_only:
        if cascade_target and cascade_target != ws["id"]:
            return 0  # focus moved on: keep it pending for the next visit
        if ws["layout"] == "stacking":
            cascade(ws["output"], order, focused_id, ws_id=ws["id"])
        return 0

    if mode == "toggle":
        cur = ws["layout"]
        new = CYCLE[(CYCLE.index(cur) + 1) % len(CYCLE)] if cur in CYCLE else CYCLE[0]
    else:
        new = mode
    if new not in CYCLE:
        return 1

    targets = workspaces if all_ws else [ws]
    with open(STATE) as f:
        state = update_state(f.read(), targets, new)

    for t in targets:
        flag = f"{PENDING}/{t['id']}"
        if new == "stacking" and t["id"] != ws["id"]:
            open(flag, "a").close()
        elif os.path.exists(flag):
            os.remove(flag)

    # Title bars + layout in one go -> one config reload.
    write_atomic(TITLEBAR, f'[appearance.title_bar]\nmode = "{"forced" if new == "stacking" else "off"}"\n')
    write_atomic(STATE, state)
    wait_until(lambda: next(w for w in ipc.query("workspaces") if w["id"] == ws["id"])["layout"] == new)

    # Cascade when entering stacking, and again when re-selected (Mod+F2 re-arranges).
    if new == "stacking":
        cascade(ws["output"], order, focused_id, ws_id=ws["id"])

    icon, desc = NOTIFY[new]
    scope = "all workspaces" if all_ws else ws["name"]
    subprocess.Popen(
        ["notify-send", "-a", "umbriel", "-i", icon, "-t", "1800",
         "-h", "string:x-canonical-private-synchronous:umbriel-layout",
         f"Layout: {new.capitalize()} · {scope}", desc],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
