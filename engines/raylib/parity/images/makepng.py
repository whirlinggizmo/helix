"""Writes the PNG the images suite loads as an animation of one frame, by the path its command line names: 5 x 4 pixels of RGBA, each
its own color and alpha."""
import struct, sys, zlib
from pathlib import Path


def png(width, height, pixel):
    """A PNG of 8-bit RGBA pixels, each pixel(x, y) a tuple, every row filtered by none."""
    rows = b''.join(b'\0' + bytes(c for x in range(width) for c in pixel(x, y)) for y in range(height))

    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    header = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header) + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')


Path(sys.argv[1]).write_bytes(png(5, 4, lambda x, y: (x * 50, y * 60, (x + y) * 20, 255 - x * y * 10)))
