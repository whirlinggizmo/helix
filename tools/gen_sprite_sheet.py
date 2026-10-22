"""The examples' sprite sheet, examples/assets/sheets/gizmos.png and gizmos.json, where they're committed (the sprite-sheet and platformer
examples draw it): a blob walking (six frames of low hops, squashed landing, stretched pushing off, its pivot at its feet), in the air (rising,
falling) and standing (twenty frames, breathing and blinking), and a gear of six teeth turning (eight frames, one tooth red), each 24 x 24 texels, drawn here as pixel art and packed as TexturePacker packs: trimmed to what isn't transparent, some frames turned a quarter turn
clockwise, written as its JSON Hash.

  python3 tools/gen_sprite_sheet.py"""
import json
import math
from pathlib import Path
import struct
import zlib

SIZE = 24
GAP = 2
WIDTH = 128
# The frames packed turned, to prove a reader draws them upright.
ROTATED = {'walk_02.png', 'walk_05.png', 'idle_07.png', 'gear_03.png', 'gear_07.png'}


def body(squash, bottom, open_eyes=True):
    """The blob: an ellipse whose bottom is at bottom, squashed (squash 1, wide and low) or stretched (-1, narrow and tall), its eyes on its
    right (which way it faces, and which way is up), shut to a dark line when not open_eyes. Its outline is a texel wide all round, with no
    texel jutting out of it alone."""
    w, h = 8 + 2 * squash, 7.5 - 2.5 * squash
    cx = 11.5
    cy = bottom - h
    inside = {(x, y) for y in range(SIZE) for x in range(SIZE) if ((x + .5 - cx) / w) ** 2 + ((y + .5 - cy) / h) ** 2 <= 1}
    near = ((1, 0), (-1, 0), (0, 1), (0, -1))
    # A texel on the ellipse's widest row or column with one neighbour inside sticks out alone: dropped.
    while True:
        alone = {(x, y) for x, y in inside if sum((x + dx, y + dy) in inside for dx, dy in near) <= 1}
        if not alone:
            break
        inside -= alone
    pixels = {(x, y): (0x2e, 0x8b, 0x57) if any((x + dx, y + dy) not in inside for dx, dy in near) else (0x5f, 0xd0, 0x7a)
              for x, y in inside}
    ey = round(cy - h * .25)
    for ex in (round(cx + w * .15), round(cx + w * .55)):
        for dy in (0, 1):
            if (ex, ey + dy) in pixels and (open_eyes or dy == 1):
                pixels[(ex, ey + dy)] = (0xff, 0xff, 0xff) if dy == 0 else (0x10, 0x10, 0x20)
    return pixels


# The walk, a frame a tenth of a second: how high it is off the ground and how squashed, landing squashed, pushing off stretched.
WALK = [(0, .6), (0, .2), (1, -.4), (2, -.2), (1, 0), (0, .3)]


def walk(k):
    """The blob walking, frame k of WALK: low hops, on the ground half the time."""
    rise, squash = WALK[k]
    return body(squash, 24 - rise)


def jump(k):
    """The blob in the air, its body's own motion carrying it: rising stretched (frame 0), falling rounder (frame 1)."""
    return body(-.6 if k == 0 else -.2, 24)


IDLE = 20


def idle(k):
    """The blob standing, frame k of IDLE (two seconds at a tenth each): breathing, a texel up and down, and blinking near the end."""
    breath = math.sin(2 * math.pi * k / IDLE)
    return body(-.2 * breath, 24, k not in (IDLE - 3, IDLE - 2))


