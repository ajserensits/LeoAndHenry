"""Trim generated transparent sprites to their visible pixels and cap their size.

Keeps the soft contact shadow, so the bottom edge of the result is where the
object meets the ground (the yard screen anchors sprites by bottom-center).

Usage: python3 -I ArtworkSource/tools/finish_sprite.py OUT_DIR PREFIX raw.png [...]
Writes OUT_DIR/PREFIX<raw name>.png
"""

import sys
from pathlib import Path

from PIL import Image

MAX_SIDE = 600


def finish(raw, out_dir, prefix):
    image = Image.open(raw).convert("RGBA")
    alpha = image.getchannel("A").point(lambda a: 255 if a > 10 else 0)
    image = image.crop(alpha.getbbox())
    scale = min(1.0, MAX_SIDE / max(image.size))
    if scale < 1:
        image = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    final = out_dir / f"{prefix}{raw.name}"
    image.save(final, optimize=True)
    return final


if __name__ == "__main__":
    out_dir = Path(sys.argv[1])
    out_dir.mkdir(parents=True, exist_ok=True)
    for name in sys.argv[3:]:
        print(finish(Path(name), out_dir, sys.argv[2]))
