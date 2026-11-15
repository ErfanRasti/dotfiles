#!/usr/bin/env python3
"""Usage: pad.py SOCKET_PATH

Companion of the desktop icons' input pad: a ui.pixelStream only reports pointer and
key events once it shows a frame, so this serves it one fully transparent 1x1 frame
(noctalia's pixel-stream protocol: SOCK_SEQPACKET, little-endian u32 messages,
RGBA buffers in sealed memfds). The icons are drawn by the plugin under it.

Exits when another instance owns the socket, and when its parent plugin runtime
is gone (the socket file is removed or replaced).

Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).
"""

import fcntl
import os
import select
import socket
import struct
import sys

REQUEST = 2  # noctalia -> companion (HELLO, 1, needs no answer)
BUFFER, FRAME = 1, 2


def make_buffer():
    fd = os.memfd_create("desktop-icons-pad", os.MFD_CLOEXEC | os.MFD_ALLOW_SEALING)
    os.write(fd, bytes(4))  # 1x1, RGBA 0,0,0,0
    fcntl.fcntl(fd, fcntl.F_ADD_SEALS, fcntl.F_SEAL_SHRINK)
    return fd


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    path = sys.argv[1]
    os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)

    # Another live instance answers on the socket: leave it be.
    probe = socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET)
    try:
        probe.connect(path)
        probe.close()
        return
    except OSError:
        probe.close()
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass

    server = socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET)
    server.bind(path)
    os.chmod(path, 0o600)
    server.listen(4)
    ino = os.stat(path).st_ino
    fd = make_buffer()

    sent = {}  # connection -> whether it has its frame (one per connection)
    while True:
        ready, _, _ = select.select([server, *sent], [], [], 5.0)
        try:
            if os.stat(path).st_ino != ino:
                return  # replaced by a newer instance
        except FileNotFoundError:
            return
        for s in ready:
            if s is server:
                sent[server.accept()[0]] = False
                continue
            try:
                data = s.recv(64)
                if not data:
                    raise ConnectionError
                if not sent[s] and len(data) >= 8 and struct.unpack_from("<I", data)[0] == REQUEST:
                    socket.send_fds(s, [struct.pack("<IIII", BUFFER, 0, 1, 1)], [fd])
                    s.send(struct.pack("<II", FRAME, 0))
                    sent[s] = True
            except OSError:  # ConnectionError included
                del sent[s]
                s.close()


if __name__ == "__main__":
    main()
