# helix.font

[Back to the index](README.md)

## Font

*class* in [`src/helix/font/Font.hx`](../../src/helix/font/Font.hx), `import helix.font.Font;`

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

## Fonts

*class* in [`src/helix/font/Fonts.hx`](../../src/helix/font/Fonts.hx), `import helix.font.Fonts;`

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

*typedef* in [`src/helix/font/Glyph.hx`](../../src/helix/font/Glyph.hx), `import helix.font.Glyph;`

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
