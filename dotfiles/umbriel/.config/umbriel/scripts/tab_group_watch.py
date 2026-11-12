#!/usr/bin/env -S python3 -I -B
"""Open new windows inside the focused tab group instead of beside it.

umbriel always opens a new tiled window as a new column next to the focused one, even when
that column is a tab group (Mod+G). This listens to window events on the IPC socket and, when
a window appears while a tab group had focus, stacks it into that group with
`window-consume-left`. It then lands where [layout.tabs] new_tab_position says.

Ignored: floating, scratchpad and dialog (child) windows, and windows that open on another
workspace or not right of the group (window rules, other outputs).
Started from config/autostarts.toml. Only one instance runs at a time.
"""

import fcntl
import os
import sys
import time

HERE = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, HERE)
import umbriel_ipc as ipc  # noqa: E402

RUN = os.environ.get("XDG_RUNTIME_DIR", "/tmp")


def tiled(w):
    return not (w.get("floating") or w.get("scratchpad") or w.get("minimized"))


def should_join(new, group):
    return (
        group is not None
        and new.get("focused")
        and tiled(new)
        and not new.get("parent")
        and not new.get("tabbed")
        and new.get("workspace") == group.get("workspace")
        and new.get("column") == group.get("column", -2) + 1
    )


def main():
    lock = open(f"{RUN}/umbriel-tab-group-watch.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return 0  # already running

    while True:
        known = None   # window ids seen in the previous event
        group = None   # focused window, if it was a tiled tab in a group
        pending = {}   # new window id -> (group when it appeared, deadline); focus may come later
        try:
            for ev in ipc.subscribe(["windows"]):
                wins = ev.get("data")
                if not isinstance(wins, list):
                    continue
                ids = {w["id"] for w in wins}
                now = time.monotonic()
                if known is not None and group is not None:
                    for i in ids - known:
                        pending[i] = (group, now + 1.0)
                pending = {i: p for i, p in pending.items() if i in ids and p[1] > now}
                for w in wins:
                    p = pending.get(w["id"])
                    if p and w.get("focused"):
                        del pending[w["id"]]
                        if should_join(w, p[0]):
                            ipc.action("window-consume-left")
                        break
                known = ids
                focused = next((w for w in wins if w.get("focused")), None)
                if focused is not None:
                    group = focused if focused.get("tabbed") and tiled(focused) else None
        except OSError:
            pass
        time.sleep(2)  # compositor restarted or stream dropped: reconnect


if __name__ == "__main__":
    sys.exit(main())
