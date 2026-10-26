"""Draw composition safe-zone templates for each artwork format.

Templates are review aids only. Lay one over a generated image (or attach it
to the image prompt) to check that the board, pause button, captions, and
iPhone crops stay clear. Never ship a template in the app bundle.

Usage: python3 -I ArtworkSource/tools/make_templates.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent.parent / "templates"

KEEP_CLEAR = (40, 140, 255, 70)   # board / UI sits here: keep it calm
CROP_LOST = (0, 0, 0, 110)        # cropped away on some iPhones
CAPTION = (255, 170, 0, 70)       # app-rendered text goes here
LINE = (255, 255, 255, 230)


def font(size):
    for name in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                 "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def label(draw, xy, text, size=26):
    draw.text(xy, text, font=font(size), fill=LINE, stroke_width=3, stroke_fill=(0, 0, 0, 255))


def canvas(w, h):
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def chapter_background():
    # 1672 x 941 source, shown with scaledToFill behind the board.
    w, h = 1672, 941
    image, d = canvas(w, h)

    # Landscape iPhone (~932 x 430 pt, 19.5:9): fills width, crops top/bottom.
    visible_h = w * 430 / 932
    crop = (h - visible_h) / 2
    d.rectangle([0, 0, w, crop], fill=CROP_LOST)
    d.rectangle([0, h - crop, w, h], fill=CROP_LOST)
    label(d, (20, 12), "cropped in landscape on modern iPhones", 22)

    # Art Bible: central 55% stays calm because the square board covers it.
    x0, x1 = w * 0.225, w * 0.775
    d.rectangle([x0, crop, x1, h - crop], fill=KEEP_CLEAR, outline=LINE, width=3)
    label(d, (x0 + 16, crop + 16), "BOARD ZONE: central 55%, calm, no characters")

    # Pause button: 52 pt circle, 18 pt from right, 10 pt from top (landscape).
    scale = w / 932
    bx1 = w - 18 * scale
    by0 = crop + 10 * scale
    d.ellipse([bx1 - 52 * scale, by0, bx1, by0 + 52 * scale], fill=(255, 255, 255, 90), outline=LINE, width=3)
    label(d, (bx1 - 300, by0 + 52 * scale + 8), "pause button: low contrast", 22)

    # Portrait: same image fills height, so only a central strip is visible.
    strip = h * 430 / 932
    px0 = (w - strip) / 2
    for x in (px0, px0 + strip):
        for y in range(0, h, 24):
            d.line([x, y, x, y + 12], fill=(255, 80, 80, 255), width=4)
    label(d, (px0 + 8, h - crop - 70), "portrait: only this strip shows", 22)

    label(d, (20, h - crop - 110), "character moments\nin side margins", 28)
    label(d, (x1 + 20, h - crop - 110), "character moments\nin side margins", 28)
    image.save(OUT / "template-chapter-background-1672x941.png")


def story_panel():
    # 1536 x 1024 source. Landscape shows it whole; portrait shows a square
    # center crop. Captions are rendered by SwiftUI along the bottom.
    w, h = 1536, 1024
    image, d = canvas(w, h)
    sq0 = (w - h) / 2
    d.rectangle([0, 0, sq0, h], fill=CROP_LOST)
    d.rectangle([w - sq0, 0, w, h], fill=CROP_LOST)
    label(d, (16, 16), "landscape only", 22)
    label(d, (w - sq0 + 16, 16), "landscape only", 22)
    d.rectangle([sq0, 0, w - sq0, h], outline=LINE, width=3)
    label(d, (sq0 + 16, 16), "PORTRAIT CROP: both dogs and the scary object fit here")
    d.rectangle([0, h * 0.80, w, h], fill=CAPTION)
    label(d, (sq0 + 16, h * 0.80 + 16), "CAPTION BAND: simple ground or floor, no faces")
    image.save(OUT / "template-story-panel-1536x1024.png")


def obstacle_tile():
    # 512 x 512 transparent blocker. Must not read as a round match piece.
    s = 512
    image, d = canvas(s, s)
    pad = s * 0.08
    d.rectangle([0, 0, s - 1, s - 1], outline=(255, 80, 80, 255), width=4)
    d.rectangle([pad, pad, s - pad, s - pad], outline=LINE, width=3)
    label(d, (pad + 10, pad + 10), "object fits inside 84%", 22)
    label(d, (pad + 10, s - pad - 64), "transparent background\nreadable at 44 pt", 22)
    image.save(OUT / "template-obstacle-512.png")


def map_marker():
    # 512 x 512 portrait, clipped to a circle by ChapterMapView.
    s = 512
    image, d = canvas(s, s)
    d.rectangle([0, 0, s, s], fill=CROP_LOST)
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, s, s], fill=255)
    image.paste((0, 0, 0, 0), (0, 0), mask)
    d = ImageDraw.Draw(image)
    d.ellipse([0, 0, s - 1, s - 1], outline=LINE, width=4)
    d.ellipse([s * 0.18, s * 0.12, s * 0.82, s * 0.80], outline=(255, 200, 0, 255), width=3)
    label(d, (s * 0.24, s * 0.82), "face inside yellow oval", 22)
    image.save(OUT / "template-map-marker-512.png")


def app_icon():
    # 1024 x 1024 icon. iOS rounds the corners; keep faces in the center 80%.
    s = 1024
    image, d = canvas(s, s)
    d.rounded_rectangle([0, 0, s - 1, s - 1], radius=s * 0.2237, outline=LINE, width=4)
    pad = s * 0.10
    d.rectangle([pad, pad, s - pad, s - pad], outline=(255, 200, 0, 255), width=3)
    label(d, (pad + 12, pad + 12), "faces inside center 80%, no text", 30)
    image.save(OUT / "template-app-icon-1024.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    chapter_background()
    story_panel()
    obstacle_tile()
    map_marker()
    app_icon()
    print(f"Templates written to {OUT}")
