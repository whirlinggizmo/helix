# helix.services.fonts

[Back to the index](README.md)

## Font2D

*class* in [`services/src/helix/services/fonts/Font2D.hx`](../../services/src/helix/services/fonts/Font2D.hx), `import helix.services.fonts.Font2D;`

Represents a font made by `Fonts`: its metrics, its glyphs, and the atlas they are drawn from.

```haxe
final size:Float
final ascent:Float
final descent:Float
final lineGap:Float
final atlas:Image
final glyphs:Array<Glyph2D>
final notdef:Null<Glyph2D>
function getGlyph(codepoint:Int):Null<Glyph2D>
```

- `size`: Gets the size it was made at: the pixel height of a line from its ascent to its descent.
- `ascent`: Gets how far the tallest glyphs rise above the baseline, in pixels.
- `descent`: Gets how far the lowest glyphs fall below it, in pixels, negative.
- `lineGap`: Gets the space a line leaves below its descent before the next line's ascent, in pixels.
- `atlas`: Gets the atlas: white, each glyph's coverage (or distance) as alpha, rows top to bottom.
- `glyphs`: Gets the glyphs, in the order their characters were asked for; a character the font lacks has none.
- `notdef`: Gets the glyph the font draws for a character it lacks, its .notdef: a BMFont's invalid-character glyph (character -1, also among `glyphs`); null when the font has none, as a TrueType font loaded by `Fonts.load` has none.
- `getGlyph`: Returns a character's glyph.
  - `codepoint`: The character.
  - returns: Its glyph, or null when the font has none.

## FontKind

*abstract* in [`services/src/helix/services/fonts/FontKind.hx`](../../services/src/helix/services/fonts/FontKind.hx), `import helix.services.fonts.FontKind;`

Specifies what a font's glyphs hold, as `Fonts.load` and `Fonts.rasterize` rasterize them.

- `FontKind.Coverage`: Antialiased coverage: each texel how much of it the glyph covers.
- `FontKind.Bitmap`: Coverage made hard-edged: each texel covered or not, for pixel fonts drawn at their own size.
- `FontKind.Distance`: Signed distances to the outline, sharp at any size through a distance-field shader: 128 on the outline, 64 a texel, with 4 texels of padding around each glyph.

## FontPacking

*abstract* in [`services/src/helix/services/fonts/FontPacking.hx`](../../services/src/helix/services/fonts/FontPacking.hx), `import helix.services.fonts.FontPacking;`

Specifies how `Fonts.load` places glyphs on the atlas.

