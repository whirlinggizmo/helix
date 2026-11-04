#!/usr/bin/env python3
"""Generates the UI art and the sounds for Wardens, the jam's game (see spec.md).

Writes into assets/ beside this file:

  ui/panel.png    96x96 nine-slice panel, margins in ui/slices.txt
  ui/button.png   64x128 nine-slice button sheet, four 64x32 states stacked
  ui/icons.png    384x144 atlas of 48x48 icons, 8 per row, named in ui/icons.txt
  ui/slices.txt   the nine-slice margins and the button's state layout
  ui/icons.txt    one "index name" line per icon, row by row
  sound/slash.wav, shot.wav, hit.wav, gem.wav, level.wav
                  16-bit PCM, 44100 Hz, mono, synthesized
  sound/music.ogg a 24 second seamless loop, Vorbis at about 96 kbps

Everything is drawn or synthesized here from code, so the art and sounds are
the trial's own and contain no third-party content. Seeds are fixed, so a
rerun gives identical files. The characters are not made here (see
assets/README.md).

Run:  python3 gen_assets.py
Needs Python 3, PIL, numpy and ffmpeg (with libvorbis) at /usr/bin/ffmpeg.
"""
import os
import subprocess
import wave

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "assets")
UI = os.path.join(OUT, "ui")
SND = os.path.join(OUT, "sound")
RATE = 44100
FFMPEG = "/usr/bin/ffmpeg"

# ---------------------------------------------------------------- nine-slices


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(len(a)))


def rounded_box(w, h, radius, body_top, body_bot, light, dark, bevel=3.0,
                outline=(12, 14, 20), sat=1.0, ss=4):
    """A rounded box with an outline, a bevel (light top left, dark bottom
    right) and a vertical body gradient. Computed from a signed distance,
    supersampled by ss."""
    W, H = w * ss, h * ss
    ys, xs = np.mgrid[0:H, 0:W]
    px = (xs + 0.5) / ss
    py = (ys + 0.5) / ss
    r = radius
    # distance inside the rounded rectangle (positive inside)
    cx = np.clip(px, r, w - r)
    cy = np.clip(py, r, h - r)
    dist_c = np.hypot(px - cx, py - cy)
    inside = r - dist_c  # positive inside the corner arcs, edge distance elsewhere
    edge = np.minimum(np.minimum(px, w - px), np.minimum(py, h - py))
    d = np.where((px < r) | (px > w - r), np.where((py < r) | (py > h - r), inside, edge), edge)
    d = np.where((py < r) | (py > h - r), np.where((px < r) | (px > w - r), inside, d), d)

    t = py / h
    body = np.array([lerp(body_top, body_bot, tt) for tt in np.linspace(0, 1, 256)])
    body_img = body[np.clip((t * 255).astype(int), 0, 255)]
    # bevel colour runs light (top left) to dark (bottom right)
    s = np.clip((px / w + py / h) / 2.0, 0, 1)
    s = np.clip((s - 0.25) / 0.5, 0, 1)
    lc = np.array(light, float)
    dc = np.array(dark, float)
    bev = lc[None, None, :] * (1 - s[..., None]) + dc[None, None, :] * s[..., None]
    col = np.where((d < 1.0 + bevel)[..., None], bev, body_img)
    col = np.where((d < 1.0)[..., None], np.array(outline, float)[None, None, :], col)
    a = (d > 0).astype(float) * 255
    img = np.dstack([col, a])
    out = Image.fromarray(img.clip(0, 255).astype(np.uint8), "RGBA")
    out = out.resize((w, h), Image.BOX)
    if sat != 1.0:
        arr = np.asarray(out).astype(float)
        g = arr[..., :3].mean(axis=2, keepdims=True)
        arr[..., :3] = g + (arr[..., :3] - g) * sat
        out = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
    return out


def make_panel():
    img = rounded_box(96, 96, 12, (44, 52, 66), (30, 36, 48),
                      (150, 168, 196), (70, 82, 104), bevel=3.0)
    img.save(os.path.join(UI, "panel.png"))


BUTTON_MARGIN = 12


