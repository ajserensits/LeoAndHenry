"""Check a candidate PNG against the Art Bible before it enters the app.

Checks filename convention, format, size, color mode, and (for obstacles and
markers) transparency. It cannot judge likeness, so the Art Bible review
checklist still applies.

Usage: python3 -I ArtworkSource/tools/check_asset.py path/to/file.png [...]
"""

import re
import sys
from pathlib import Path

from PIL import Image

# filename pattern -> (expected size, needs transparency)
RULES = [
    (r"chapter-\d{2}-scene-\d{2}-[a-z0-9-]+", ((1536, 1024),), False),
    (r"chapter-\d{2}-[a-z0-9-]+", ((1672, 941),), False),
    (r"obstacle-[a-z0-9-]+", ((512, 512),), True),
    (r"leo-henry-[a-z0-9-]+", ((941, 1672),), False),  # portrait title art
    (r"(leo|henry)-map-marker(-[a-z0-9-]+)?", ((512, 512),), False),
    (r"(leo|henry)-[a-z0-9-]+", ((512, 512),), False),
    (r"app-icon(-[a-z0-9-]+)?", ((1024, 1024),), False),
]


def check(path):
    problems = []
    stem = path.stem
    if path.suffix != ".png":
        problems.append("must be a .png")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", stem):
        problems.append("filename must be lowercase kebab-case")

    rule = next((r for r in RULES if re.fullmatch(r[0], stem)), None)
    if rule is None:
        problems.append("filename matches no Art Bible convention")

    with Image.open(path) as image:
        if image.format != "PNG":
            problems.append(f"file is {image.format}, not PNG")
        icc = image.info.get("icc_profile")
        if icc and b"sRGB" not in icc and b"srgb" not in icc.lower():
            problems.append("embedded color profile is not sRGB")
        if rule:
            sizes, needs_alpha = rule[1], rule[2]
            if image.size not in sizes:
                want = " or ".join(f"{w}x{h}" for w, h in sizes)
                problems.append(f"size {image.width}x{image.height}, expected {want}")
            has_alpha = image.mode in ("RGBA", "LA") or "transparency" in image.info
            if needs_alpha:
                if not has_alpha:
                    problems.append("needs a transparent background")
                else:
                    corners = [image.convert("RGBA").getpixel(p)[3] for p in
                               ((0, 0), (image.width - 1, 0), (0, image.height - 1),
                                (image.width - 1, image.height - 1))]
                    if max(corners) > 10:
                        problems.append("corners are not transparent")
            if stem.startswith("app-icon") and has_alpha:
                problems.append("app icon must not have an alpha channel")

    return problems


def main(paths):
    failed = False
    for name in paths:
        path = Path(name)
        problems = check(path)
        status = "OK  " if not problems else "FAIL"
        print(f"{status} {path.name}")
        for problem in problems:
            print(f"     - {problem}")
        failed |= bool(problems)
    return 1 if failed else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
