"""Turn raw 1536x1024 generator output into 1672x941 chapter backgrounds.

Scales to 1672 wide, center-crops the height, saves as sRGB PNG, and writes a
review copy with the safe-zone template laid over it.

Usage: python3 -I ArtworkSource/tools/finish_background.py OUT_DIR raw.png [...]
"""

import sys
from pathlib import Path

from PIL import Image

TEMPLATE = Path(__file__).resolve().parent.parent / "templates" / "template-chapter-background-1672x941.png"
W, H = 1672, 941


def finish(raw, out_dir):
    image = Image.open(raw).convert("RGB")
    scale = W / image.width
    image = image.resize((W, round(image.height * scale)), Image.LANCZOS)
    top = (image.height - H) // 2
    image = image.crop((0, top, W, top + H))

    final = out_dir / raw.name
    image.save(final, optimize=True)

    review = out_dir / "review" / raw.name
    review.parent.mkdir(exist_ok=True)
    Image.alpha_composite(image.convert("RGBA"), Image.open(TEMPLATE)).convert("RGB").save(review)
    return final


if __name__ == "__main__":
    out_dir = Path(sys.argv[1])
    out_dir.mkdir(parents=True, exist_ok=True)
    for name in sys.argv[2:]:
        print(finish(Path(name), out_dir))
