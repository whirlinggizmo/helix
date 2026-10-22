# helix.font

[Back to the index](README.md)

## BakedFont

*typedef* in `src/helix/font/FontBaker.hx`

A font's characters baked into one distance-field atlas: a byte a texel, 128 on the outline, rising inward and falling outward by 128 / padding a pixel.

- `width:Int`
- `scale:Float`
- `pixelHeight:Float`
- `lineGap:Float`
- `height:Int`
- `glyphs:Array<BakedGlyph>`
- `field:haxe.io.Bytes`
- `descent:Float`
- `ascent:Float`

## BakedGlyph

*typedef* in `src/helix/font/FontBaker.hx`

A baked glyph: its place in the atlas, its box's offset from the pen on the baseline (y down) and its advance, in pixels at the baked height. A glyph with nothing to draw (a space) has no size.

- `yOffset:Int`
- `y:Int`
- `xOffset:Int`
- `x:Int`
- `width:Int`
- `height:Int`
- `code:Int`
- `advance:Float`

## Font

*class* in `src/helix/font/Font.hx`

A font for text (Batch2D.drawText, a Text2D node): its characters as glyphs in one texture. builtIn() is JetBrains Mono's printable ASCII as a distance field, sharp at any size; fromTrueType() any TrueType font's printable ASCII and Latin-1, baked the same way (Fonts loads them from files), with its kerning; pixel() a 5x7 bitmap font. Sizes are in font pixels: the size the font was made at, which text is scaled from to the size asked for.

```haxe
static function fromTrueType(data:haxe.io.Bytes, ?pixelHeight:Float = 32., ?padding:Int = 6, ?gpu:IGraphics):Font
static function builtIn(?gpu:IGraphics):Font
static function pixel(?gpu:IGraphics):Font
var texture(default, null):Texture2D
var size(default, null):Float
var ascent(default, null):Float
var descent(default, null):Float
var distanceField(default, null):Bool
function getGlyph(code:Int):Null<Glyph>
function getKerning(left:Int, right:Int):Float
function measure(text:String, size:Float):Float
function wrap(text:String, size:Float, width:Float):Array<String>
function measureWrapped(text:String, size:Float, width:Float, ?lineHeight:Float = 1.25):Float
function destroy(?gpu:IGraphics):Void
```

- `fromTrueType`: A font from a TrueType file's bytes: its printable ASCII and Latin-1 characters baked at pixelHeight (ascent to descent) into a distance field with padding pixels around each glyph (FontBaker), sharp from small text to about four times pixelHeight. Throws, saying why, for a file it can't read. On gpu, the program's (Graphics) when not given. The caller destroys it.
- `builtIn`: The built-in font: JetBrains Mono's printable ASCII as a distance field, baked by tools/bake_fonts.py (SIL OFL 1.1, see THIRD_PARTY_NOTICES.md). On gpu, the program's (Graphics) when not given.
- `pixel`: The 5x7 pixel font: crisp at whole multiples of 7, blocky between. Its texture also carries a white texel for shapes. On gpu, the program's (Graphics) when not given.
- `texture`: The texture holding every glyph, with a white texel for untextured shapes.
- `size`: The height the font was made at, ascent to descent, in font pixels: a text's size scales this.
- `ascent`: How far the tallest glyphs reach above the baseline, in font pixels.
- `descent`: How far glyphs reach below the baseline, in font pixels; 0 or negative.
- `distanceField`: Whether the texture's alpha is a distance from each glyph's outline (Batch2D draws it so) rather than coverage.
- `getGlyph`: A character's glyph, or null when it has none (space has an advance but nothing to draw: its glyph has no size).
- `getKerning`: How far the pen moves besides the advance between characters left and right, in font pixels: usually negative, closing a pair such as "AV". 0 for a font without kerning.
- `measure`: How far text moves the pen at size (world units, ascent to descent): its width, by its glyphs' advances and the kerning between them. Characters without a glyph count as nothing.
- `wrap`: text broken into lines no wider than width in world units at size: at spaces, and a word wider than a line within it, between its letters; a line break ("\n") always breaks. Lines keep no trailing spaces.
- `measureWrapped`: The height text takes wrapped to width at size (wrap), its lines lineHeight times size apart: what Batch2D.drawTextWrapped returns, known before drawing, for what's laid out under it (a button below a title that may wrap).
- `destroy`: Frees the font's texture on gpu, the adapter that made it: the program's (Graphics) when not given.

## FontBaker

*class* in `src/helix/font/FontBaker.hx`

Bakes a TrueType font's characters into a signed distance field atlas, in Haxe, the same on every target: each glyph's outline is flattened into segments finer than a twentieth of a pixel, and each texel holds its signed distance to them (inside by the nonzero rule), so text drawn from it stays sharp from small to about four times the baked height. Glyphs are packed in rows, left to right.

