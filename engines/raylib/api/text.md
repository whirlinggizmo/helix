# rtext: text

[Back to the library](README.md)


```haxe
static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void
static function MeasureText(text:String, fontSize:Int):Int
static function DrawTextEx(font:Font, text:String, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void
static function DrawTextPro(font:Font, text:String, position:Vector2, origin:Vector2, rotation:Float, fontSize:Float, spacing:Float, tint:Color):Void
static function DrawTextCodepoint(font:Font, codepoint:Int, position:Vector2, fontSize:Float, tint:Color):Void
static function DrawTextCodepoints(font:Font, codepoints:Array<Int>, codepointCount:Int, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void
static function SetTextLineSpacing(spacing:Int):Void
static function MeasureTextEx(font:Font, text:String, fontSize:Float, spacing:Float):Vector2
static function GetGlyphIndex(font:Font, codepoint:Int):Int
static function GetGlyphInfo(font:Font, codepoint:Int):GlyphInfo
static function GetGlyphAtlasRec(font:Font, codepoint:Int):Rectangle
static function GetFontDefault():Font
static function IsFontValid(font:Font):Bool
static function UnloadFont(font:Font):Void
static function UnloadFontData(glyphs:Array<GlyphInfo>, glyphCount:Int):Void
static function GenImageFontAtlas(glyphs:Array<GlyphInfo>, glyphRecs:Array<Rectangle>, glyphCount:Int, fontSize:Int, padding:Int, packMethod:Int):Image
static function LoadFontFromImage(image:Image, key:Color, firstChar:Int):Font
static function DrawFPS(posX:Int, posY:Int):Void
static function TextFormat(text:String, args:haxe.extern.Rest<Dynamic>):String
static function TextIsEqual(text1:String, text2:String):Bool
static function TextLength(text:String):Int
static function TextSubtext(text:String, position:Int, length:Int):String
static function TextReplace(text:String, replace:String, by:String):String
static function TextInsert(text:String, insert:String, position:Int):String
static function TextJoin(textList:Array<String>, count:Int, delimiter:String):String
static function TextSplit(text:String, delimiter:Int, count:Array<Int>):Array<String>
static function TextFindIndex(text:String, find:String):Int
static function TextToUpper(text:String):String
static function TextToLower(text:String):String
static function TextToPascal(text:String):String
static function TextToSnake(text:String):String
static function TextToCamel(text:String):String
static function TextToInteger(text:String):Int
static function TextToFloat(text:String):Float
static function LoadUTF8(codepoints:Array<Int>, length:Int):String
static function UnloadUTF8(text:String):Void
static function LoadCodepoints(text:String, count:Array<Int>):Array<Int>
static function UnloadCodepoints(codepoints:Array<Int>):Void
static function GetCodepointCount(text:String):Int
static function GetCodepoint(text:String, codepointSize:Array<Int>):Int
static function GetCodepointNext(text:String, codepointSize:Array<Int>):Int
static function GetCodepointPrevious(text:String, codepointSize:Array<Int>):Int
static function CodepointToUTF8(codepoint:Int, utf8Size:Array<Int>):String
static macro function ExportFontAsCode(font:Font, fileName:String):Bool
static macro function LoadFontEx(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int):Font
static macro function LoadFontFromMemory(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int):Font
static macro function LoadFontData(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int):Array<GlyphInfo>
```

- `DrawText`: Draws text in raylib's default font. See `DrawTextEx` for drawing text in another font.
  - `text`: The text; "\n" starts a line.
  - `posX`: The left edge.
  - `posY`: The top edge.
  - `fontSize`: The height of a line, in pixels.
  - `color`: The color.

  A size under 10 draws at 10.

  The letters are a tenth of the size apart.
- `MeasureText`: Returns the width of text's widest line as `DrawText` draws it. See `MeasureTextEx` for measuring text's height too.
  - `text`: The text.
  - `fontSize`: The height of a line, in pixels.
  - returns: The width, in pixels.

  A size under 10 is measured at 10.
- `DrawTextEx`: Draws text in a font. See `DrawTextPro` for drawing text turned about a point.
  - `font`: The font; one with no texture draws as the default font.
  - `text`: The text; "\n" starts a line.
  - `position`: The top-left corner.
  - `fontSize`: The height of a line, in pixels; the font is scaled from its size to it.
  - `spacing`: The space between letters, in pixels.
  - `tint`: The color.

  Each "\n" moves down by the size and the space `SetTextLineSpacing` sets.