def gear(k):
    """The gear's frame k of 8: six teeth turned k eighths of a turn, its first tooth red."""
    cx = cy = 11.5
    turn = k / 8 * 2 * math.pi
    pixels = {}
    for y in range(SIZE):
        for x in range(SIZE):
            dx, dy = x + .5 - cx, y + .5 - cy
            r = math.hypot(dx, dy)
            a = (math.atan2(dy, dx) - turn) % (2 * math.pi)
            # Where in its tooth's sixth of the turn it is, 0 at the tooth's middle.
            part = (a / (2 * math.pi) * 6 + .5) % 1 - .5
            on_tooth = abs(part) < .22
            if 3.5 <= r <= (11.5 if on_tooth else 8.5):
                if on_tooth and r > 8 and (a < math.pi / 6 or a > 2 * math.pi - math.pi / 6):
                    pixels[(x, y)] = (0xe0, 0x40, 0x40)
                else:
                    pixels[(x, y)] = (0x9a, 0xa4, 0xb0) if r > 5 else (0x5a, 0x64, 0x70)
    return pixels


def trimmed(pixels):
    """The picture's box around what isn't transparent: x, y, w, h."""
    xs = [x for x, _ in pixels]
    ys = [y for _, y in pixels]
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1


def png(width, height, rgba):
    """RGBA8 rows, top first, as a PNG file's bytes."""
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
    rows = b''.join(b'\0' + bytes(rgba[y * width * 4:(y + 1) * width * 4]) for y in range(height))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(rows, 9)) + chunk(b'IEND', b''))


def generate():
    """Writes examples/assets/sheets/gizmos.png and gizmos.json."""
    sheets = Path(__file__).resolve().parents[1] / 'examples/assets/sheets'
    pictures = ([(f'walk_{k + 1:02}.png', walk(k), True) for k in range(len(WALK))] + [(f'jump_{k + 1:02}.png', jump(k), True) for k in range(2)]
                + [(f'idle_{k + 1:02}.png', idle(k), True) for k in range(IDLE)]
                + [(f'gear_{k + 1:02}.png', gear(k), False) for k in range(8)])
    # Shelves, left to right then down, each frame as packed (turned frames are as tall as they're wide upright).
    placed, x, y, shelf = [], 0, 0, 0
    for name, pixels, feet in pictures:
        tx, ty, tw, th = trimmed(pixels)
        turned = name in ROTATED
        pw, ph = (th, tw) if turned else (tw, th)
        if x + pw > WIDTH:
            x, y, shelf = 0, y + shelf + GAP, 0
        placed.append((name, pixels, feet, (tx, ty, tw, th), turned, x, y))
        x += pw + GAP
        shelf = max(shelf, ph)
    height = 1
    while height < y + shelf:
        height *= 2
    rgba = bytearray(WIDTH * height * 4)
    frames = {}
    for name, pixels, feet, (tx, ty, tw, th), turned, px, py in placed:
        for (sx, sy), color in pixels.items():
            ux, uy = sx - tx, sy - ty
            # Turned a quarter clockwise: the upright top-left lands at the packed rectangle's top-right.
            ax, ay = (px + th - 1 - uy, py + ux) if turned else (px + ux, py + uy)
            i = (ay * WIDTH + ax) * 4
            rgba[i:i + 4] = bytes(color) + b'\xff'
        frame = {'frame': {'x': px, 'y': py, 'w': tw, 'h': th}, 'rotated': turned, 'trimmed': True,
                 'spriteSourceSize': {'x': tx, 'y': ty, 'w': tw, 'h': th}, 'sourceSize': {'w': SIZE, 'h': SIZE}}
        if feet:
            frame['pivot'] = {'x': .5, 'y': 1}
        frames[name] = frame
    sheets.mkdir(exist_ok=True)
    (sheets / 'gizmos.png').write_bytes(png(WIDTH, height, rgba))
    meta = {'app': 'tools/gen_sprite_sheet.py', 'image': 'gizmos.png', 'format': 'RGBA8888',
            'size': {'w': WIDTH, 'h': height}, 'scale': '1'}
    (sheets / 'gizmos.json').write_text(json.dumps({'frames': frames, 'meta': meta}, indent='\t') + '\n')


if __name__ == '__main__':
    generate()
