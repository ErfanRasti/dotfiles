#!/usr/bin/env python3
import os
import re
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

# Device pairing IDs that apps write into their settings (the selectedDeviceId key)
device_id = re.compile(r'("selectedDeviceId"\s*:\s*)"[^"]+"')

for path in sys.argv[1:]:
    if not os.path.isfile(path):
        continue

    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    new_content = (
        content.replace(pattern1, replacement1)
        .replace(pattern2, replacement2)
        .replace(pattern3, replacement3)
    )
    new_content = device_id.sub(r'\1""', new_content)

    if new_content != content:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