- `DrawTextPro`: Draws text in a font, turned about a point.
  - `font`: The font.
  - `text`: The text.
  - `position`: Where the point goes.
  - `origin`: The point turned about, from the text's top-left corner.
  - `rotation`: The turn, in degrees, clockwise on the screen.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, in pixels.
  - `tint`: The color.
- `DrawTextCodepoint`: Draws one character in a font. See `DrawTextCodepoints` for drawing several.
  - `font`: The font.
  - `codepoint`: The character.
  - `position`: The top-left corner of its line.
  - `fontSize`: The height of a line, in pixels.
  - `tint`: The color.
- `DrawTextCodepoints`: Draws characters in a font, as `DrawTextEx` draws text.
  - `font`: The font.
  - `codepoints`: The characters.
  - `codepointCount`: How many of them.
  - `position`: The top-left corner.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, in pixels.
  - `tint`: The color.
- `SetTextLineSpacing`: Sets the space between lines of text, added to the size at each "\n".
  - `spacing`: The space, in pixels.

  Defaults to 2 pixels.
- `MeasureTextEx`: Returns the size text is drawn at by `DrawTextEx`: its widest line's width, and its lines' height.
  - `font`: The font.
  - `text`: The text.
  - `fontSize`: The height of a line, in pixels.
  - `spacing`: The space between letters, in pixels.
  - returns: The size, in pixels; 0 by 0 for no text or a font with no texture.
- `GetGlyphIndex`: Returns the index of a character's glyph in a font.
  - `font`: The font.
  - `codepoint`: The character.
  - returns: The index; 0 for a font that isn't valid (`IsFontValid`).

  A character the font lacks gives the index of the font's "?", or 0 when the font lacks that too.
- `GetGlyphInfo`: Returns a character's glyph in a font, as `GetGlyphIndex` finds it.
  - `font`: The font.
  - `codepoint`: The character.
  - returns: The glyph.
- `GetGlyphAtlasRec`: Returns where a character's glyph is on its font's texture, as `GetGlyphIndex` finds it.
  - `font`: The font.
  - `codepoint`: The character.
  - returns: The rectangle, in texels.
- `GetFontDefault`: Returns raylib's default font, made at the first call.
  - returns: The font.

  Holds 224 glyphs, Latin-1 from the space, 10 pixels high, laid out as raylib lays them out.

  Each glyph's image is its part of the font's image, white in `PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`, so `ImageText` draws with the font.

  The font's texture goes to the GPU when first drawn.
- `IsFontValid`: Returns whether a font has a size, glyphs, and their places on its texture.
  - `font`: The font.
  - returns: True when it does.
- `UnloadFont`: Frees a font's texture and its glyphs' images.
  - `font`: The font.

  Skipped for the default font.
- `UnloadFontData`: Frees glyphs' images.
  - `glyphs`: The glyphs.
  - `glyphCount`: How many of them.
- `GenImageFontAtlas`: Packs glyphs' images into one image for a font's texture, as raylib does, and returns the image.
  - `glyphs`: The glyphs, their images 8-bit grayscale.
  - `glyphRecs`: Receives each glyph's place, replacing what it held.
  - `glyphCount`: How many glyphs; 0 for 95.
  - `fontSize`: The font's size, a row's height.
  - `padding`: The empty texels around each glyph.
  - `packMethod`: 0 packs rows in order; 1 packs by height, as raylib's skyline packer.
  - returns: The image.

  The image is white, the glyphs' coverage its alpha (`PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`).

  The image's bottom-right 3 by 3 texels are opaque white.

  The image's size is estimated from the glyphs' widths, a power of two wide.

  Packing rows in order (`packMethod` 0) doubles the image's height each time the rows run out, so every glyph has its place.

  The skyline packer (`packMethod` 1) skips a glyph that doesn't fit, logs a warning, and places the glyph at 2147483648 across and down.
- `LoadFontFromImage`: Returns a font read from an image of glyphs in rows on a key color, as raylib reads it.
  - `image`: The image, in any uncompressed format.
  - `key`: The color around the glyphs.
  - `firstChar`: The first glyph's character.
  - returns: The font.

  The key's border before the first glyph gives the space between glyphs and between rows.

  Each glyph is a run of pixels that aren't the key, numbered from `firstChar`.

  The key becomes clear on the font's texture.

  An image with no such border gives the default font.

  A glyph's height stops at the image's bottom and its width at the image's right edge.

  At most 256 glyphs are read.