- `FontPacking.Rows`: In rows, in the order asked for, each row a line's height.
- `FontPacking.Skyline`: As tightly as a skyline packs them, tallest first (helix-math's `RectPacker2D`).

## Fonts

*class* in [`services/src/helix/services/fonts/Fonts.hx`](../../services/src/helix/services/fonts/Fonts.hx), `import helix.services.fonts.Fonts;`

Provides fonts by path: a TrueType or OpenType font rasterized at a size (`load`), or a BMFont's .fnt and its images (`loadBmFont`), each as a `Font2D` with its glyphs on one atlas. A TrueType font's glyphs also come from its bytes, each on its own, for a program that places them itself (`rasterize`).

A TrueType font's glyphs are rasterized by the platform (`IFontRasterizer`) and packed onto an atlas as `FontsOptions` says. Its answers come as the assets, images and rasterizer it uses are polled.

```haxe
var fonts = new Fonts(rasterizer, assets, images);
fonts.load("ui.ttf", 24, [for (c in 32...127) c], Coverage, font -> ui = font);
```

```haxe
function new(rasterizer:IFontRasterizer, assets:Assets, images:Images, ?options:FontsOptions)
function load(path:String, size:Float, codepoints:Array<Int>, kind:FontKind, loaded:Font2D -> Void, ?failed:String -> Void):() -> Void
function rasterize(encoded:haxe.io.Bytes, size:Float, codepoints:Array<Int>, kind:FontKind, rasterized:(glyphs:Array<RasterGlyph>, ascent:Float, descent:Float, lineGap:Float) -> Void, ?failed:String -> Void):() -> Void
function loadBmFont(path:String, loaded:Font2D -> Void, ?failed:String -> Void):() -> Void
```

- `new`: Creates the fonts over the platform's rasterizer, the assets fonts are found in, and the images a BMFont's are decoded by.
  - `rasterizer`: The platform's font rasterizer.
  - `assets`: The assets the files are read through.
  - `images`: The images a BMFont's pages are decoded by.
  - `options`: Optional. How the atlas is made. Defaults to a texel of padding, packed as a skyline.
- `load`: Loads a TrueType or OpenType font and rasterizes its glyphs at a size onto one atlas.
  - `path`: The file, as the assets name it.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted; one the font lacks has no glyph.
  - `kind`: What the glyphs hold: coverage, hard-edged coverage, or signed distances.
  - `loaded`: Receives the font.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  One of `loaded` or `failed` is called once, at a later poll, never during this call.
- `rasterize`: Rasterizes a TrueType or OpenType font's glyphs from the file's bytes, each on its own, for a program that places them itself: on an atlas of its own, or one image each. `load` makes a font of them on one atlas.
  - `encoded`: The font file's bytes, TTF or OTF.
  - `size`: The pixel height: the font's ascent to its descent.
  - `codepoints`: The characters wanted.
  - `kind`: What the glyphs hold: coverage, hard-edged coverage, or signed distances.
  - `rasterized`: Receives a glyph for each codepoint, in their order, its bitmap as `kind` says (one the font lacks isn't `found`, and is empty), and the font's ascent, descent (below the baseline, negative) and line gap, in pixels.
  - `failed`: Optional. Receives why the font can't be read. When omitted, the failure is logged.
  - returns: A function that aborts it; neither callback is called after it, and once one was, it does nothing.

  One of `rasterized` or `failed` is called once, at a later poll, never during this call.
- `loadBmFont`: Loads a BMFont: its .fnt (the text format) and its pages, stacked top to bottom onto one atlas. A page with no transparency whose texels are gray is coverage, so it becomes white with the gray as alpha, as raylib takes it.
  - `path`: The .fnt file, as the assets name it.
  - `loaded`: Receives the font: its size the .fnt's line height, its ascent its base.
  - `failed`: Optional. Receives why it couldn't be loaded. When omitted, the failure is logged.
  - returns: A function that aborts the load; neither callback is called after it, and once one was, it does nothing.

  One of `loaded` or `failed` is called once, at a later poll, never during this call.

## FontsOptions

*class* in [`services/src/helix/services/fonts/FontsOptions.hx`](../../services/src/helix/services/fonts/FontsOptions.hx), `import helix.services.fonts.FontsOptions;`

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

*class* in [`services/src/helix/services/fonts/Glyph2D.hx`](../../services/src/helix/services/fonts/Glyph2D.hx), `import helix.services.fonts.Glyph2D;`

Represents one of a font's glyphs: where it is on the atlas, where it sits from the pen, and how far it moves the pen.

```haxe
final codepoint:Int
final x:Int
final y:Int
final width:Int
final height:Int
final offsetX:Float
final offsetY:Float
final advance:Float
```

- `codepoint`: Gets the character.
- `x`: Gets its place on the atlas: left edge, in texels.
- `y`: Gets its top edge on the atlas, in texels.
- `width`: Gets its width on the atlas, in texels; 0 for a glyph with nothing to draw, such as a space.
- `height`: Gets its height on the atlas, in texels.
- `offsetX`: Gets its left edge from the pen, in pixels at the font's size.
- `offsetY`: Gets its top edge from the baseline, in pixels at the font's size, down positive: above the baseline it is negative.
- `advance`: Gets how far the pen moves after it, in pixels at the font's size.
