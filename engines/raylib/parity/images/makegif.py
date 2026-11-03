"""Writes the GIF the images suite loads as a font, by the path its command line names: one frame of three glyphs on a magenta key,
as LoadFontFromImage scans them. Its LZW data is written without compressing: a minimum code size of 7, so each code is a byte, the
pixels (fewer than the 126 codes before the size grows) between a clear code and the end code."""
import struct, sys
from pathlib import Path

KEY, WHITE, BLACK, GRAY = 0, 1, 2, 3
COLORS = [(255, 0, 255), (255, 255, 255), (0, 0, 0), (128, 128, 128)]
WIDTH, HEIGHT = 13, 7


def pixel(x, y):
    """Three glyphs, 3 x 5 at x 1, 5 and 9 and y 1, each its own pattern; the key around them."""
    if not 1 <= y <= 5 or x % 4 == 0 or x > 11:
        return KEY
    glyph, gx, gy = x // 4, x % 4 - 1, y - 1
    return [WHITE if (gx + gy) % 2 else BLACK, GRAY if gy % 2 else WHITE, BLACK if gx == 1 else GRAY][glyph]


def gif():
    pixels = bytes(pixel(x, y) for y in range(HEIGHT) for x in range(WIDTH))
    codes = bytes([128]) + pixels + bytes([129])
    blocks = b''.join(bytes([len(codes[i:i + 255])]) + codes[i:i + 255] for i in range(0, len(codes), 255)) + b'\0'
    table = b''.join(bytes(c) for c in COLORS)
    screen = struct.pack('<HHBBB', WIDTH, HEIGHT, 0x81, 0, 0)  # a global table of 4 colors, background index 0
    image = b'\x2c' + struct.pack('<HHHHB', 0, 0, WIDTH, HEIGHT, 0) + bytes([7]) + blocks
    return b'GIF89a' + screen + table + image + b'\x3b'


Path(sys.argv[1]).write_bytes(gif())
