# helix.formats.truetype

[Back to the index](README.md)

## TrueTypeTables

*class* in [`formats/src/helix/formats/truetype/TrueTypeTables.hx`](../../formats/src/helix/formats/truetype/TrueTypeTables.hx), `import helix.formats.truetype.TrueTypeTables;`

Represents the tables of a TrueType or OpenType font, read as stb_truetype reads them.

It reads the vertical metrics (`hhea`), the units per em (`head`), each codepoint's glyph (`cmap`, the subtable stb_truetype picks), its advance (`hmtx`) and, for TrueType outlines, its box (`glyf`), so glyphs are found, measured and placed as a native build places them. An OpenType font with CFF outlines has no `glyf`: `hasGlyf` is false, and its boxes are not read. Nothing is drawn: outlines, kerning and font collections are not read.

```haxe
var tables = new TrueTypeTables(bytes);
var scale = tables.scaleFor(32);
var advance = tables.advance(tables.glyphIndex("A".code)) * scale;
```

```haxe
function new(data:haxe.io.Bytes)
final unitsPerEm:Int
final ascent:Int
final descent:Int
final lineGap:Int
function scaleFor(size:Float):Float
var hasGlyf(get, never):Bool
function glyphIndex(codepoint:Int):Int
function advance(glyphIndex:Int):Int
function box(glyphIndex:Int):Null<Array<Int>>
```

- `new`: Reads a font's tables.
  - `data`: The font file.
  - throws `String`: It isn't a TrueType or OpenType font, or lacks a table stb_truetype needs.

  The bytes are kept, not copied: the glyph lookups read them.
- `unitsPerEm`: Gets the font's units per em, from `head`.
- `ascent`: Gets the font's ascent, from `hhea`: in font units above the baseline, y up.
- `descent`: Gets the font's descent, from `hhea`: in font units, y up, so below the baseline it is negative.
- `lineGap`: Gets the font's line gap, from `hhea`: in font units, the space between one line's descent and the next line's ascent.
- `scaleFor`: Returns the scale for a pixel height, as stb_truetype's `ScaleForPixelHeight`.
  - `size`: The pixel height.
  - returns: Pixels per font unit.
- `hasGlyf`: Gets a value indicating whether the font has TrueType outlines in `glyf`, whose boxes `box` reads.
- `glyphIndex`: Returns a codepoint's glyph, as stb_truetype's `FindGlyphIndex` finds it, or 0 for none.
  - `codepoint`: The codepoint.
  - returns: The glyph index.
- `advance`: Returns a glyph's advance, in font units.
  - `glyphIndex`: The glyph index.
  - returns: The advance.
- `box`: Returns a TrueType glyph's box, in font units: x0, y0, x1, y1, y up; null for one with no outline.
  - `glyphIndex`: The glyph index.
  - returns: The box.

  Only a font with `hasGlyf` has boxes to read.
