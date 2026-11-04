"""Writes one of raygui_values' style and icon files, chosen by the name it is given: style.rgs, a text style (its properties, a font line
naming a font that isn't there, a property after it, and a last line with no break after it); dark.rgs, a binary style of properties and
no font; icons.rgi, two icons and their names.

    python3 makestyles.py <destination>"""
import struct
import sys
from pathlib import Path

out = Path(sys.argv[1])
out.parent.mkdir(parents=True, exist_ok=True)
if out.name == 'style.rgs':
    out.write_text('#\n# rgs style text file (v4.0)\n#\n'
                   'p 00 00 0x2f7486ff    DEFAULT_BORDER_COLOR_NORMAL\n'
                   'p 00 01 0x024658ff    DEFAULT_BASE_COLOR_NORMAL\n'
                   'p 00 16 0x00000014    TEXT_SIZE\n'
                   'p 01 14 0x00000002    LABEL_TEXT_ALIGNMENT\n'
                   'f 16 0 missing.ttf\n'
                   'p 00 17 0x00000003    TEXT_SPACING\n'
                   'p 02 12 0x00000004    BUTTON_BORDER_WIDTH\n'
                   'p 03 02 0x11223344    TOGGLE_TEXT_COLOR_NORMAL', encoding='utf-8')
elif out.name == 'dark.rgs':
    props = [(0, 0, 0x878787ff), (0, 1, 0x2c2c2cff), (0, 2, 0xc3c3c3ff), (0, 18, 0x6a6a6aff), (0, 19, 0x212121ff), (4, 16, 12),
             (12, 16, 30), (6, 14, 0)]
    data = b'rGS ' + struct.pack('<hhi', 400, 0, len(props))
    for c, p, v in props:
        data += struct.pack('<hhI', c, p, v)
    data += struct.pack('<i', 0)
    out.write_bytes(data)
elif out.name == 'icons.rgi':
    data = b'rGI ' + struct.pack('<hhhh', 100, 0, 2, 16)
    for name in (b'ICON_FIRST', b'ICON_SECOND'):
        data += name.ljust(32, b'\0')
    words = [0x0ff00ff0, 0x81818181, 0xffff0000, 0x0000ffff, 0x12345678, 0x9abcdef0, 0xf0f0f0f0, 0x0f0f0f0f]
    data += struct.pack('<16I', *(words + [w ^ 0xffffffff for w in words]))
    out.write_bytes(data)
else:
    sys.exit(f'makestyles: no file is called {out.name}')
