#!/usr/bin/env python3
"""Bidirectional sync between matugen/config.toml and noctalia/user-templates.toml.

Text-based transformation that preserves comments and formatting.
"""

import re
import sys
from pathlib import Path

MATUGEN = Path.home() / ".config/matugen/config.toml"
NOCTALIA = Path.home() / ".config/noctalia/user-templates.toml"

NOCTALIA_HEADER = """[theme.templates]
enable_builtin_templates = true
enable_community_templates = true
builtin_ids = []
community_ids = ["telegram"]
"""

MATUGEN_HEADER = """[config]

version_check = false
"""


def matugen_to_noctalia(text: str) -> str:
    """Convert matugen format to noctalia format (text-based)."""
    # Replace config header with noctalia header
    text = re.sub(r"^\[config\]\n\nversion_check = false\n", NOCTALIA_HEADER, text)

    # Replace section headers
    text = re.sub(r"^\[config\.(custom_colors)\]$", r"[theme.templates.\1]", text, flags=re.MULTILINE)
    text = re.sub(r"^\[templates\.(\w+)\]$", r"[theme.templates.user.\1]", text, flags=re.MULTILINE)

    # Fix comments that reference old section names
    text = re.sub(r"# \[templates\.", "# [theme.templates.user.", text)
    text = re.sub(r"# \[config\.", "# [theme.templates.", text)

    return text


def noctalia_to_matugen(text: str) -> str:
    """Convert noctalia format to matugen format (text-based)."""
    # Replace noctalia header with config header
    text = re.sub(
        r"^\[theme\.templates\]\nenable_builtin_templates = true\nenable_community_templates = true\nbuiltin_ids = \[\]\ncommunity_ids = \[\"telegram\"\]\n",
        MATUGEN_HEADER,
        text,
    )

    # Replace section headers
    text = re.sub(r"^\[theme\.templates\.(custom_colors)\]$", r"[config.\1]", text, flags=re.MULTILINE)
    text = re.sub(r"^\[theme\.templates\.user\.(\w+)\]$", r"[templates.\1]", text, flags=re.MULTILINE)

    # Fix comments that reference old section names
    text = re.sub(r"# \[theme\.templates\.user\.", "# [templates.", text)
    text = re.sub(r"# \[theme\.templates\.", "# [config.", text)

    return text


def main():
    if len(sys.argv) < 2:
        print("Usage: sync_matugen_noctalia.py <changed-file>", file=sys.stderr)
        sys.exit(1)

    changed = Path(sys.argv[1]).resolve()

    if changed == MATUGEN.resolve():
        text = MATUGEN.read_text()
        output = matugen_to_noctalia(text)
        NOCTALIA.write_text(output)
        print(f"Synced: {MATUGEN.name} → {NOCTALIA.name}")
    elif changed == NOCTALIA.resolve():
        text = NOCTALIA.read_text()
        output = noctalia_to_matugen(text)
        MATUGEN.write_text(output)
        print(f"Synced: {NOCTALIA.name} → {MATUGEN.name}")
    else:
        print(f"Unknown file: {changed}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()