def make_button():
    sheet = Image.new("RGBA", (64, 128), (0, 0, 0, 0))
    # (top, bottom, light, dark, saturation, y offset)
    states = [
        ((70, 84, 108), (46, 56, 76), (170, 188, 214), (84, 98, 124), 1.0, 0),
        ((96, 114, 144), (66, 80, 106), (214, 228, 248), (110, 128, 156), 1.0, 0),
        ((34, 42, 58), (26, 32, 44), (96, 110, 136), (52, 62, 82), 1.0, 1),
        ((60, 64, 72), (50, 53, 60), (110, 114, 122), (72, 75, 82), 0.0, 0),
    ]
    for i, (top, bot, lt, dk, sat, dy) in enumerate(states):
        # The shape is 31 high so a pressed button can move down 1 px inside its cell.
        box = rounded_box(64, 31, 8, top, bot, lt, dk, bevel=2.0, sat=sat)
        sheet.alpha_composite(box, (0, i * 32 + dy))
    sheet.save(os.path.join(UI, "button.png"))


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
    if which == "adventurer":  # mountains and a sun
        c.ell(30, 9, 39, 18, GOLD, OUT)
        c.poly([(5, 38), (18, 14), (31, 38)], (236, 240, 244), OUT)
        c.poly([(20, 38), (31, 22), (43, 38)], (205, 215, 225), OUT)
        c.poly([(13, 24), (18, 14), (23, 24), (18, 22)], WHITE)
    elif which == "casual":  # a t-shirt
        c.poly([(15, 8), (21, 8), (24, 12), (27, 8), (33, 8), (43, 15), (38, 23), (35, 21), (35, 40),
                (13, 40), (13, 21), (10, 23), (5, 15)], WHITE, OUT)
        c.ell(20, 22, 28, 30, (60, 150, 220))
    elif which == "formal":  # a bow tie
        c.poly([(24, 24), (7, 13), (7, 35)], WHITE, OUT)
        c.poly([(24, 24), (41, 13), (41, 35)], WHITE, OUT)
        c.rect(20, 19, 28, 29, (250, 220, 220), r=2, outline=OUT)
    elif which == "medieval":  # a shield
        c.poly([(9, 8), (39, 8), (39, 26), (24, 42), (9, 26)], (220, 224, 232), OUT)
        c.poly([(24, 8), (39, 8), (39, 26), (24, 42)], (190, 40, 40))
        c.poly([(9, 8), (24, 8), (24, 42), (9, 26)], (240, 200, 60))
        c.line([(24, 8), (24, 42)], OUT, 1.2)
    elif which == "punk":  # a mohawk of spikes
        c.rect(8, 34, 40, 41, (30, 30, 36), r=2, outline=OUT)
        for i, x in enumerate((9, 17, 25, 33)):
            h = 14 + (i % 2) * 6
            c.poly([(x, 36), (x + 4, 36 - h - 6), (x + 8, 36)], WHITE, OUT)
    elif which == "scifi":  # an atom ring and core
        c.d.arc([8 * SS, 15 * SS, 40 * SS, 33 * SS], 0, 360, fill=WHITE, width=int(2.2 * SS))
        im = c.im
        # a second, tilted ring
        ring = Image.new("RGBA", im.size, (0, 0, 0, 0))
        rd = ImageDraw.Draw(ring)
        rd.arc([8 * SS, 15 * SS, 40 * SS, 33 * SS], 0, 360, fill=WHITE, width=int(2.2 * SS))
        ring = ring.rotate(60, resample=Image.BICUBIC, center=(24 * SS, 24 * SS))
        im.alpha_composite(ring)
        ring2 = ring.rotate(60, resample=Image.BICUBIC, center=(24 * SS, 24 * SS))
        im.alpha_composite(ring2)
        c.d = ImageDraw.Draw(c.im)
        c.ell(19, 19, 29, 29, (255, 240, 120), OUT)
    elif which == "soldier":  # chevrons and a star
        for y in (8, 15, 22):
            c.line([(10, y + 7), (24, y), (38, y + 7)], OUT, 6.0)
            c.line([(10, y + 7), (24, y), (38, y + 7)], (230, 224, 170), 3.6)
        c.poly([(24, 33), (25.6, 36.6), (29.5, 37), (26.6, 39.6), (27.4, 43.4), (24, 41.4), (20.6, 43.4),
                (21.4, 39.6), (18.5, 37), (22.4, 36.6)], (255, 215, 80), OUT)
    elif which == "suit":  # a necktie on a collar
        c.poly([(8, 8), (24, 20), (40, 8), (42, 40), (6, 40)], WHITE, OUT)
        c.poly([(24, 20), (30, 12), (24, 10), (18, 12)], (36, 54, 128), OUT)
        c.poly([(24, 18), (28, 22), (27, 36), (24, 41), (21, 36), (20, 22)], (200, 50, 60), OUT)
    elif which == "witch":  # a pointed hat
        c.poly([(24, 5), (31, 28), (17, 28)], (40, 24, 60), OUT)
        c.poly([(23, 7), (28, 12), (20, 12)], (60, 40, 90))
        c.rect(19, 21, 29, 26, GOLD)
        c.poly([(5, 36), (10, 28), (38, 28), (43, 36), (24, 40)], (40, 24, 60), OUT)
        c.rect(20, 22, 28, 26, GOLD, outline=OUT)
    elif which == "worker":  # a hard hat
        c.poly([(8, 30), (9, 22), (14, 14), (24, 10), (34, 14), (39, 22), (40, 30)], (255, 224, 70), OUT)
        c.rect(21, 8, 27, 24, (240, 190, 40), outline=OUT)
        c.rect(5, 29, 43, 36, (255, 224, 70), r=3, outline=OUT)
        c.line([(14, 18), (18, 14)], WHITE, 1.4)


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


