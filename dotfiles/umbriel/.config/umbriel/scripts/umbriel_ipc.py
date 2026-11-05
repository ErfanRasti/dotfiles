"""Tiny client for umbriel's JSON IPC socket ($UMBRIEL_SOCKET).

One request per connection (umbriel closes the socket after replying). Talking to the socket
directly avoids spawning `umbriel` + `jq` processes for every query/action.
"""

import json
import os
import socket


def _path():
    # umbriel exports UMBRIEL_SOCKET to everything it spawns; otherwise derive it from the
    # session's runtime dir and Wayland display (no hard-coded paths).
    p = os.environ.get("UMBRIEL_SOCKET")
    if p:
        return p
    wl = os.environ.get("WAYLAND_DISPLAY", "wayland-0")
    return os.path.join(os.environ.get("XDG_RUNTIME_DIR", ""), f"umbriel-{wl}.sock")


SOCKET = _path()


def _readline(s):
    buf = bytearray()
    while not buf.endswith(b"\n"):
        chunk = s.recv(262144)
        if not chunk:
            break
        buf += chunk
    return bytes(buf)


def request(obj):
    """Send one request; return the "ok" payload, or raise RuntimeError with the "err" text."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKET)
        s.sendall(json.dumps(obj).encode() + b"\n")
        reply = json.loads(_readline(s) or b"{}")
    if "err" in reply:
        raise RuntimeError(reply["err"])
    return reply.get("ok")


def query(cmd):
    return request({"cmd": cmd})


def action(name, **args):
    """Run an action; returns True on success, False on an error reply."""
    try:
        request({"cmd": "action", "action": name, **args})
        return True
    except (RuntimeError, OSError):
        return False


def subscribe(events):
    """Yield parsed event objects ({"event": ..., "data": ...}) until the stream ends."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(SOCKET)
        s.sendall(json.dumps({"cmd": "subscribe", "events": list(events)}).encode() + b"\n")
        with s.makefile("rb") as f:
            for line in f:
                try:
                    yield json.loads(line)
                except ValueError:
                    continue
