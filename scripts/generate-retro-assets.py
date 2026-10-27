#!/usr/bin/env python3
"""Generate the desktop-scene assets for the retro labwc rice.

Everything here is original, deterministic pixel art.  The circuit tile is
seamless and is also expanded to a 1920x1080 wallpaper for swaybg.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "quickshell" / "assets"
WALLPAPERS = Path.home() / "Pictures"

BASE = (105, 126, 143)
DARK = (62, 80, 94)
MID = (82, 102, 118)
LIGHT = (139, 158, 173)
HILITE = (177, 193, 205)
SHADOW = (45, 61, 74)


def circuit_tile(size: int = 384, cell: int = 64) -> Image.Image:
    """A seamless blue-grey circuit-board tile."""
    rng = random.Random(37)
    img = Image.new("RGB", (size, size), BASE)
    draw = ImageDraw.Draw(img)

    # Continuous copper-ish traces.  Keeping these on a fixed grid makes the
    # tile wrap cleanly at every edge.
    for y in range(0, size, cell // 2):
        shade = DARK if (y // (cell // 2)) % 2 == 0 else MID
        draw.line((0, y, size, y), fill=shade, width=1)
        if y % cell == 0:
            draw.line((0, y + 2, size, y + 2), fill=LIGHT, width=1)
    for x in range(0, size, cell // 2):
        shade = DARK if (x // (cell // 2)) % 2 == 0 else MID
        draw.line((x, 0, x, size), fill=shade, width=1)
        if x % cell == 0:
            draw.line((x + 2, 0, x + 2, size), fill=LIGHT, width=1)

    # A subtle repeating grid of vias.
    for gy in range(0, size, cell // 2):
        for gx in range(0, size, cell // 2):
            if (gx // 32 + gy // 32) % 3 == 0:
                draw.rectangle((gx + 5, gy + 5, gx + 10, gy + 10), fill=DARK)
                draw.rectangle((gx + 6, gy + 6, gx + 9, gy + 9), fill=HILITE)
                draw.point((gx + 8, gy + 8), fill=SHADOW)

    # Chip dies, one per cell, with offset traces and pins.
    for cy in range(0, size, cell):
        for cx in range(0, size, cell):
            w = rng.choice((32, 36, 40, 44, 48))
            h = rng.choice((28, 32, 36, 40, 44))
            # Keep every chip inside its cell so the pattern wraps by cell.
            x = cx + (cell - w) // 2
            y = cy + (cell - h) // 2

            # Trace tails from the chip to the cell edges.
            mid_y = y + h // 2
            mid_x = x + w // 2
            draw.line((cx, mid_y, x, mid_y), fill=DARK, width=2)
            draw.line((x + w, mid_y, cx + cell, mid_y), fill=DARK, width=2)
            draw.line((mid_x, cy, mid_x, y), fill=DARK, width=2)
            draw.line((mid_x, y + h, mid_x, cy + cell), fill=DARK, width=2)

            # Pins around the package.
            for px in range(x + 4, x + w - 3, 5):
                draw.line((px, y - 3, px, y), fill=DARK, width=1)
                draw.line((px, y + h, px, y + h + 3), fill=DARK, width=1)
            for py in range(y + 4, y + h - 3, 5):
                draw.line((x - 3, py, x, py), fill=DARK, width=1)
                draw.line((x + w, py, x + w + 3, py), fill=DARK, width=1)

            # Package body: shadow, outline, fill, inner highlight.
            draw.rectangle((x - 1, y - 1, x + w, y + h), fill=SHADOW)
            draw.rectangle((x, y, x + w - 1, y + h - 1), fill=MID, outline=DARK)
            draw.rectangle((x + 3, y + 3, x + w - 4, y + h - 4), fill=(73, 92, 108))
            draw.rectangle((x + 3, y + 3, x + w - 4, y + 5), fill=LIGHT)
            draw.rectangle((x + 3, y + h - 6, x + w - 4, y + h - 4), fill=SHADOW)
            draw.rectangle((x + 3, y + 3, x + 5, y + h - 4), fill=LIGHT)
            draw.rectangle((x + w - 6, y + 3, x + w - 4, y + h - 4), fill=DARK)

            # Small identifying marks on the die.
            for _ in range(3):
                mx = x + rng.randint(7, max(8, w - 9))
                my = y + rng.randint(8, max(9, h - 10))
                draw.rectangle((mx, my, mx + rng.randint(2, 6), my + 2), fill=HILITE)
            draw.rectangle((x + w - 11, y + h - 11, x + w - 8, y + h - 8), fill=(190, 204, 214))
            draw.rectangle((x + w - 10, y + h - 10, x + w - 9, y + h - 9), fill=SHADOW)

    return img


def upscale(im: Image.Image, factor: int) -> Image.Image:
    return im.resize((im.width * factor, im.height * factor), Image.Resampling.NEAREST)


def icon_base(size: int = 32) -> Image.Image:
    return Image.new("RGBA", (size, size), (0, 0, 0, 0))


def draw_folder(draw: ImageDraw.ImageDraw) -> None:
    # Old-school blue-grey folder with a warm paper tab.
    draw.rectangle((3, 9, 29, 28), fill=(43, 61, 76), outline=(18, 28, 38))
    draw.rectangle((3, 12, 29, 28), fill=(92, 132, 164), outline=(18, 28, 38))
    draw.rectangle((5, 8, 17, 13), fill=(71, 105, 133), outline=(18, 28, 38))
    draw.rectangle((5, 14, 27, 26), fill=(124, 164, 194))
    draw.rectangle((6, 15, 26, 16), fill=(176, 203, 220))
    draw.rectangle((8, 19, 24, 23), fill=(92, 132, 164))
    draw.rectangle((11, 20, 21, 22), fill=(207, 222, 232))


def draw_computer(draw: ImageDraw.ImageDraw) -> None:
    # Chunky CRT with a blue screen.
    draw.rectangle((2, 4, 30, 22), fill=(36, 48, 58), outline=(14, 22, 30))
    draw.rectangle((4, 6, 28, 19), fill=(86, 106, 118))
    draw.rectangle((6, 8, 26, 17), fill=(24, 73, 98), outline=(11, 33, 48))
    draw.rectangle((8, 10, 24, 11), fill=(71, 154, 181))
    draw.rectangle((8, 13, 19, 14), fill=(125, 196, 213))
    draw.rectangle((20, 15, 23, 16), fill=(224, 239, 243))
    draw.rectangle((11, 23, 21, 26), fill=(66, 78, 88), outline=(18, 28, 36))
    draw.rectangle((7, 27, 25, 29), fill=(112, 126, 136), outline=(18, 28, 36))
    draw.rectangle((9, 28, 23, 28), fill=(170, 184, 193))
    draw.rectangle((16, 22, 17, 23), fill=(30, 40, 48))


def draw_trash(draw: ImageDraw.ImageDraw) -> None:
    # Metal bin with a lid and a few paper scraps.
    draw.rectangle((8, 8, 24, 11), fill=(98, 112, 124), outline=(22, 31, 40))
    draw.rectangle((11, 5, 21, 8), fill=(70, 84, 96), outline=(22, 31, 40))
    draw.rectangle((15, 4, 17, 5), fill=(174, 188, 198))
    draw.rectangle((9, 12, 23, 28), fill=(75, 89, 101), outline=(22, 31, 40))
    draw.rectangle((10, 13, 13, 27), fill=(112, 128, 140))
    draw.rectangle((15, 13, 17, 27), fill=(52, 66, 78))
    draw.rectangle((19, 13, 22, 27), fill=(112, 128, 140))
    draw.rectangle((11, 16, 13, 17), fill=(216, 225, 231))
    draw.rectangle((18, 21, 21, 22), fill=(216, 225, 231))
    draw.line((8, 30, 24, 30), fill=(19, 28, 36), width=2)


def draw_books(draw: ImageDraw.ImageDraw) -> None:
    # Three stacked books, with the top one open.
    draw.rectangle((4, 22, 28, 28), fill=(38, 59, 84), outline=(15, 24, 34))
    draw.rectangle((6, 23, 26, 25), fill=(107, 153, 184))
    draw.rectangle((6, 26, 26, 27), fill=(217, 228, 233))
    draw.rectangle((5, 16, 27, 22), fill=(91, 45, 57), outline=(15, 24, 34))
    draw.rectangle((7, 17, 25, 19), fill=(180, 76, 91))
    draw.rectangle((7, 20, 25, 21), fill=(226, 203, 194))
    draw.rectangle((7, 10, 17, 16), fill=(62, 82, 62), outline=(15, 24, 34))
    draw.rectangle((16, 10, 26, 16), fill=(70, 91, 70), outline=(15, 24, 34))
    draw.rectangle((9, 12, 15, 13), fill=(188, 209, 173))
    draw.rectangle((18, 12, 24, 13), fill=(188, 209, 173))
    draw.line((16, 10, 16, 16), fill=(15, 24, 34))
    draw.rectangle((13, 6, 14, 10), fill=(218, 190, 91))
    draw.rectangle((18, 6, 19, 10), fill=(218, 190, 91))


def companion_sprite() -> Image.Image:
    """An original 64x80 sitting pixel companion, scaled 2x for display."""
    w, h = 64, 80
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    outline = (43, 27, 51, 255)
    hair_dark = (67, 32, 84, 255)
    hair = (105, 49, 128, 255)
    hair_light = (151, 83, 173, 255)
    skin = (243, 202, 185, 255)
    skin_dark = (210, 154, 148, 255)
    jacket = (174, 40, 60, 255)
    jacket_dark = (122, 27, 44, 255)
    jacket_light = (225, 91, 107, 255)
    skirt = (42, 31, 52, 255)
    skirt_light = (72, 54, 86, 255)
    boot = (27, 23, 36, 255)
    boot_light = (72, 58, 80, 255)
    white = (247, 238, 232, 255)

    def rect(x1, y1, x2, y2, color, outline=None):
        d.rectangle((x1, y1, x2, y2), fill=color, outline=outline)

    # Ground shadow.
    d.ellipse((8, 72, 56, 79), fill=(20, 18, 26, 80))

    # Hair mass and side locks.
    d.ellipse((18, 8, 46, 36), fill=outline)
    d.ellipse((20, 10, 44, 34), fill=hair_dark)
    d.ellipse((22, 12, 42, 31), fill=hair)
    rect(18, 26, 23, 45, hair_dark)
    rect(41, 26, 46, 45, hair_dark)
    rect(20, 28, 22, 42, hair)
    rect(42, 28, 44, 42, hair)
    rect(23, 12, 32, 14, hair_light)
    rect(34, 12, 40, 13, hair_light)

    # Face.
    d.ellipse((24, 18, 40, 34), fill=skin)
    rect(25, 20, 39, 28, skin)
    rect(24, 24, 40, 28, skin)
    rect(38, 26, 40, 30, skin_dark)
    rect(26, 28, 27, 29, (229, 164, 158, 255))

    # Eyes and brows.
    rect(27, 24, 28, 26, outline)
    rect(36, 24, 37, 26, outline)
    rect(27, 24, 27, 24, white)
    rect(36, 24, 36, 24, white)
    rect(29, 29, 31, 29, (160, 88, 96, 255))
    rect(26, 22, 29, 22, outline)
    rect(34, 22, 37, 22, outline)

    # Hair bangs over the forehead.
    rect(23, 18, 25, 24, hair)
    rect(26, 17, 30, 20, hair)
    rect(31, 17, 34, 19, hair_light)
    rect(35, 18, 40, 21, hair)
    rect(38, 20, 41, 25, hair_dark)

    # Torso and jacket.
    d.polygon(
        [(21, 34), (43, 34), (45, 51), (19, 51)],
        fill=jacket,
        outline=outline,
    )
    rect(22, 35, 42, 36, jacket_light)
    rect(27, 34, 37, 45, white)
    d.polygon([(30, 34), (34, 34), (32, 43)], fill=(216, 199, 193, 255))
    rect(32, 36, 33, 43, jacket_dark)

    # Arms, ending in hands on the knees.
    d.polygon(
        [(19, 37), (24, 38), (20, 55), (15, 55)],
        fill=jacket_dark,
        outline=outline,
    )
    d.polygon(
        [(43, 37), (39, 38), (45, 55), (50, 55)],
        fill=jacket_dark,
        outline=outline,
    )
    rect(14, 53, 20, 58, skin, outline=outline)
    rect(44, 53, 50, 58, skin, outline=outline)
    rect(16, 54, 19, 55, skin_dark)
    rect(45, 54, 48, 55, skin_dark)

    # Skirt.
    d.polygon(
        [(20, 49), (44, 49), (47, 60), (17, 60)],
        fill=skirt,
        outline=outline,
    )
    rect(22, 51, 42, 53, skirt_light)
    for x in (24, 30, 36, 42):
        rect(x, 54, x, 59, (61, 45, 72, 255))

    # Bent legs: thighs then boots.
    d.polygon(
        [(17, 58), (29, 57), (31, 65), (15, 66)],
        fill=skirt,
        outline=outline,
    )
    d.polygon(
        [(44, 58), (32, 57), (30, 65), (46, 66)],
        fill=skirt,
        outline=outline,
    )
    rect(19, 65, 29, 73, skin, outline=outline)
    rect(33, 65, 43, 73, skin, outline=outline)
    rect(20, 66, 28, 68, skin_dark)
    rect(34, 66, 42, 68, skin_dark)

    # Boots.
    d.polygon(
        [(16, 72), (29, 72), (29, 78), (14, 78)],
        fill=boot,
        outline=outline,
    )
    d.polygon(
        [(33, 72), (46, 72), (48, 78), (33, 78)],
        fill=boot,
        outline=outline,
    )
    rect(17, 73, 27, 74, boot_light)
    rect(34, 73, 44, 74, boot_light)
    rect(14, 77, 29, 78, outline)
    rect(33, 77, 49, 78, outline)

    # Small hair highlights.
    rect(22, 15, 24, 16, hair_light)
    rect(26, 14, 27, 15, hair_light)
    rect(42, 31, 43, 34, hair_light)

    return upscale(im, 2)


def main() -> None:
    ASSETS.mkdir(parents=True, exist_ok=True)
    WALLPAPERS.mkdir(parents=True, exist_ok=True)

    tile = circuit_tile()
    tile.save(ASSETS / "circuit-tile.png")

    wallpaper = Image.new("RGB", (1920, 1080), BASE)
    for y in range(0, 1080, tile.height):
        for x in range(0, 1920, tile.width):
            wallpaper.paste(tile, (x, y))
    wallpaper.save(ASSETS / "wallpaper-circuit.png")
    wallpaper.save(WALLPAPERS / "wallpaper-circuit.png")

    for name, draw_fn in (
        ("home", draw_folder),
        ("trash", draw_trash),
        ("computer", draw_computer),
        ("books", draw_books),
    ):
        base = icon_base()
        draw_fn(ImageDraw.Draw(base))
        upscale(base, 4).save(ASSETS / f"icon-{name}.png")

    companion_sprite().save(ASSETS / "companion.png")
    print("wrote assets to", ASSETS)


if __name__ == "__main__":
    main()
