# helix.formats.bmfont

[Back to the library](README.md)

## BmFontChar

*class* in [`libs/formats/src/helix/formats/bmfont/BmFontChar.hx`](../src/helix/formats/bmfont/BmFontChar.hx), `import helix.formats.bmfont.BmFontChar;`

Represents one glyph of a BMFont: where it is on its page, and how it is placed and advanced, in pixels.

```haxe
final id:Int
final x:Int
final y:Int
final width:Int
final height:Int
final xOffset:Int
final yOffset:Int
final xAdvance:Int
final page:Int
final channel:Int
```

- `id`: Gets the glyph's character: its Unicode codepoint (or its code in the font's charset when not Unicode).
- `x`: Gets the left of the glyph's rectangle on its page, in pixels.
- `y`: Gets the top of the glyph's rectangle on its page, in pixels, y down.
- `width`: Gets the width of the glyph's rectangle on its page, in pixels.
- `height`: Gets the height of the glyph's rectangle on its page, in pixels.
- `xOffset`: Gets how far right of the pen the rectangle is drawn, in pixels.
- `yOffset`: Gets how far below the line's top the rectangle is drawn, in pixels, y down.
- `xAdvance`: Gets how far the pen moves right after the glyph, in pixels.
- `page`: Gets the id of the page the glyph is on (`BmFontPage.id`).
- `channel`: Gets the color channels the glyph is in: 1 blue, 2 green, 4 red, 8 alpha, 15 all four.

## BmFontFile

*class* in [`libs/formats/src/helix/formats/bmfont/BmFontFile.hx`](../src/helix/formats/bmfont/BmFontFile.hx), `import helix.formats.bmfont.BmFontFile;`

Represents a bitmap font read from AngelCode BMFont's text format (.fnt): its size and line metrics, its pages, glyphs and kerning pairs, in pixels.

`read` takes the file's text and its path. The pages are images in files of their own, each path resolved against the .fnt file's directory, for the caller to load. Each line is a tag (`info`, `common`, `page`, `char`, `kerning`) and its `key=value` pairs, a value quoted when it holds spaces; unknown tags and keys are skipped, and a key a line omits reads as 0. BMFont's XML and binary formats are not read.

```haxe
var font = BmFontFile.read(text, "fonts/title.fnt");
for (page in font.pages) load(page.path);
```

```haxe
static function read(text:String, path:String):BmFontFile
final face:String
final size:Int
final lineHeight:Int
final base:Int
final scaleWidth:Int
final scaleHeight:Int
final pages:Array<BmFontPage>
final chars:Array<BmFontChar>
final kernings:Array<BmFontKerning>
```

- `read`: Reads a BMFont text file.
  - `text`: The file's text.
  - `path`: The file's path, against whose directory its pages' paths are resolved.
  - returns: The font.
  - throws `String`: It is not BMFont's text format (it has no `common` line, or is BMFont's XML or binary format), or a number in it isn't one.
- `face`: Gets the font's face name, `info`'s `face`: empty when the file gives none.
- `size`: Gets the size the font was made at, `info`'s `size`, in pixels: negative when it is the glyphs' cell height rather than the em's.
- `lineHeight`: Gets the distance from one line's top to the next's, `common`'s `lineHeight`, in pixels.
- `base`: Gets the distance from a line's top to its baseline, `common`'s `base`, in pixels.
- `scaleWidth`: Gets the width of each page's image, `common`'s `scaleW`, in pixels.
- `scaleHeight`: Gets the height of each page's image, `common`'s `scaleH`, in pixels.
- `pages`: Gets the font's pages, in the file's order.
- `chars`: Gets the font's glyphs, in the file's order.
- `kernings`: Gets the font's kerning pairs, in the file's order: empty when it has none.

## BmFontKerning

*class* in [`libs/formats/src/helix/formats/bmfont/BmFontKerning.hx`](../src/helix/formats/bmfont/BmFontKerning.hx), `import helix.formats.bmfont.BmFontKerning;`

Represents one kerning pair of a BMFont: how far the pen moves when one glyph follows another.

```haxe
final first:Int
final second:Int
final amount:Int
```

- `first`: Gets the first glyph's character (`BmFontChar.id`).
- `second`: Gets the second glyph's character, the one following the first (`BmFontChar.id`).
- `amount`: Gets how far the pen moves right, in pixels, after the first glyph's advance and before the second: negative to close up.

## BmFontPage

*class* in [`libs/formats/src/helix/formats/bmfont/BmFontPage.hx`](../src/helix/formats/bmfont/BmFontPage.hx), `import helix.formats.bmfont.BmFontPage;`

Represents one page of a BMFont: an image holding some of its glyphs, named by its id.

```haxe
final id:Int
final path:String
```

- `id`: Gets the page's id, by which a glyph names the page it is on (`BmFontChar.page`).
- `path`: Gets the path of the page's image, resolved against the .fnt file's directory.
