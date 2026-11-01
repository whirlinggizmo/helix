"""fontfile_62: raylib 6.2's LoadFontEx on a TrueType file (ray/examples/text's JetBrains Mono), which helix-ray takes from 6.2, against
helix-ray's LoadFontExAsync. One list for both sides (shared/gen.py's syntax): load loads a font and font prints it (each glyph, its place
and a checksum of its image), in ref.c.in and FontFileBits.hx.in."""


def ints(*items):
    """A list of ints, as C and Haxe write it."""
    return {'c': '(int[]){ ' + ', '.join(map(str, items)) + ' }', 'hx': '[' + ', '.join(map(str, items)) + ']'}


def with_list(template, listed):
    """A case whose statements hold a list written apart in C and Haxe, at @L@, and a font f (@F@)."""
    return {'c': template.replace('@L@', listed['c']).replace('@F@', 'Font f'),
            'hx': template.replace('@L@', listed['hx']).replace('@F@', 'var f')}


# Characters the font has and lacks: A, CJK's 中 (lacked), '?', the ideographic space (lacked), the no-break space, the thin space, the
# Ogham space mark, the em space and B.
WANTED = (65, 0x4E2D, 63, 0x3000, 0xA0, 0x2009, 0x1680, 0x2003, 66)

CASES = [
    # The printable ASCII, as LoadFontEx loads it without codepoints.
    'font("ascii", load("font.ttf", 20, NULL, 0));',
    # Only the glyphs the font has (5.5 kept an empty one for each it lacked, drawn as nothing), so a character it lacks is its '?';
    # each Unicode space it has a blank glyph as wide as its advance (5.5 made only U+0020's).
    with_list('{ @F@ = load("font.ttf", 24, @L@, 9); font("wanted", f); num("wantedmissing", GetGlyphIndex(f, 0x4E2D)); '
              'num("wantedquestion", GetGlyphIndex(f, 63)); num("wantedspace", GetGlyphIndex(f, 0x3000)); }', ints(*WANTED)),
    # (A font with none of the characters asked for isn't a case: 6.2 packs 95 glyphs it hasn't made, reading past its memory.)
]
