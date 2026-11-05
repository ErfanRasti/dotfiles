#!/usr/bin/env -S python3 -I -B
"""Title bars only while the focused workspace uses the stacking layout, plus deferred cascades.

umbriel has no per-layout title-bar setting, so this listens to workspace events on the IPC
socket (one process, no `umbriel subscribe`/`jq` children) and writes config/titlebar.toml
(an optional include) only when the mode must change. Layouts live in config
(set_layout.py), so these reloads don't reset them.

Workspaces switched to stacking by `set_layout.py --all` but not cascaded yet have a flag in
$XDG_RUNTIME_DIR/umbriel-cascade-pending/; on the first visit they are cascaded.
Started from config/autostarts.toml. Only one instance runs at a time.
"""

import fcntl
import os
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, HERE)
import umbriel_ipc as ipc  # noqa: E402

TITLEBAR = os.path.expanduser("~/.config/umbriel/config/titlebar.toml")
RUN = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
PENDING = f"{RUN}/umbriel-cascade-pending"
SET_LAYOUT = os.path.join(HERE, "set_layout.py")


def current_mode():
    try:
        with open(TITLEBAR) as f:
            text = f.read()
    except FileNotFoundError:
        return None
    return "forced" if '"forced"' in text else "off"


def apply(mode):
    if current_mode() == mode:
        return
    with open(TITLEBAR + ".tmp", "w") as f:
        f.write(f'[appearance.title_bar]\nmode = "{mode}"\n')
    os.replace(TITLEBAR + ".tmp", TITLEBAR)


def deferred_cascade(ws_id):
    subprocess.Popen([sys.executable, "-I", "-B", SET_LAYOUT, "--cascade", ws_id],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main():
    lock = open(f"{RUN}/umbriel-stacking-watch.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return 0  # already running

    last = None
    while True:
        try:
            for ev in ipc.subscribe(["workspaces"]):
                focused = next((w for w in ev.get("data") or [] if w.get("focused")), None)
                if not focused:
                    continue
                key = (focused["id"], focused["layout"])
                if key == last:
                    continue  # unrelated workspace event (window count, urgency, ...)
                last = key
                stacking = focused["layout"] == "stacking"
                apply("forced" if stacking else "off")
                if stacking and os.path.exists(f"{PENDING}/{focused['id']}"):
                    # Let the workspace switch settle; set_layout.py clears the flag on success.
                    threading.Timer(0.35, deferred_cascade, args=(focused["id"],)).start()
        except OSError:
            pass
        last = None
        time.sleep(2)  # compositor restarted or stream dropped: reconnect


if __name__ == "__main__":
    sys.exit(main())
