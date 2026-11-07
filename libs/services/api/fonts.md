# helix.services.fonts

[Back to the library](README.md)

## Font2D

*class* in [`libs/services/src/helix/services/fonts/Font2D.hx`](../src/helix/services/fonts/Font2D.hx), `import helix.services.fonts.Font2D;`

Represents a font: its kind, its metrics, its glyphs, the atlas they are drawn from, and its kerning pairs.

`Fonts` makes one from a font file, or from glyph images (`Fonts.packFont`). A program or an engine layer holding a font's atlas and glyphs of its own (raylib's default font) constructs one.

```haxe
function new(kind:FontKind, size:Float, ascent:Float, descent:Float, lineGap:Float, atlas:Image, glyphs:Array<Glyph2D>, ?kernings:Array<Kerning2D>, ?notdef:Glyph2D)
final kind:FontKind
final size:Float
final ascent:Float
final descent:Float
final lineGap:Float
final atlas:Image
final glyphs:Array<Glyph2D>
final notdef:Null<Glyph2D>
var kernings(get, never):Array<Kerning2D>
function getGlyph(codepoint:Int):Null<Glyph2D>
function getKerning(first:Int, second:Int):Float
```

- `new`: Creates a font from its atlas and its glyphs' places on it.
  - `kind`: What its glyphs hold.
  - `size`: The pixel height of a line from its ascent to its descent.
  - `ascent`: How far the tallest glyphs rise above the baseline, in pixels.
  - `descent`: How far the lowest fall below it, in pixels, negative.
  - `lineGap`: The space between one line's descent and the next line's ascent, in pixels.
  - `atlas`: The atlas: white, each glyph's coverage or distance as alpha.
  - `glyphs`: The glyphs, each its place on the atlas.
  - `kernings`: Optional. The kerning pairs; none when omitted.
  - `notdef`: Optional. The glyph drawn for a character the font lacks, also among `glyphs`; none when omitted.
- `kind`: Gets what its glyphs hold: coverage, hard-edged coverage, or signed distances, as it was made.
- `size`: Gets the size it was made at: the pixel height of a line from its ascent to its descent.
- `ascent`: Gets how far the tallest glyphs rise above the baseline, in pixels.
- `descent`: Gets how far the lowest glyphs fall below it, in pixels, negative.
- `lineGap`: Gets the space a line leaves below its descent before the next line's ascent, in pixels.
- `atlas`: Gets the atlas: white, each glyph's coverage (or distance) as alpha, rows top to bottom.
- `glyphs`: Gets the glyphs, in the order their characters were asked for; a character the font lacks has none.
- `notdef`: Gets the glyph the font draws for a character it lacks, its .notdef: a BMFont's invalid-character glyph (character -1, also among `glyphs`); null when the font has none, as a TrueType font loaded by `Fonts.load` has none.
- `kernings`: Gets the kerning pairs: a TrueType font's between the characters it was made with, from its `GPOS` pair adjustments or else its `kern` table; a BMFont's from its .fnt. Empty for a font with none.
- `getGlyph`: Returns a character's glyph.
  - `codepoint`: The character.
  - returns: Its glyph, or null when the font has none.
- `getKerning`: Returns how far the pen moves between two characters beyond the first's advance, from `kernings`.
  - `first`: The first character.
  - `second`: The character following it.
  - returns: The amount, in pixels at the font's size: negative to close up, 0 for a pair the font doesn't kern.

## FontKind

*abstract* in [`libs/services/src/helix/services/fonts/FontKind.hx`](../src/helix/services/fonts/FontKind.hx), `import helix.services.fonts.FontKind;`

Specifies what a font's glyphs hold (`Font2D.kind`): `Fonts.load`, `rasterize` and `loadBmFont` make Coverage, `loadBitmap` and `rasterizeBitmap` Bitmap, `loadDistanceField` and `rasterizeDistanceField` Distance; `packFont` and a `Font2D` a program makes what they are given.

- `FontKind.Coverage`: Antialiased coverage: each texel how much of it the glyph covers.
- `FontKind.Bitmap`: Coverage made hard-edged: each texel covered or not, for pixel fonts drawn at their own size.
- `FontKind.Distance`: Signed distances to the outline, sharp at any size through a distance-field shader: 128 on the outline, 64 a texel, with 4 texels of padding around each glyph.

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Coverage, Bitmap): what Std.string, interpolation and trace show.

## FontPacking

*abstract* in [`libs/services/src/helix/services/fonts/FontPacking.hx`](../src/helix/services/fonts/FontPacking.hx), `import helix.services.fonts.FontPacking;`

Specifies how `Fonts.load` places glyphs on the atlas.