```haxe
static function bake(font:TrueType, codes:Array<Int>, pixelHeight:Float, padding:Int, atlasWidth:Int):BakedFont
```

- `bake`: Bakes codes (characters) of font at pixelHeight (ascent to descent) with padding pixels of field around each glyph, into an atlas atlasWidth wide and as tall as it needs (a power of two), with a free last row (its last texel is set fully inside: a white texel).

## FontCache

*class* in `src/helix/font/FontCache.hx`

TrueType fonts loaded through the assets into Font2Ds: read and baked into a distance-field texture in Haxe (Font.fromTrueType), the same on every target, and baked again in place when a file changes during development. The runner's is what the Fonts static forwards to; the caller releases what it loads.

```haxe
function new(assets:IAssets, gpu:IGraphics)
function load(path:String, loaded:Font -> Void, ?failed:String -> Void):IRequest
function getPath(font:Font):Null<String>
function release(font:Font):Void
function reloaded(path:String, bytes:haxe.io.Bytes):Void
function shutdown():Void
```

- `new`: Loads through assets and uploads to gpu; shutdown shuts nothing down but this service.
- `load`: Loads path (a .ttf) into a font. One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded once it is baked; failed (else the log, with the path) for a load failure or a file it can't read.
- `getPath`: The file font was loaded from, or null for one this service didn't load.
- `release`: Frees a font this service loaded, and stops reloading it.
- `reloaded`: The file behind loaded fonts changed: they're baked again in place, keeping their Font objects. A file that no longer reads leaves them as they were.
- `shutdown`: Frees every font still loaded and takes no more loads: a load that lands after calls nothing. The runner's, at the program's end.

## Fonts

*class* in `src/helix/font/Fonts.hx`

TrueType fonts from files, baked into distance fields and baked again when a file changes during development (FontCache). The program's one, a static class: each member forwards to instance, written by helix.macro.Facade from FontCache's public members with their doc comments.

```haxe
static function load(path:String, loaded:Font -> Void, ?failed:String -> Void):IRequest
static function getPath(font:Font):Null<String>
static function release(font:Font):Void
```

- `load`: Loads path (a .ttf) into a font. One of loaded or failed runs once on the host thread, and neither once the request is cancelled: loaded once it is baked; failed (else the log, with the path) for a load failure or a file it can't read.
- `getPath`: The file font was loaded from, or null for one this service didn't load.
- `release`: Frees a font this service loaded, and stops reloading it.

## Glyph

*typedef* in `src/helix/font/Font.hx`

Where a glyph's texels are, and where it goes: x and y from the pen on the baseline (y grows down), its size, and how far the pen moves after it, in font pixels.

- `y:Float`
- `x:Float`
- `width:Float`
- `v1:Float`
- `v0:Float`
- `u1:Float`
- `u0:Float`
- `height:Float`
- `advance:Float`

## GlyphOutline

*typedef* in `src/helix/font/TrueType.hx`

A glyph's outline in font units (y up): closed contours, each a list of points, x and y in turn, with whether each is on the curve; two off-curve points in a row have an on-curve point between them, as TrueType draws quadratic curves.

An alias of `Array<{points:Array<Float>, onCurve:Array<Bool>}>`.

## TrueType

*class* in `src/helix/font/TrueType.hx`

A TrueType font file (glyf outlines) as read: its metrics, its characters' glyphs and their outlines, and the kerning between pairs (the GPOS table's pair adjustments, or the older kern table). Read in Haxe, the same on every target; Font bakes it into a texture. Throws, saying why, for a file it can't read: no glyf outlines (a CFF font), or a table missing or cut short.

```haxe
function new(data:haxe.io.Bytes)
final unitsPerEm:Int
final ascent:Int
final descent:Int
final lineGap:Int
function getGlyphIndex(code:Int):Int
function getAdvance(glyph:Int):Int
function getOutline(glyph:Int):GlyphOutline
function getKerning(left:Int, right:Int):Int
```

- `new`: Reads a TrueType file (the first font of a collection).
- `unitsPerEm`: Font units in an em: what the metrics below are counted in.
- `ascent`: How far the font reaches above the baseline, in font units.
- `descent`: How far it reaches below the baseline, in font units: 0 or negative.
- `lineGap`: The extra space between lines, in font units.
- `getGlyphIndex`: The glyph of character code, or 0 (the missing glyph) when the font has none.
- `getAdvance`: How far the pen moves after glyph, in font units.
- `getOutline`: glyph's outline in font units, y up: empty for a glyph with none (a space). Composite glyphs are assembled from their parts.
- `getKerning`: The horizontal kerning between glyphs left and right, in font units: added to left's advance (usually negative, closing the pair). From GPOS pair adjustments when the font has them, else its kern table; 0 for none.
