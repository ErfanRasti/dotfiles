#!/usr/bin/env python3
import os
import sys
import socket

username = os.getenv("USER")
hostname = socket.gethostname()

pattern1 = f"/home/{username}"
replacement1 = "~"

pattern2 = f"{username}"
replacement2 = "user"

pattern3 = f"{hostname}"
replacement3 = "host"

for path in sys.argv[1:]:
    if not os.path.isfile(path):
        continue

    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    new_content = content.replace(pattern1, replacement1)
    new_content = content.replace(pattern2, replacement2)
    new_content = content.replace(pattern3, replacement3)

    if new_content != content:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