- `DrawFPS`: Draws the frames a second as "60 FPS", 20 pixels high in the default font.
  - `posX`: The left edge.
  - `posY`: The top edge.

  Green at 30 or more, orange under 30, red under 15.
- `TextFormat`: Returns text formatted as C's `printf` formats it.
  - `text`: The format.
  - `args`: The values, one for each conversion.
  - returns: The text; empty for a null format.

  Takes `%d` and `%i`, `%u`, `%f` and `%F`, `%e` and `%E`, `%g` and `%G`, `%x`, `%X`, `%o`, `%c` (a character code), `%s` and `%%`.

  Takes C's flags (`-`, `0`, `+`, space, `#`), widths and precisions, as in `%5d`, `%-8s`, `%03i` and `%*d`.

  `%f` writes 6 places unless a precision is given, as in `%.2f`.

  Reads and ignores C's length modifiers (`l`, `ll`, `h`, `z`).

  Text past 1023 UTF-8 bytes is cut to its first 1020, and "..." ends it.
- `TextIsEqual`: Returns whether two texts are the same.
  - `text1`: The first text.
  - `text2`: The second text.
  - returns: True when they are; false when either is null.
- `TextLength`: Returns the length of text in UTF-8 bytes, as raylib counts it: "héllo" is 6.
  - `text`: The text.
  - returns: The length, in bytes; 0 for null text.

  The text functions' positions and lengths are all in these bytes.

  `String.length` counts otherwise, and not alike on every target.
- `TextSubtext`: Returns a piece of text, by its place in UTF-8 bytes.
  - `text`: The text.
  - `position`: Where the piece starts, in bytes from the start.
  - `length`: How long it is, in bytes.
  - returns: The piece; empty for null text, a position below 0 or at or past the end, or a length below 1.

  The piece stops at the text's end and is at most 1023 bytes.

  A character the piece cuts through becomes a "?" for each of its bytes taken.
- `TextReplace`: Returns text with every piece of it that matches replaced, from the start, each match after the one before.
  - `text`: The text.
  - `replace`: The text replaced.
  - `by`: The text put in its place.
  - returns: The new text; null when any is null or `replace` is empty.
- `TextInsert`: Returns text with other text put in at a place in UTF-8 bytes.
  - `text`: The text.
  - `insert`: The text put in.
  - `position`: Where, in bytes from the start, clamped to the end.
  - returns: The new text; empty when either is null, the position is below 0, or the result is too long.

  The result is at most 1022 bytes.

  A character the place cuts through becomes a "?" for each of its bytes.
- `TextJoin`: Returns texts joined into one, a delimiter between each two.
  - `textList`: The texts; a null one is empty.
  - `count`: How many of them.
  - `delimiter`: The text between them; null for none.
  - returns: The joined text.

  The result is at most 1023 UTF-8 bytes.

  A text that would take the result past 1023 bytes, with its delimiter, is skipped, and the texts after it are still joined.
- `TextSplit`: Returns the pieces of text between a delimiter: one more than the delimiters the text holds, an empty one between two together.
  - `text`: The text.
  - `delimiter`: The byte between pieces, such as `",".code`.
  - `count`: Receives how many pieces there are, at its index 0; 0 for null text.
  - returns: The pieces; none for null text.

  The delimiter is one byte, its low 8 bits.

  Only the text's first 1023 UTF-8 bytes are read.

  There are at most 128 pieces, the last of them empty when the text holds more.

  A character a piece cuts through becomes a "?" for each of its bytes.
- `TextFindIndex`: Returns where text is first found in other text, in UTF-8 bytes from the start, as `TextSubtext` takes it.
  - `text`: The text searched.
  - `find`: The text found; empty text is found at 0.
  - returns: The position, in bytes; -1 when it isn't there or either is null.
- `TextToUpper`: Returns text with its letters a to z made capitals.
  - `text`: The text.
  - returns: The new text; empty for null text.

  Other letters, as "é", are unchanged.
- `TextToLower`: Returns text with its capitals A to Z made lower case.
  - `text`: The text.
  - returns: The new text; empty for null text.

  Other letters, as "É", are unchanged.
