#!/usr/bin/env python3
import os
import sys

username = os.getenv("USER")
pattern = f"{username}"
replacement = "user"

for path in sys.argv[1:]:
    if not os.path.isfile(path):
        continue

    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    new_content = content.replace(pattern, replacement)

    if new_content != content:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
