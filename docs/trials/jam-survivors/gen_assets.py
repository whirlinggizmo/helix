#!/usr/bin/env python3
"""Generates the icon atlas for Wardens, the jam's game (see spec.md).

Writes into assets/ui/ beside this file:

  icons.png  384x144 atlas of 48x48 icons, 8 per row
  icons.txt  one "index name" line per icon, row by row

Kenney's Game Icons are generic interface symbols and have no sword, gun, bullet, outfit
or armor-slot pictures, so these are drawn here from code, but for the outfits: each is a portrait of the warden in it,
rendered in Blender from the outfit's four parts by render_outfits.py into icon-sources/outfits/. Everything else in assets/ is
third-party and credited in assets/CREDITS.md. The art is the trial's own.

Run:  python3 gen_assets.py
Needs Python 3, PIL and numpy.
"""
import os

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
UI = os.path.join(HERE, "assets", "ui")


# ---------------------------------------------------------------------- icons

ICON = 48
SS = 4
ICON_NAMES = (
    ["sharper_blade", "quick_hands", "long_reach", "gun", "more_bullets"]
    + ["outfit_" + n for n in ("adventurer", "casual", "formal", "medieval", "punk",
                               "scifi", "soldier", "suit", "witch", "worker")]
    + ["slot_head", "slot_body", "slot_legs", "slot_feet"]
    + ["weapon_sword", "weapon_gun"]
)

WHITE = (248, 248, 250)
STEEL = (200, 214, 230)
STEEL_D = (120, 138, 160)
BROWN = (130, 82, 40)
GOLD = (245, 200, 70)
OUT = (14, 16, 24)
SLATE = (46, 56, 74)
SLATE_HI = (128, 146, 176)


