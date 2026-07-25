#!/usr/bin/env python3
"""Bidirectional sync between matugen/config.toml and noctalia/user-templates.toml.

Text-based transformation that preserves comments and formatting.
Preserves [theme.templates] in noctalia and [config] in matugen (never synced).
"""

import re
import sys
from pathlib import Path

MATUGEN = Path.home() / ".config/matugen/config.toml"
NOCTALIA = Path.home() / ".config/noctalia/user-templates.toml"


def extract_block(text: str, section: str) -> tuple[str, str]:
    """Extract a TOML section block without trailing newlines."""
    pattern = rf"^(\[{re.escape(section)}\](?:\n(?:[^\[\n].*)*)*)"
    m = re.match(pattern, text, re.MULTILINE)
    if m:
        return m.group(1), text[m.end():]
    return "", text


def strip_section(text: str, section: str) -> str:
    """Remove a TOML section and any trailing blank lines."""
    pattern = rf"^\[{re.escape(section)}\].*?(?=\n\[|\Z)"
    text = re.sub(pattern, "", text, count=1, flags=re.DOTALL)
    return text


def collapse_newlines(text: str) -> str:
    """Collapse 3+ consecutive newlines to exactly 2."""
    return re.sub(r"\n{3,}", "\n\n", text)


def normalize(text: str) -> str:
    """Normalize whitespace: strip, collapse blank lines, ensure trailing newline."""
    text = text.strip()
    text = collapse_newlines(text)
    return text + "\n"


def is_noctalia_format(text: str) -> bool:
    """Check if text is in noctalia format (has [theme.templates.user.*] sections)."""
    return bool(re.search(r"^\[theme\.templates\.user\.\w+\]", text, re.MULTILINE))


def is_matugen_format(text: str) -> bool:
    """Check if text is in matugen format (has [templates.*] sections)."""
    return bool(re.search(r"^\[templates\.\w+\]", text, re.MULTILINE))


def matugen_to_noctalia(text: str) -> str:
    """Convert matugen format to noctalia format (text-based).

    Preserves the existing [theme.templates] block in noctalia.
    Strips [config] block (noctalia doesn't have it).
    """
    if is_noctalia_format(text):
        return normalize(text)

    existing_noctalia = NOCTALIA.read_text()
    theme_block, _ = extract_block(existing_noctalia, "theme.templates")

    config_block, text = extract_block(text, "config")
    text = strip_section(text, "theme.templates")

    text = re.sub(r"^\[config\.(custom_colors)\]$", r"[theme.templates.\1]", text, flags=re.MULTILINE)
    text = re.sub(r"^\[templates\.(\w+)\]$", r"[theme.templates.user.\1]", text, flags=re.MULTILINE)
    text = re.sub(r"# \[templates\.", "# [theme.templates.user.", text)
    text = re.sub(r"# \[config\.", "# [theme.templates.", text)

    if theme_block:
        text = theme_block + "\n" + text

    return normalize(text)


def noctalia_to_matugen(text: str) -> str:
    """Convert noctalia format to matugen format (text-based).

    Preserves the existing [config] block in matugen.
    Strips [theme.templates] block (matugen manages it separately).
    """
    if is_matugen_format(text):
        return normalize(text)

    existing_matugen = MATUGEN.read_text()
    config_block, _ = extract_block(existing_matugen, "config")

    noctalia_theme_block, text = extract_block(text, "theme.templates")

    text = re.sub(r"^\[theme\.templates\.(custom_colors)\]$", r"[config.\1]", text, flags=re.MULTILINE)
    text = re.sub(r"^\[theme\.templates\.user\.(\w+)\]$", r"[templates.\1]", text, flags=re.MULTILINE)
    text = re.sub(r"# \[theme\.templates\.user\.", "# [templates.", text)
    text = re.sub(r"# \[theme\.templates\.", "# [config.", text)

    if config_block:
        text = config_block + "\n" + text

    return normalize(text)


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