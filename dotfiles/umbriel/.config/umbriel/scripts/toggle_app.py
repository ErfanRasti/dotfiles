#!/usr/bin/env python3
"""App toggle (umbriel port of niri/scripts/toggle_app.sh), using umbriel's default scratchpad.

Usage: toggle_app.py [--float[=WxH]] <app-id> <command...>
--float opens the app floating and centered, WxH of the screen (default 0.65x0.7).
Only the window this script started is toggled (its id is kept in $XDG_RUNTIME_DIR/toggle_app/);
other windows of the app are left alone.
  not open               -> start <command> (in the workspace's layout, or floating with --float)
  focused on a workspace -> put it into the scratchpad (Mod+Shift+W shows the scratchpad)
  in the scratchpad      -> (shown or hidden) move it out to the current workspace and focus it
  on another workspace   -> bring it to the current workspace and focus it
  on this workspace      -> focus it

umbriel's move actions act on the FOCUSED window, so every move first makes sure the target
really has focus and otherwise does nothing (never moves some other window by mistake).

No in-between motion: every step goes straight to umbriel's socket (well under a millisecond
each), so the whole burst (focus on the other workspace, move, switch back) lands inside one
frame. The workspace the window came from never shows up and nothing slides there and back;
only the window's own pop out / pop in animation plays.
"""

import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import umbriel_ipc as ipc  # noqa: E402

STATE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "toggle_app")
FLOAT = (0.65, 0.7)  # default --float size, as fractions of the screen


def act(name, **args):
    return ipc.action(name, **args)


def focused_id():
    try:
        return (ipc.query("focused-window") or {}).get("id")
    except (RuntimeError, OSError):
        return None


def focus(wid):
    """Focus <wid>; True once umbriel reports it focused (focus is normally applied at once)."""
    act("window-focus", window=wid)
    for _ in range(50):  # safety net only: at most ~50 ms
        if focused_id() == wid:
            return True
        time.sleep(0.001)
    return False


def pad_shown():
    return sum(1 for w in ipc.query("windows") if w["scratchpad"] and w["visible"])


def place_after(wid, anchor):
    """Scrolling layout: move <wid> (focused, in its own column) to the column right after
    <anchor>, the window that was focused before, instead of wherever it landed (the end)."""
    if not anchor:
        return
    cols = {w["id"]: w for w in ipc.query("windows")}
    me, ref = cols.get(wid), cols.get(anchor)
    if not me or not ref or me["floating"] or ref["floating"] or me["workspace"] != ref["workspace"]:
        return
    gap = me["column"] - ref["column"]
    if gap > 1:
        for _ in range(gap - 1):
            act("column-move-left")
    elif gap < 0:  # left of the anchor (restored to this workspace): step over it
        for _ in range(-gap):
            act("column-move-right")


def bring(wid, cur, anchor, scrolling):
    """With <wid> focused: move it to workspace <cur>, stay there, and slot it after <anchor>."""
    act("window-move-to-workspace", workspace=cur)
    act("workspace-switch", workspace=cur)
    if focus(wid) and scrolling:
        place_after(wid, anchor)


def wait_for(wid, ok):
    """Poll <wid> until ok(window) (at most ~1 s); return the window, or None."""
    for _ in range(100):
        w = next((x for x in ipc.query("windows") if x["id"] == wid), None)
        if w and ok(w):
            return w
        time.sleep(0.01)
    return None


def make_floating(wid, size):
    """Float <wid>, resize it to <size> (fractions of its output) and center it."""
    if not focus(wid):
        return
    act("window-toggle-floating", window=wid)
    w = wait_for(wid, lambda w: w["floating"])
    if not w:
        return
    out = next(o for o in ipc.query("outputs") if o["name"] == w["output"])["logical_size"]
    ow, oh = out["width"], out["height"]
    act("window-modify-width-right", delta=round(size[0] - w["w"] / ow, 4))
    act("window-modify-height-down", delta=round(size[1] - w["h"] / oh, 4))
    # Center once the resize has landed, or the old size is used.
    wait_for(wid, lambda w: abs(w["w"] / ow - size[0]) < 0.02 and abs(w["h"] / oh - size[1]) < 0.05)
    act("window-center")


def spawn(cmd, app_id, state, windows, size=None):
    """Start <cmd> and save the id of the window it opens as the one to toggle (floated if <size>)."""
    before = {w["id"] for w in windows}
    subprocess.run(["umbriel", "msg", "spawn", *cmd], check=False)
    for _ in range(300):  # up to ~30 s, for a slow cold start
        new = [w["id"] for w in ipc.query("windows")
               if w["id"] not in before and w["app_id"] == app_id and not w["parent"]]
        if new:
            os.makedirs(STATE, exist_ok=True)
            with open(state, "w") as f:
                f.write(new[0])
            if size:
                make_floating(new[0], size)
            return
        time.sleep(0.1)


def main():
    args, size = sys.argv[1:], None
    if args and args[0].startswith("--float"):
        wh = args.pop(0).partition("=")[2]
        size = tuple(map(float, wh.split("x"))) if wh else FLOAT
    if len(args) < 2:
        sys.exit("usage: toggle_app.py [--float[=WxH]] <app-id> <command...>")
    app_id, cmd = args[0], args[1:]
    state = os.path.join(STATE, app_id)

    windows = ipc.query("windows")
    try:
        with open(state) as f:
            tracked = f.read()
    except OSError:
        tracked = None
    target = next((w for w in windows if w["id"] == tracked), None)
    if target is None:
        return spawn(cmd, app_id, state, windows, size)

    ws = next(w for w in ipc.query("workspaces") if w["focused"])
    cur, scrolling = ws["index"], ws["layout"] == "scrolling"

    wid, pad = target["id"], target["scratchpad"]
    # The window focused on screen right now. (The windows list's "focused" flag is per
    # workspace, so it is true for one window on every workspace: never use it for this.)
    anchor = focused_id()

    if anchor == wid and not pad:
        act("window-move-to-scratchpad")
    elif pad:
        # Restoring needs the scratchpad shown; remember whether it was, so it can be hidden
        # again instead of leaving the other scratchpad windows open over the workspace.
        shown = pad_shown()
        if not focus(wid):  # reveals it in the scratchpad
            return
        act("window-restore-from-scratchpad")  # back to its saved workspace...
        if shown == 0 and pad_shown() != 0:
            act("scratchpad-toggle")
        if focus(wid):
            bring(wid, cur, anchor, scrolling)  # ...then to the current one
    elif target["workspace"] != ws["id"]:
        if focus(wid):
            bring(wid, cur, anchor, scrolling)
    else:
        focus(wid)


if __name__ == "__main__":
    main()