def make_slices():
    m = BUTTON_MARGIN
    with open(os.path.join(UI, "slices.txt"), "w") as f:
        f.write("# image left top right bottom (pixels), then any notes\n")
        f.write("panel.png 16 16 16 16\n")
        f.write("button.png %d %d %d %d states=4 layout=vertical size=64x32 order=normal,focused,pressed,disabled\n"
                % (m, m, m, m))
        f.write("# Each button state is its own 64x32 cell, nine-sliced with those margins on its own.\n")
        f.write("# The shape fills 31 rows of its cell, so the pressed state's 1 px shift stays inside it.\n")


# --------------------------------------------------------------------- sounds


def write_wav(name, x):
    x = np.asarray(x, float)
    n = int(0.004 * RATE)
    x[-n:] *= np.linspace(1, 0, n)
    x[:8] *= np.linspace(0, 1, 8)
    x = x / np.max(np.abs(x)) * 0.85  # -1.4 dBFS
    pcm = np.round(x * 32767).astype("<i2")
    with wave.open(os.path.join(SND, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def tt(sec):
    return np.arange(int(sec * RATE)) / RATE


def lowpass(x, cutoff):
    """One-pole low pass with a per-sample cutoff in Hz."""
    a = 1 - np.exp(-2 * np.pi * cutoff / RATE)
    y = np.zeros_like(x)
    s = 0.0
    for i in range(len(x)):
        s += a[i] * (x[i] - s)
        y[i] = s
    return y


def slash(rng):
    t = tt(0.28)
    u = t / t[-1]
    noise = rng.standard_normal(len(t))
    cut = 400 + 5200 * np.sin(np.pi * u) ** 1.5
    y = lowpass(lowpass(noise, cut), cut * 1.5)
    env = np.sin(np.pi * u) ** 1.6 * (1 - 0.3 * u)
    return y * env


def shot(rng):
    t = tt(0.2)
    f = 200 + 1500 * np.exp(-t * 22)
    ph = 2 * np.pi * np.cumsum(f) / RATE
    y = np.sin(ph) + 0.35 * np.sign(np.sin(ph)) * 0.5
    y *= np.exp(-t * 14)
    click = rng.standard_normal(len(t)) * np.exp(-t * 400) * 0.5
    return y + click


def hit(rng):
    t = tt(0.24)
    f = 48 + 90 * np.exp(-t * 30)
    ph = 2 * np.pi * np.cumsum(f) / RATE
    body = np.sin(ph) * np.exp(-t * 14)
    n = lowpass(rng.standard_normal(len(t)), np.full(len(t), 900.0)) * np.exp(-t * 45)
    return body + 0.7 * n


def bell(t, f, decay):
    return (np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * f * 2.01 * t)
            + 0.12 * np.sin(2 * np.pi * f * 3.02 * t)) * np.exp(-t * decay)


def gem(rng):
    y = np.zeros(int(0.5 * RATE))
    for start, f in ((0.0, 1318.5), (0.09, 1975.5)):
        i = int(start * RATE)
        seg = tt(0.5 - start)
        y[i:] += bell(seg, f, 7.0) * np.minimum(1, seg * 1000)
    return y


def level(rng):
    notes = [523.25, 659.25, 783.99, 1046.5, 1318.5]
    y = np.zeros(int(0.95 * RATE))
    for k, f in enumerate(notes):
        i = int(k * 0.085 * RATE)
        seg = tt(0.95) [: len(y) - i]
        amp = 0.7 + 0.1 * k
        y[i:] += amp * (np.sin(2 * np.pi * f * seg) * 0.8 + 0.25 * np.sin(2 * np.pi * f * 2 * seg)) \
            * np.exp(-seg * (5.0 if k < 4 else 3.0)) * np.minimum(1, seg * 800)
    return y


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def make_music():
    bpm = 120
    beat = 60.0 / bpm
    bars = 12
    total = bars * 4 * beat  # 24 s
    N = int(round(total * RATE))
    mix = np.zeros(N)

    def add(start, sig):
        """Adds sig at start seconds, wrapping around the end so the loop is seamless."""
        i = int(round(start * RATE))
        idx = (i + np.arange(len(sig))) % N
        np.add.at(mix, idx, sig)

    # Am, F, Dm, E per four bars, three times: a minor key with a major dominant.
    chords = [
        (57, [0, 3, 7]),   # A minor (root MIDI 57)
        (53, [0, 4, 7]),   # F major
        (50, [0, 3, 7]),   # D minor
        (52, [0, 4, 7]),   # E major
    ]
    rng = np.random.default_rng(7)
    pattern = [0, 1, 2, 3, 2, 1, 2, 1]  # eighth notes up and down the chord plus its octave
    for bar in range(bars):
        root, ints = chords[bar % 4]
        tones = [root + 12 + i for i in ints] + [root + 24]
        t0 = bar * 4 * beat
        # arpeggio, two notes of a pluck every beat
        for k in range(8):
            f = midi(tones[pattern[k]])
            seg = tt(0.7)
            pl = (np.sin(2 * np.pi * f * seg) + 0.4 * np.sin(2 * np.pi * 2 * f * seg)
                  + 0.2 * np.sin(2 * np.pi * 3 * f * seg)) * np.exp(-seg * 6.5)
            pl *= np.minimum(1, seg * 600)
            add(t0 + k * beat / 2, 0.20 * pl)
        # bass, root on 1 and 3, fifth on 4
        for k, (off, note) in enumerate(((0, root - 12), (1.5, root - 12), (2, root - 12), (3, root - 5))):
            f = midi(note)
            dur = 0.9 * beat if k != 1 else 0.45 * beat
            seg = tt(dur)
            env = np.minimum(1, seg * 200) * np.minimum(1, (dur - seg) * 100) * np.exp(-seg * 2.0)
            add(t0 + off * beat, 0.42 * (np.sin(2 * np.pi * f * seg) + 0.3 * np.sin(4 * np.pi * f * seg)) * env)
        # a soft pad of the chord's tones, held the bar
        seg = tt(4 * beat)
        env = np.minimum(1, seg * 3) * np.minimum(1, (4 * beat - seg) * 3)
        for i in ints:
            f = midi(root + 12 + i)
            add(t0, 0.05 * np.sin(2 * np.pi * f * seg) * env)
    # a quiet hat on the off beats
    for k in range(bars * 8):
        seg = tt(0.04)
        h = rng.standard_normal(len(seg)) * np.exp(-seg * 120)
        h = np.diff(np.concatenate([[0], h]))
        add(k * beat + beat / 2 * (k % 2), 0.05 * h)
    mix = mix / np.max(np.abs(mix)) * 0.7  # leaves room for Vorbis overshoot
    pcm = np.round(mix * 32767).astype("<i2")
    tmp = os.path.join(SND, "_music.wav")
    with wave.open(tmp, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    out = os.path.join(SND, "music.ogg")
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis",
                    "-b:a", "96k", "-fflags", "+bitexact", "-flags:a", "+bitexact",
                    "-map_metadata", "-1", "-serial_offset", "1", out], check=True)
    os.remove(tmp)


def main():
    os.makedirs(UI, exist_ok=True)
    os.makedirs(SND, exist_ok=True)
    make_panel()
    make_button()
    make_icons()
    make_slices()
    rng = np.random.default_rng(1)
    for name, fn in (("slash.wav", slash), ("shot.wav", shot), ("hit.wav", hit),
                     ("gem.wav", gem), ("level.wav", level)):
        write_wav(name, fn(rng))
    make_music()


if __name__ == "__main__":
    main()