- `TextToPascal`: Returns snake-case text in Pascal case: "hello_world" is "HelloWorld". See `TextToCamel` for making camel case.
  - `text`: The text.
  - returns: The new text; empty for null text.

  Drops each run of underscores, and makes the first letter and the one after each run capitals if they are a to z.

  The result is at most 1023 UTF-8 bytes.
- `TextToSnake`: Returns Pascal- or camel-case text, or words, in snake case: "helloWorld" and "Hello World" are "hello_world".
  - `text`: The text.
  - returns: The new text; empty for null text.

  Makes each capital A to Z lower case, with an underscore before it when it follows a letter a to z, or follows a capital and has a letter a to z after it. "HTTPServer" is "http_server".

  Makes each space an underscore.

  Adds no underscore at the start, nor where the text so far ends in one.

  The result is at most 1023 UTF-8 bytes.
- `TextToCamel`: Returns snake-case text in camel case: "hello_world" is "helloWorld". See `TextToPascal` for making Pascal case.
  - `text`: The text.
  - returns: The new text; empty for null text.

  Drops each run of underscores, and makes the letter after each run a capital if it is a to z.

  Makes the first letter lower case if it is A to Z.

  The result is at most 1023 UTF-8 bytes.
- `TextToInteger`: Returns the whole number text starts with: an optional "+" or "-", then the digits up to the first character that isn't one.
  - `text`: The text.
  - returns: The number; 0 when it starts with none, or for null text.

  Skips nothing, not even spaces.

  A number past 32 bits wraps.
- `TextToFloat`: Returns the number text starts with: an optional "+" or "-", digits, then a "." and more digits.
  - `text`: The text.
  - returns: The number; 0 when it starts with none, or for null text.

  Reads no exponent, as in "1e3", and skips nothing.

  Worked out in 32-bit floats, digit by digit, as raylib works it: "0.1" is 0.100000001490116.
- `LoadUTF8`: Returns the text of characters.
  - `codepoints`: The characters' codes.
  - `length`: How many of them.
  - returns: The text; a code past 0x10FFFF adds nothing.
- `UnloadUTF8`: Does nothing, since the garbage collector frees text from `LoadUTF8`.
  - `text`: The text.
- `LoadCodepoints`: Returns the codes of text's characters.
  - `text`: The text.
  - `count`: Receives how many there are, at its index 0; 0 for null text.
  - returns: The codes; null for null text.
- `UnloadCodepoints`: Does nothing, since the garbage collector frees codes from `LoadCodepoints`.
  - `codepoints`: The codes.
- `GetCodepointCount`: Returns how many characters text holds: "héllo→" holds 6, in 9 bytes.
  - `text`: The text.
  - returns: The count; 0 for null text.
- `GetCodepoint`: Returns the code of text's first character, checking its UTF-8 bytes as RFC 3629 has them. See `GetCodepointNext` for reading the character without the check.
  - `text`: The text.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by; 1 for empty or null text.
  - returns: The code; 0 for empty text, '?' (0x3F) for null text.
- `GetCodepointNext`: Returns the code of text's first character. See `GetCodepoint` for checking its UTF-8 bytes as RFC 3629 has them.
  - `text`: The text.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by, as in `TextSubtext(text, codepointSize[0], TextLength(text))`; 1 for empty or null text.
  - returns: The code; 0 for empty text, '?' (0x3F) for null text.
- `GetCodepointPrevious`: Returns the code of text's last character.
  - `text`: The text.
  - `codepointSize`: Receives the character's length in UTF-8 bytes, at its index 0: what to move back by; 1 for empty or null text.
  - returns: The code; '?' (0x3F) for empty or null text.

  `GetCodepointPrevious(TextSubtext(text, 0, position), size)` gives the character before a position.
- `CodepointToUTF8`: Returns a character as text.
  - `codepoint`: The character's code.
  - `utf8Size`: Receives its length in UTF-8 bytes, at its index 0; 0 for a code past 0x10FFFF.
  - returns: The text; empty for a code past 0x10FFFF.
- `ExportFontAsCode`: Writes a font as a C header, and returns once it is written.
  - `font`: The font.
  - `fileName`: The file.
  - returns: Whether it was written. Why it wasn't is logged.
- `LoadFontEx`: Loads a TrueType or OpenType font file at a size, and returns the font once its glyphs are ready. See `LoadFontFromMemory` for making a font from bytes already loaded.
  - `fileName`: The file, as the program names it.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
  - returns: The font, or the default font (`GetFontDefault`) when it couldn't be loaded. Why it couldn't is logged.