- `FontPacking.Rows`: In rows, in the order asked for, each row a line's height.
- `FontPacking.Skyline`: As tightly as a skyline packs them, tallest first (helix-math's `RectPacker2D`).

```haxe
function toString():String
```

- `toString`: Returns the value's name as written (Rows, Skyline): what Std.string, interpolation and trace show.

## Fonts

*class* in [`libs/services/src/helix/services/fonts/Fonts.hx`](../src/helix/services/fonts/Fonts.hx), `import helix.services.fonts.Fonts;`

Provides fonts by path: a TrueType or OpenType font rasterized at a size as coverage (`load`), hard-edged (`loadBitmap`) or signed distances (`loadDistanceField`), or a BMFont's .fnt and its images (`loadBmFont`), each as a `Font2D` with its glyphs on one atlas. A TrueType font's glyphs also come from its bytes, each on its own, for a program that places them itself (`rasterize`, `rasterizeBitmap`, `rasterizeDistanceField`). Each kind is its own call, so a program carries only the rasterizing it asks for. A font's kerning pairs come with it: a TrueType font's between the characters asked for, a BMFont's from its .fnt. A program or an engine layer holding glyph images of its own makes a font of them with `packFont`.

A TrueType font's glyphs are rasterized by the platform (`IFontRasterizer`) and packed onto an atlas as `FontsOptions` says. Its answers come as the assets, images and rasterizer it uses are polled.

```haxe
var fonts = new Fonts(rasterizer, assets, images);
fonts.load("ui.ttf", 24, [for (c in 32...127) c], font -> ui = font);
```

```haxe
function new(rasterizer:IFontRasterizer, assets:Assets, images:Images, ?options:FontsOptions)
function load(path:String, size:Float, codepoints:Array<Int>, loaded:Font2D -> Void, ?failed:String -> Void):() -> Void
function loadBitmap(path:String, size:Float, codepoints:Array<Int>, loaded:Font2D -> Void, ?failed:String -> Void):() -> Void
function loadDistanceField(path:String, size:Float, codepoints:Array<Int>, loaded:Font2D -> Void, ?failed:String -> Void):() -> Void
function rasterize(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, ?failed:String -> Void):() -> Void
function rasterizeBitmap(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, ?failed:String -> Void):() -> Void
function rasterizeDistanceField(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, ?failed:String -> Void):() -> Void
function loadBmFont(path:String, loaded:Font2D -> Void, ?failed:String -> Void):() -> Void
function packFont(name:String, kind:FontKind, size:Float, ascent:Float, descent:Float, lineGap:Float, glyphs:Array<RasterGlyph>, ?kernings:Array<Kerning2D>):Font2D
```

- `new`: Creates the fonts over the platform's rasterizer, the assets fonts are found in, and the images a BMFont's are decoded by.
  - `rasterizer`: The platform's font rasterizer.
  - `assets`: The assets the files are read through.
  - `images`: The images a BMFont's pages are decoded by.
  - `options`: Optional. How the atlas is made. Defaults to a texel of padding, packed as a skyline.
- `load`: Loads a TrueType or OpenType font and rasterizes its glyphs at a size onto one atlas, as antialiased coverage (`FontKind.Coverage`).
  - `path`: The file, as the assets name it.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted; one the font lacks has no glyph.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  One of `loaded` or `failed` is called once, at a later poll, never during this call.
- `loadBitmap`: Loads a TrueType or OpenType font as `load` does, its glyphs' coverage made hard-edged (`FontKind.Bitmap`), for pixel fonts drawn at their own size.
  - `path`: The file, as the assets name it.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted; one the font lacks has no glyph.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.
- `loadDistanceField`: Loads a TrueType or OpenType font as `load` does, its glyphs signed distances to their outlines (`FontKind.Distance`), sharp at any size through a distance-field shader.
  - `path`: The file, as the assets name it.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted; one the font lacks has no glyph.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.
- `rasterize`: Rasterizes a TrueType or OpenType font's glyphs from the file's bytes as antialiased coverage, each on its own, for a program that places them itself: on an atlas of its own, or one image each. `load` makes a font of them on one atlas.
  - `encoded`: The font file's bytes, TTF or OTF.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted.
  - `rasterized`: Receives a glyph for each codepoint, in their order (one the font lacks isn't `found`, and is empty), and the font's ascent, descent (below the baseline, negative) and line gap, in pixels.
  - `failed`: Optional. Receives why the font can't be read. When omitted, the failure is logged.
  - returns: A function that aborts it; neither callback is called after it, and once one was, it does nothing.

  One of `rasterized` or `failed` is called once, at a later poll, never during this call.
- `rasterizeBitmap`: Rasterizes glyphs as `rasterize` does, their coverage made hard-edged: each texel covered or not.
  - `encoded`: The font file's bytes, TTF or OTF.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted.
  - `rasterized`: Receives a glyph for each codepoint, in their order, and the font's ascent, descent and line gap.
  - `failed`: Optional. Receives why the font can't be read. When omitted, the failure is logged.
  - returns: A function that aborts it; neither callback is called after it, and once one was, it does nothing.
- `rasterizeDistanceField`: Rasterizes glyphs as signed distances to their outlines (`IFontRasterizer.rasterizeDistanceField`): 128 on the outline, 64 a texel, with 4 texels of padding around each glyph.
  - `encoded`: The font file's bytes, TTF or OTF.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted.
  - `rasterized`: Receives a glyph for each codepoint, in their order, and the font's ascent, descent and line gap.
  - `failed`: Optional. Receives why the font can't be read. When omitted, the failure is logged.
  - returns: A function that aborts it; neither callback is called after it, and once one was, it does nothing.
- `loadBmFont`: Loads a BMFont: its .fnt (the text format) and its pages, stacked top to bottom onto one atlas. A page with no transparency whose texels are gray is coverage, so it becomes white with the gray as alpha, as raylib takes it.
  - `path`: The .fnt file, as the assets name it.
  - `loaded`: Receives the font: its size the .fnt's line height, its ascent its base.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  One of `loaded` or `failed` is called once, at a later poll, never during this call.
- `packFont`: Returns a font made of glyph images, packed onto one atlas as `FontsOptions` says, as `load` packs a TrueType font's: the smallest power-of-two square they fit, white, each glyph's image as alpha. For a program or an engine layer holding a font's glyphs of its own (raylib's default font, the glyphs `rasterize` gives).
  - `name`: The atlas's name, its image's `path`; "" for none.
  - `kind`: What the glyphs hold.
  - `size`: The pixel height of a line from its ascent to its descent.
  - `ascent`: How far the tallest glyphs rise above the baseline, in pixels.
  - `descent`: How far the lowest fall below it, in pixels, negative.
  - `lineGap`: The space between one line's descent and the next line's ascent, in pixels.
  - `glyphs`: Each glyph's image, `width * height` bytes, its place from the pen and its advance.
  - `kernings`: Optional. The kerning pairs; none when omitted.
  - returns: The font, its glyphs in the order given.

## FontsOptions

*class* in [`libs/services/src/helix/services/fonts/FontsOptions.hx`](../src/helix/services/fonts/FontsOptions.hx), `import helix.services.fonts.FontsOptions;`

Represents how `Fonts` makes a font's atlas.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{?padding:Int, ?packing:FontPacking}
```

```haxe
final padding:Int = 1
final packing:FontPacking = Skyline
```

- `padding`: Gets the empty texels around each glyph on the atlas, so sampling one doesn't reach its neighbour. Defaults to 1.
- `packing`: Gets how glyphs are placed on the atlas. Defaults to `Skyline`.

## Glyph2D

*class* in [`libs/services/src/helix/services/fonts/Glyph2D.hx`](../src/helix/services/fonts/Glyph2D.hx), `import helix.services.fonts.Glyph2D;`

Represents one of a font's glyphs: where it is on the atlas, where it sits from the pen, and how far it moves the pen.

```haxe
function new(codepoint:Int, x:Int, y:Int, width:Int, height:Int, offsetX:Float, offsetY:Float, advance:Float)
final codepoint:Int
final x:Int
final y:Int
final width:Int
final height:Int
final offsetX:Float
final offsetY:Float
final advance:Float
```

- `new`: Creates a glyph.
  - `codepoint`: The character.
  - `x`: Its left edge on the atlas, in texels.
  - `y`: Its top edge on the atlas, in texels.
  - `width`: Its width on the atlas, in texels; 0 for nothing to draw.
  - `height`: Its height on the atlas, in texels.
  - `offsetX`: Its left edge from the pen, in pixels at the font's size.
  - `offsetY`: Its top edge from the baseline, in pixels at the font's size, down positive.
  - `advance`: How far the pen moves after it, in pixels at the font's size.
- `codepoint`: Gets the character.
- `x`: Gets its place on the atlas: left edge, in texels.
- `y`: Gets its top edge on the atlas, in texels.
- `width`: Gets its width on the atlas, in texels; 0 for a glyph with nothing to draw, such as a space.
- `height`: Gets its height on the atlas, in texels.
- `offsetX`: Gets its left edge from the pen, in pixels at the font's size.
- `offsetY`: Gets its top edge from the baseline, in pixels at the font's size, down positive: above the baseline it is negative.
- `advance`: Gets how far the pen moves after it, in pixels at the font's size.

## Kerning2D

*typedef* in [`libs/services/src/helix/services/fonts/Kerning2D.hx`](../src/helix/services/fonts/Kerning2D.hx), `import helix.services.fonts.Kerning2D;`

Represents a kerning pair of a font: how far the pen moves when one character follows another, beyond the first's advance.

- `second:Int`: The character following it.
- `first:Int`: The first character.
- `amount:Float`: How far the pen moves right between them, in pixels at the font's size: negative to close up.