class Canvas:
    """A 48x48 icon drawn at 4x in 48-unit coordinates."""

    def __init__(self):
        self.im = Image.new("RGBA", (ICON * SS, ICON * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def pts(self, p):
        return [(x * SS, y * SS) for x, y in p]

    def poly(self, p, fill, outline=None):
        self.d.polygon(self.pts(p), fill=fill)
        if outline:
            q = self.pts(p) + [self.pts(p)[0]]
            self.d.line(q, fill=outline, width=int(1.2 * SS), joint="curve")

    def rect(self, x0, y0, x1, y1, fill, r=0, outline=None):
        self.d.rounded_rectangle([x0 * SS, y0 * SS, x1 * SS, y1 * SS], radius=r * SS,
                                 fill=fill, outline=outline, width=int(1.2 * SS))

    def ell(self, x0, y0, x1, y1, fill, outline=None):
        self.d.ellipse([x0 * SS, y0 * SS, x1 * SS, y1 * SS], fill=fill,
                       outline=outline, width=int(1.2 * SS))

    def line(self, p, fill, w):
        self.d.line(self.pts(p), fill=fill, width=int(w * SS), joint="curve")

    def plate(self, fill, edge=None):
        """The rounded plate every icon sits on."""
        top = tuple(min(255, int(c * 1.18 + 8)) for c in fill)
        self.rect(1.5, 1.5, 46.5, 46.5, OUT, r=9)
        self.rect(2.5, 2.5, 45.5, 45.5, edge or tuple(min(255, int(c * 1.5 + 30)) for c in fill), r=8)
        self.rect(4, 4, 44, 44, fill, r=7)
        self.rect(4, 4, 44, 22, top, r=7)
        self.rect(4, 14, 44, 24, fill)
        self.rect(4, 22, 44, 44, fill, r=7)
        self.rect(4, 14, 44, 30, fill)

    def done(self):
        return self.im.resize((ICON, ICON), Image.LANCZOS)


def sword(c, x0=10, y0=38, x1=36, y1=12, w=4.0):
    """A sword from the hilt (x0,y0) to the tip (x1,y1)."""
    dx, dy = x1 - x0, y1 - y0
    n = (dx * dx + dy * dy) ** 0.5
    ux, uy = dx / n, dy / n
    nx, ny = -uy, ux
    gx, gy = x0 + ux * 7, y0 + uy * 7  # guard position
    # grip and pommel
    c.line([(x0, y0), (gx, gy)], OUT, 4.2)
    c.line([(x0, y0), (gx, gy)], BROWN, 2.6)
    c.ell(x0 - 2.4, y0 - 2.4, x0 + 2.4, y0 + 2.4, GOLD, OUT)
    # blade
    tipx, tipy = x1, y1
    bl = [(gx + nx * w / 2, gy + ny * w / 2), (gx - nx * w / 2, gy - ny * w / 2),
          (tipx - nx * w / 2 - ux * 0.5, tipy - ny * w / 2 - uy * 0.5),
          (tipx + ux * 3, tipy + uy * 3),
          (tipx + nx * w / 2 - ux * 0.5, tipy + ny * w / 2 - uy * 0.5)]
    c.poly(bl, STEEL, OUT)
    c.line([(gx + ux * 1.5, gy + uy * 1.5), (tipx - ux * 1, tipy - uy * 1)], WHITE, 1.0)
    # guard
    c.line([(gx + nx * 6, gy + ny * 6), (gx - nx * 6, gy - ny * 6)], OUT, 4.4)
    c.line([(gx + nx * 5.5, gy + ny * 5.5), (gx - nx * 5.5, gy - ny * 5.5)], GOLD, 2.6)


def gun(c, scale=1.0, ox=0, oy=0, col=(70, 78, 92)):
    def T(p):
        return [(ox + 24 + (x - 24) * scale, oy + 24 + (y - 24) * scale) for x, y in p]
    body = T([(8, 17), (38, 17), (40, 20), (40, 25), (28, 25), (26, 33), (24, 36), (17, 36),
              (19, 25), (8, 25)])
    c.poly(body, col, OUT)
    c.poly(T([(10, 18.5), (37, 18.5), (37, 20.5), (10, 20.5)]), (150, 162, 182))
    c.poly(T([(22, 26), (27, 26), (25.5, 31), (21, 31)]), (46, 52, 64))
    c.poly(T([(40, 20), (44, 20), (44, 24), (40, 24)]), (40, 44, 54), OUT)


def make_icon(name):
    c = Canvas()
    # ---- cards
    if name == "sharper_blade":
        c.plate((60, 80, 128))
        sword(c)
        for (sx, sy, r) in ((35, 35, 4.5), (13, 14, 3.2)):  # sparkles
            c.poly([(sx, sy - r), (sx + r * .3, sy - r * .3), (sx + r, sy), (sx + r * .3, sy + r * .3),
                    (sx, sy + r), (sx - r * .3, sy + r * .3), (sx - r, sy), (sx - r * .3, sy - r * .3)],
                   GOLD, OUT)
    elif name == "quick_hands":
        c.plate((150, 110, 30))
        c.poly([(27, 6), (12, 26), (22, 26), (18, 42), (36, 20), (26, 20), (31, 6)], (255, 226, 80), OUT)
        c.line([(6, 18), (11, 18)], WHITE, 1.8)
        c.line([(5, 26), (9, 26)], WHITE, 1.8)
        c.line([(37, 32), (42, 32)], WHITE, 1.8)
    elif name == "long_reach":
        c.plate((40, 110, 100))
        c.line([(10, 24), (38, 24)], OUT, 5.5)
        c.line([(10, 24), (38, 24)], WHITE, 3.0)
        c.poly([(5, 24), (14, 17), (14, 31)], WHITE, OUT)
        c.poly([(43, 24), (34, 17), (34, 31)], WHITE, OUT)
        c.line([(6, 36), (6, 42)], WHITE, 2.2)
        c.line([(42, 36), (42, 42)], WHITE, 2.2)
        c.line([(6, 39), (42, 39)], WHITE, 1.6)
        c.line([(24, 8), (24, 14)], WHITE, 2.0)
    elif name == "gun":
        c.plate((120, 60, 60))
        gun(c, 1.0, 0, 0)
        c.ell(9, 38, 13, 42, (255, 190, 60))
    elif name == "more_bullets":
        c.plate((110, 74, 40))
        for i, x in enumerate((13, 24, 35)):
            y = 8 + (0 if i == 1 else 4)
            c.poly([(x - 4, y + 10), (x - 4, y + 4), (x - 2.5, y + 1), (x, y - 1.5), (x + 2.5, y + 1),
                    (x + 4, y + 4), (x + 4, y + 10)], (255, 210, 90), OUT)
            c.rect(x - 4, y + 10, x + 4, y + 25, (214, 150, 50), outline=OUT)
            c.rect(x - 4, y + 24, x + 4, y + 29, (150, 100, 40), outline=OUT)
            c.line([(x - 1.5, y + 4), (x - 1.5, y + 23)], WHITE, 1.0)
    # ---- outfits
    elif name.startswith("outfit_"):
        outfit(c, name[7:])
    # ---- slots
    elif name == "slot_head":
        c.plate((70, 84, 110))
        c.ell(13, 8, 35, 32, (240, 200, 160), OUT)
        c.poly([(11, 20), (13, 12), (24, 6), (35, 12), (37, 20), (35, 22), (35, 17), (24, 14), (13, 17),
                (13, 22)], STEEL, OUT)
        c.rect(19, 30, 29, 40, (240, 200, 160), outline=OUT)
        c.line([(24, 8), (24, 14)], STEEL_D, 1.5)
    elif name == "slot_body":
        c.plate((70, 84, 110))
        c.poly([(15, 8), (21, 8), (24, 12), (27, 8), (33, 8), (43, 14), (39, 22), (35, 20), (35, 41),
                (13, 41), (13, 20), (9, 22), (5, 14)], (110, 170, 230), OUT)
        c.line([(24, 12), (24, 40)], (70, 120, 190), 1.5)
    elif name == "slot_legs":
        c.plate((70, 84, 110))
        c.poly([(13, 7), (35, 7), (37, 41), (27, 41), (24, 20), (21, 41), (11, 41)], (110, 170, 230), OUT)
        c.rect(13, 7, 35, 12, (70, 120, 190), outline=OUT)
    elif name == "slot_feet":
        c.plate((70, 84, 110))
        c.poly([(12, 8), (24, 8), (24, 26), (40, 30), (41, 38), (10, 38)], (110, 170, 230), OUT)
        c.rect(10, 36, 41, 41, (60, 70, 90), outline=OUT)
        c.line([(14, 12), (23, 12)], (70, 120, 190), 1.5)
    # ---- weapons
    elif name == "weapon_sword":
        c.plate((60, 70, 96))
        sword(c)
    elif name == "weapon_gun":
        c.plate((60, 70, 96))
        gun(c, 1.0, 0, 0, col=(96, 106, 124))
    return c.done()


def outfit(c, which):
    cols = {
        "adventurer": (52, 140, 66), "casual": (60, 150, 220), "formal": (168, 36, 58),
        "medieval": (150, 96, 44), "punk": (214, 40, 150), "scifi": (24, 178, 186),
        "soldier": (92, 104, 46), "suit": (36, 54, 128), "witch": (118, 58, 168),
        "worker": (238, 134, 24),
    }
    c.plate(cols[which])
    # Her portrait in the outfit, rendered from its four parts by render_outfits.py, its head and shoulders inside the plate.
    name = {"scifi": "SciFi"}.get(which, which.capitalize())
    shot = Image.open(os.path.join(HERE, "icon-sources", "outfits", name + ".png")).convert("RGBA")
    shot = shot.crop((20, 0, 108, 88)).resize((40 * SS, 40 * SS), Image.LANCZOS)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, shot.size[0] - 1, shot.size[1] - 1], radius=7 * SS, fill=255)
    alpha = Image.fromarray((np.asarray(shot.getchannel("A"), dtype=np.uint16) * np.asarray(mask) // 255).astype(np.uint8))
    shot.putalpha(alpha)
    c.im.alpha_composite(shot, (4 * SS, 4 * SS))


def make_icons():
    cols = 8
    rows = (len(ICON_NAMES) + cols - 1) // cols
    atlas = Image.new("RGBA", (cols * ICON, rows * ICON), (0, 0, 0, 0))
    for i, n in enumerate(ICON_NAMES):
        atlas.alpha_composite(make_icon(n), ((i % cols) * ICON, (i // cols) * ICON))
    atlas.save(os.path.join(UI, "icons.png"))
    with open(os.path.join(UI, "icons.txt"), "w") as f:
        for i, n in enumerate(ICON_NAMES):
            f.write("%d %s\n" % (i, n))


def main():
    os.makedirs(UI, exist_ok=True)
    make_icons()


if __name__ == "__main__":
    main()
