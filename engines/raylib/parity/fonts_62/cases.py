"""fonts_62: raylib 6.2's GenImageFontAtlas and LoadFontFromImage, which helix-raylib takes from 6.2, against helix-raylib's. One list for both
sides (shared/gen.py's syntax): glyphs(n, w0, dw, wm, h0, hm) makes glyphs of known sizes and texels, atlas prints an atlas (its size,
format and a checksum of its texels, then each glyph's place) and font a font, all in ref.c.in and FontBits.hx.in. Each fix has a case
built from the input that showed its bug in raylib 5.5."""


def image(name, width, height, rectangles, pixels=()):
    """A font image of width by height on raylib's MAGENTA key, the rectangles (x, y, w, h) and pixels (x, y) white, read by
    LoadFontFromImage from 'A'."""
    drawn = ''.join(f' ImageDrawRectangle(OUT(img), {x}, {y}, {w}, {h}, WHITE);' for x, y, w, h in rectangles)
    drawn += ''.join(f' ImageDrawPixel(OUT(img), {x}, {y}, WHITE);' for x, y in pixels)
    return '{ LET(img, Image, GenImageColor(' + f'{width}, {height}, MAGENTA));{drawn} font("{name}", LoadFontFromImage(img, MAGENTA, 65)); ' + '}'


CASES = [
    # Packing in rows: when the estimate runs out of rows, 6.2 makes the atlas twice as high and goes on (5.5 left every glyph after
    # with an empty place); a glyph past the atlas's edge is clipped (5.5 wrote past its texels).
    'atlas("atlasrows", glyphs(10, 65, 0, 1, 10, 1), 10, 10, 0, 0);',
    'atlas("atlastwice", glyphs(20, 65, 0, 1, 10, 1), 20, 10, 0, 0);',
    'atlas("atlastall", glyphs(10, 65, 0, 1, 25, 1), 10, 10, 0, 0);',
    'atlas("atlaspadded", glyphs(30, 4, 5, 11, 8, 5), 30, 12, 2, 0);',
    'atlas("atlasdefault", glyphs(95, 5, 3, 7, 9, 3), 0, 10, 1, 0);',
    'atlas("atlasfits", glyphs(12, 6, 2, 5, 10, 1), 12, 10, 1, 0);',
    # An atlas too small for the white corner leaves it out (5.5 wrote it past the texels).
    'atlas("atlastiny", glyphs(1, 1, 0, 1, 1, 1), 1, 1, 0, 0);',
    # The skyline packer.
    'atlas("atlasskyline", glyphs(30, 4, 5, 11, 8, 5), 30, 12, 2, 1);',
    'atlas("atlasskylinefull", glyphs(10, 65, 0, 1, 25, 1), 10, 10, 0, 1);',
    'atlas("atlasskylinepadded", glyphs(10, 65, 0, 1, 25, 1), 10, 10, 3, 1);',
    # LoadFontFromImage: a glyph's width ends at the image's right edge (5.5 read on into the next row, here a white pixel at its
    # left), its height at the image's bottom.
    image('imageedge', 16, 12, [(2, 2, 3, 5), (7, 2, 3, 5), (12, 2, 4, 5)], [(0, 3)]),
    image('imagebottom', 16, 7, [(2, 2, 3, 5), (7, 2, 3, 5)]),
    image('imagelines', 16, 16, [(2, 2, 3, 5), (7, 2, 2, 5), (2, 9, 4, 5), (8, 9, 1, 5)]),
    image('imagenoborder', 4, 4, [(0, 0, 4, 4)]),
]