- `LoadFontFromMemory`: Makes a font from a TrueType or OpenType file's bytes, and returns the font once its glyphs are ready. See `LoadFontEx` for loading a file by its name.
  - `fileType`: The file's extension, ".ttf" or ".otf".
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - returns: The font, or the default font (`GetFontDefault`) when it couldn't be made. Why it couldn't is logged.
- `LoadFontData`: Rasterizes a TrueType or OpenType font's glyphs, and returns them once they are ready. See `LoadFontFromMemory` for a font ready to draw.
  - `fileData`: The font file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `type`: The glyphs' kind (`FONT_DEFAULT`, `FONT_BITMAP` or `FONT_SDF`).
  - returns: The glyphs, each with its own image, or none when the font couldn't be read. Why it couldn't is logged.


```haxe
static function LoadFontExAsync(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font -> Void, ?failed:String -> Void):Void
static function LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int, loaded:Array<GlyphInfo> -> Void, ?failed:String -> Void):Void
static function ExportFontAsCodeAsync(font:Font, fileName:String, ?done:() -> Void, ?failed:String -> Void):Void
```

- `LoadFontExAsync`: Asynchronously loads a TrueType or OpenType font file at a size, replacing raylib's `LoadFontEx`. See `LoadFontFromMemoryAsync` for making a font from bytes already loaded.
  - `fileName`: The file, as the program names it.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
  - `loaded`: Receives the font once its glyphs are ready.
  - `failed`: Optional. Receives why it couldn't be loaded; when omitted, it is logged.

  The font holds only the characters the file has. `glyphCount` may be fewer than asked for, and a character it lacks draws as its '?'.

  Each Unicode space the file has (U+0020, U+00A0, U+2000 to U+200A, U+3000 and the others) is a blank glyph as wide as its advance.
- `LoadFontFromMemoryAsync`: Asynchronously makes a font from a TrueType or OpenType file's bytes, replacing raylib's `LoadFontFromMemory`. See `LoadFontExAsync` for loading a file by its name. The glyphs are rasterized off the main thread.
  - `fileType`: The file's extension, ".ttf" or ".otf". Any other is refused.
  - `fileData`: The file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `loaded`: Receives the font once its glyphs are ready.
  - `failed`: Optional. Receives why it couldn't be made; when omitted, it is logged.

  The font holds only the characters the file has, as `LoadFontExAsync`'s does. With none of them, it is the default font.
- `LoadFontDataAsync`: Asynchronously rasterizes a TrueType or OpenType font's glyphs, each with its own image. See `LoadFontFromMemoryAsync` for a font ready to draw, replacing raylib's `LoadFontData`.
  - `fileData`: The font file's bytes.
  - `dataSize`: How many of them.
  - `fontSize`: The glyphs' size: the height of a line, in pixels.
  - `codepoints`: The characters, or null for those from the space on.
  - `codepointCount`: How many characters; 0 for 95.
  - `type`: `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances. Any other is taken as `FONT_DEFAULT`.
  - `loaded`: Receives the glyphs once they are ready.
  - `failed`: Optional. Receives why the font couldn't be read; when omitted, it is logged.

  Each glyph's image is 8-bit grayscale, for `GenImageFontAtlas`.

  Under `FONT_SDF` the images hold signed distances, with 4 texels of padding, 128 on the outline and 64 for each texel.
- `ExportFontAsCodeAsync`: Asynchronously writes a font as a C header, the text raylib 5.5's `ExportFontAsCode` writes. The file is written through `SaveFileTextAsync`, replacing raylib's `ExportFontAsCode`.
  - `font`: The font.
  - `fileName`: The file.
  - `done`: Optional. Called once the file is written, or once it is refused, at a later poll.
  - `failed`: Optional. Receives why it wasn't; when omitted, it is logged.

  The header holds the texture's pixels, each glyph's rectangle, character, offsets and advance, and a function loading the font. The file's name, in Pascal case, names them.

  The pixels are in the texture's format (gray and alpha for the default font and a TrueType font's), compressed as `CompressData` compresses them, 20 bytes a line.

  The pixels are those the font's texture was made from, or the texture's own while it hasn't been drawn.

  A texture made otherwise and already on the GPU (a render texture's) is written as an empty image, as raylib writes a texture it can't read back.
