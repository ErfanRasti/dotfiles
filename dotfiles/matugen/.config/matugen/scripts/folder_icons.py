#!/usr/bin/env python3
"""Usage: folder_icons.py TONES_FILE

Build the Papirus-Matugen (system-wide) and Adwaita-Matugen (Nautilus) icon themes:
Papirus and Adwaita with Adwaita's folders recolored to the matugen primary palette.

TONES_FILE has "tone #rrggbb" lines of that palette (folder-icons-tones.txt template).
Each blue of the folders keeps its lightness (a Material tone is CIE L*) and its chroma
relative to the folder's main blue, but takes the palette's hue, so folders look like
Adwaita's in any color and in both light and dark mode. Greys stay as they are.
"""

import math
import os
import re
import sys
from pathlib import Path

THEMES = {"Papirus-Matugen": "Papirus,Adwaita,hicolor", "Adwaita-Matugen": "Adwaita,hicolor"}
ICONS = ["places/folder*.svg", "places/user-home.svg", "places/user-bookmarks.svg",
         "mimetypes/inode-directory.svg"]
# Folders drawn like Adwaita's: its folder with an emblem from ../emblems (symbolic icons
# from GNOME's Icon Development Kit, as shown in Icon Library; CC0), which also becomes
# the folder's symbolic icon
EMBLEMS = {"folder-programs": "grid-large", "folder-projects": "code", "user-desktop": "shell-overview"}
MAIN_BLUE = "#62a0ea"  # front of Adwaita's folder

INDEX_THEME = """[Icon Theme]
Name={name}
Inherits={inherits}
Directories=scalable

[scalable]
Size=128
MinSize=8
MaxSize=512
Type=Scalable
"""

WHITE = (0.95047, 1.0, 1.08883)  # D65


def hex_to_lch(h):
    r, g, b = ((c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
               for c in (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)))
    xyz = (0.4124 * r + 0.3576 * g + 0.1805 * b,
           0.2126 * r + 0.7152 * g + 0.0722 * b,
           0.0193 * r + 0.1192 * g + 0.9505 * b)
    fx, fy, fz = ((t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116)
                  for t in (v / w for v, w in zip(xyz, WHITE)))
    a, b = 500 * (fx - fy), 200 * (fy - fz)
    return 116 * fy - 16, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360


def lch_to_hex(l, c, h):
    """Lowers the chroma until the color fits in sRGB."""
    while True:
        a, b = c * math.cos(math.radians(h)), c * math.sin(math.radians(h))
        fy = (l + 16) / 116
        x, y, z = (w * (f**3 if f**3 > 216 / 24389 else (116 * f - 16) / (24389 / 27))
                   for w, f in zip(WHITE, (fy + a / 500, fy, fy - b / 200)))
        rgb = (3.2406 * x - 1.5372 * y - 0.4986 * z,
               -0.9689 * x + 1.8758 * y + 0.0415 * z,
               0.0557 * x - 0.2040 * y + 1.0570 * z)
        if all(-1e-4 <= v <= 1 + 1e-4 for v in rgb) or c < 0.5:
            break
        c *= 0.97
    return "#" + "".join(
        f"{round((12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055) * 255):02x}"
        for v in (min(max(v, 0), 1) for v in rgb))


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    # tone -> (L, C, h)
    tones = dict(sorted((int(t), hex_to_lch(h)) for t, h in
                        (line.split() for line in Path(sys.argv[1]).read_text().splitlines())))

    def palette(l):  # (chroma, hue) at lightness l, interpolated between the nearest tones
        lo = max(t for t in tones if t <= l)
        hi = min((t for t in tones if t >= l), default=lo)
        f = 0 if hi == lo else (l - lo) / (hi - lo)
        (_, c0, h0), (_, c1, h1) = tones[lo], tones[hi]
        return c0 + (c1 - c0) * f, h0 + ((h1 - h0 + 180) % 360 - 180) * f

    main_l, main_c, _ = hex_to_lch(MAIN_BLUE)
    scale = palette(main_l)[0] / main_c

    def recolor(match):
        l, c, h = hex_to_lch(match.group(0))
        if c < 8 or not 200 <= h <= 300:  # greys and non-blue accents
            return match.group(0)
        chroma, hue = palette(l)
        return lch_to_hex(l, min(c * scale, chroma), hue)

    adwaita = next((Path(d) / "icons/Adwaita" for d in
                    os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":")
                    if (Path(d) / "icons/Adwaita/scalable/places/folder.svg").is_file()), None)
    if adwaita is None:
        sys.exit("folder_icons: Adwaita icon theme not found in XDG_DATA_DIRS")
    svgs = {svg.name: svg.read_text() for p in ICONS for svg in adwaita.glob(f"scalable/{p}")}
    for name, symbol in EMBLEMS.items():
        icon = (Path(__file__).resolve().parent.parent / "emblems" / f"{symbol}-symbolic.svg").read_text()
        paths = re.sub(r'\s(fill|class|style)="[^"]*"', "", re.search(r"<svg[^>]*>(.*)</svg>", icon, re.S)[1])
        svgs[f"{name}.svg"] = svgs["folder.svg"].replace(  # emblem in Adwaita's #438de6
            "</svg>", f'<g fill="#438de6" transform="translate(50 62) scale(1.75)">{paths}</g></svg>')
        svgs[f"{name}-symbolic.svg"] = icon  # e.g. for Nautilus' sidebar
    svgs = {name: re.sub(r"#[0-9a-fA-F]{6}\b", recolor, text) for name, text in svgs.items()}

    icons = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "icons"
    for name, inherits in THEMES.items():
        (icons / name / "scalable").mkdir(parents=True, exist_ok=True)
        for svg, text in svgs.items():
            (icons / name / "scalable" / svg).write_text(text)
        (icons / name / "index.theme").write_text(INDEX_THEME.format(name=name, inherits=inherits))
        os.utime(icons / name)  # GTK rescans an icon theme when its directory changes


if __name__ == "__main__":
    main()
