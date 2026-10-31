package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.RAsync.*;
#end

/** Holds raylib's rtext (text in the default font), written here; `Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RText {
	#if !macro
	// ---- Text ----

	/** Draws text in raylib's default font. A size under 10 is drawn at 10, and letters are a tenth of the size apart.

		@param text  The text; "\n" starts a line.
		@param posX  The left edge.
		@param posY  The top edge.
		@param fontSize  The height of a line, in pixels.
		@param color  The color. */
	static function DrawText(text:String, posX:Int, posY:Int, fontSize:Int, color:Color):Void {
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		DrawTextEx(GetFontDefault(), text, new Vector2(posX, posY), fontSize, Std.int(fontSize / DefaultFont.HEIGHT), color);
	}

	/** Returns the width text is drawn at by `DrawText`, its widest line's.

		@param text  The text.
		@param fontSize  The height of a line, in pixels.
		@return  The width, in pixels. */
	static function MeasureText(text:String, fontSize:Int):Int {
		if (fontSize < DefaultFont.HEIGHT)
			fontSize = DefaultFont.HEIGHT;
		return Std.int(MeasureTextEx(GetFontDefault(), text, fontSize, Std.int(fontSize / DefaultFont.HEIGHT)).x);
	}

	/** Draws text in a font.

		@param font  The font; one with no texture draws as the default font.
		@param text  The text; "\n" starts a line.
		@param position  The top-left corner.
		@param fontSize  The height of a line, in pixels; the font is scaled from its size to it.
		@param spacing  The space between letters, in pixels.
		@param tint  The color. */
	static function DrawTextEx(font:Font, text:String, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void {
		if (font.texture == null || font.texture.id == 0)
			font = GetFontDefault();
		var x = 0., y = 0., scale = fontSize / font.baseSize;
		for (codepoint in new haxe.iterators.StringIteratorUnicode(text)) {
			var index = GetGlyphIndex(font, codepoint);
			if (codepoint == "\n".code) {
				y += fontSize + textLineSpacing;
				x = 0;
				continue;
			}
			if (codepoint != " ".code && codepoint != "\t".code)
				DrawTextCodepoint(font, codepoint, new Vector2(position.x + x, position.y + y), fontSize, tint);
			var advance = font.glyphs[index].advanceX;
			x += (advance == 0 ? font.recs[index].width : advance) * scale + spacing;
		}
	}

	/** Draws text in a font, turned about a point.

		@param font  The font.
		@param text  The text.
		@param position  Where the point goes.
		@param origin  The point turned about, from the text's top-left corner.
		@param rotation  The turn, in degrees, clockwise on the screen.
		@param fontSize  The height of a line, in pixels.
		@param spacing  The space between letters, in pixels.
		@param tint  The color. */
	static function DrawTextPro(font:Font, text:String, position:Vector2, origin:Vector2, rotation:Float, fontSize:Float, spacing:Float, tint:Color):Void {
		var frame = Runtime.frame, view = frame.view;
		var m = new Matrix3D().makeTranslation(-origin.x, -origin.y, 0);
		m = new Matrix3D().compose(m, new Matrix3D().makeRotation(0, 0, 1, rotation * DEG2RAD));
		m = new Matrix3D().compose(m, new Matrix3D().makeTranslation(position.x, position.y, 0));
		frame.cut();
		frame.view = new Matrix3D().compose(m, view);
		DrawTextEx(font, text, new Vector2(), fontSize, spacing, tint);
		frame.cut();
		frame.view = view;
	}

	/** Draws one character in a font.

		@param font  The font.
		@param codepoint  The character.
		@param position  The top-left corner of its line.
		@param fontSize  The height of a line, in pixels.
		@param tint  The color. */
	static function DrawTextCodepoint(font:Font, codepoint:Int, position:Vector2, fontSize:Float, tint:Color):Void {
		var index = GetGlyphIndex(font, codepoint);
		var scale = fontSize / font.baseSize,
			padding = font.glyphPadding,
			glyph = font.glyphs[index],
			rec = font.recs[index];
		var dest = new Rectangle(position.x + glyph.offsetX * scale - padding * scale, position.y + glyph.offsetY * scale - padding * scale,
			(rec.width + 2 * padding) * scale, (rec.height + 2 * padding) * scale);
		var source = new Rectangle(rec.x - padding, rec.y - padding, rec.width + 2 * padding, rec.height + 2 * padding);
		DrawTexturePro(font.texture, source, dest, new Vector2(), 0, tint);
	}

	/** Draws characters in a font, as `DrawTextEx` draws text.

		@param font  The font.
		@param codepoints  The characters.
		@param codepointCount  How many of them.
		@param position  The top-left corner.
		@param fontSize  The height of a line, in pixels.
		@param spacing  The space between letters, in pixels.
		@param tint  The color. */
	static function DrawTextCodepoints(font:Font, codepoints:Array<Int>, codepointCount:Int, position:Vector2, fontSize:Float, spacing:Float, tint:Color):Void {
		var x = 0., y = 0., scale = fontSize / font.baseSize;
		for (i in 0...codepointCount) {
			var codepoint = codepoints[i],
				index = GetGlyphIndex(font, codepoint);
			if (codepoint == "\n".code) {
				y += fontSize + textLineSpacing;
				x = 0;
				continue;
			}
			if (codepoint != " ".code && codepoint != "\t".code)
				DrawTextCodepoint(font, codepoint, new Vector2(position.x + x, position.y + y), fontSize, tint);
			var advance = font.glyphs[index].advanceX;
			x += (advance == 0 ? font.recs[index].width : advance) * scale + spacing;
		}
	}

	/** Sets the space between lines that "\n" adds to the size, 2 pixels until set.

		@param spacing  The space, in pixels. */
	static function SetTextLineSpacing(spacing:Int):Void {
		textLineSpacing = spacing;
	}

	/** Returns the size text is drawn at by `DrawTextEx`: its widest line's width, and its lines' height.

		@param font  The font.
		@param text  The text.
		@param fontSize  The height of a line, in pixels.
		@param spacing  The space between letters, in pixels.
		@return  The size, in pixels; 0 by 0 for no text or a font with no texture. */
	static function MeasureTextEx(font:Font, text:String, fontSize:Float, spacing:Float):Vector2 {
		if (font.texture == null || font.texture.id == 0 || text == null || text.length == 0)
			return new Vector2();
		var width = 0., widest = 0., height = fontSize, count = 0, most = 0;
		for (codepoint in new haxe.iterators.StringIteratorUnicode(text)) {
			count++;
			var index = GetGlyphIndex(font, codepoint);
			if (codepoint != "\n".code) {
				var glyph = font.glyphs[index];
				width += glyph.advanceX > 0 ? glyph.advanceX : font.recs[index].width + glyph.offsetX;
			} else {
				if (widest < width)
					widest = width;
				count = 0;
				width = 0;
				height += fontSize + textLineSpacing;
			}
			if (most < count)
				most = count;
		}
		if (widest < width)
			widest = width;
		return new Vector2(widest * fontSize / font.baseSize + (most - 1) * spacing, height);
	}

	/** Returns where a character is in a font's glyphs: its own, else the question mark's, else the first.

		@param font  The font.
		@param codepoint  The character.
		@return  The index. */
	static function GetGlyphIndex(font:Font, codepoint:Int):Int {
		var fallback = 0;
		for (i in 0...font.glyphCount) {
			if (font.glyphs[i].value == "?".code)
				fallback = i;
			if (font.glyphs[i].value == codepoint)
				return i;
		}
		return fallback;
	}

	/** Returns a character's glyph in a font, as `GetGlyphIndex` finds it.

		@param font  The font.
		@param codepoint  The character.
		@return  The glyph. */
	static function GetGlyphInfo(font:Font, codepoint:Int):GlyphInfo {
		return font.glyphs[GetGlyphIndex(font, codepoint)];
	}

	/** Returns where a character's glyph is on its font's texture, as `GetGlyphIndex` finds it.

		@param font  The font.
		@param codepoint  The character.
		@return  The rectangle, in texels. */
	static function GetGlyphAtlasRec(font:Font, codepoint:Int):Rectangle {
		return font.recs[GetGlyphIndex(font, codepoint)];
	}

	/** Returns raylib's default font: 224 glyphs, Latin-1 from the space, 10 pixels high, on a texture made at its first use.

		@return  The font. */
	static function GetFontDefault():Font {
		if (fontDefault != null)
			return fontDefault;
		var font = new Font();
		font.texture = defaultFont();
		font.baseSize = DefaultFont.HEIGHT;
		font.glyphCount = DefaultFont.WIDTHS.length;
		for (i in 0...font.glyphCount) {
			font.recs.push(new Rectangle(fontRecs[i * 2], fontRecs[i * 2 + 1], DefaultFont.WIDTHS[i], DefaultFont.HEIGHT));
			var glyph = new GlyphInfo();
			glyph.value = 32 + i;
			glyph.image = new Image();
			font.glyphs.push(glyph);
		}
		return fontDefault = font;
	}

	/** Returns whether a font holds glyphs: a size, glyphs, and their places on its texture.

		@param font  The font.
		@return  True when it does. */
	static function IsFontValid(font:Font):Bool {
		return font.baseSize > 0 && font.glyphCount > 0 && font.recs != null && font.glyphs != null;
	}

	/** Frees a font: its texture and its glyphs' images. The default font is never freed.

		@param font  The font. */
	static function UnloadFont(font:Font):Void {
		if (font == fontDefault || font.texture == GetFontDefault().texture)
			return;
		UnloadFontData(font.glyphs, font.glyphCount);
		UnloadTexture(font.texture);
	}

	/** Frees glyphs' images.

		@param glyphs  The glyphs.
		@param glyphCount  How many of them. */
	static function UnloadFontData(glyphs:Array<GlyphInfo>, glyphCount:Int):Void {
		for (i in 0...glyphCount)
			if (glyphs[i].image != null)
				UnloadImage(glyphs[i].image);
	}

	/** Packs glyphs' images into one image, a font's texture once loaded, as raylib does: its glyphs' places go into `glyphRecs`, the
		image is white with the glyphs' coverage as alpha (`PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`), and its bottom-right 3 by 3 texels are
		opaque white.

		@param glyphs  The glyphs, their images 8-bit grayscale.
		@param glyphRecs  Receives each glyph's place, replacing what it held.
		@param glyphCount  How many glyphs; 0 for 95.
		@param fontSize  The font's size, a row's height.
		@param padding  The empty texels around each glyph.
		@param packMethod  0 packs rows in order; 1 packs by height, as raylib's skyline packer.
		@return  The image. */
	static function GenImageFontAtlas(glyphs:Array<GlyphInfo>, glyphRecs:Array<Rectangle>, glyphCount:Int, fontSize:Int, padding:Int, packMethod:Int):Image {
		var atlas = new Image();
		if (glyphs == null) {
			Runtime.log(LOG_WARNING, "FONT: Provided chars info not valid, returning empty image atlas");
			return atlas;
		}
		glyphCount = glyphCount > 0 ? glyphCount : 95;
		var total = 0;
		for (i in 0...glyphCount)
			total += glyphs[i].image.width + 2 * padding;
		var padded = fontSize + 2 * padding;
		var area = total * padded * 1.2,
			size = Std.int(Math.pow(2, Math.ceil(Math.log(Math.sqrt(area)) / Math.log(2))));
		atlas.width = size;
		atlas.height = area < size * size / 2 ? Std.int(size / 2) : size;
		var gray = haxe.io.Bytes.alloc(atlas.width * atlas.height);
		var recs = [for (_ in 0...glyphCount) new Rectangle()];
		inline function blit(glyph:GlyphInfo, left:Int, top:Int)
			for (y in 0...glyph.image.height)
				for (x in 0...glyph.image.width)
					gray.set((top + y) * atlas.width + left + x, (glyph.image.data : haxe.io.Bytes).get(y * glyph.image.width + x));
		if (packMethod == 0) {
			var x = padding, y = padding;
			for (i in 0...glyphCount) {
				var glyph = glyphs[i];
				if (x >= atlas.width - glyph.image.width - 2 * padding) {
					x = padding;
					y += fontSize + 2 * padding;
					if (y > atlas.height - fontSize - padding) {
						for (j in i + 1...glyphCount)
							Runtime.log(LOG_WARNING, 'FONT: Failed to package character ($j)');
						break;
					}
				}
				blit(glyph, x, y);
				recs[i] = new Rectangle(x, y, glyph.image.width, glyph.image.height);
				x += glyph.image.width + 2 * padding;
			}
		} else if (packMethod == 1) {
			var sizes = [];
			for (i in 0...glyphCount) {
				sizes.push(glyphs[i].image.width + 2 * padding);
				sizes.push(glyphs[i].image.height + 2 * padding);
			}
			var places = helix.math.RectPacker2D.pack(atlas.width, atlas.height, sizes);
			for (i in 0...glyphCount) {
				var glyph = glyphs[i],
					x = places[i * 3] + padding,
					y = places[i * 3 + 1] + padding;
				recs[i] = new Rectangle(x, y, glyph.image.width, glyph.image.height);
				if (places[i * 3 + 2] == 1)
					blit(glyph, x, y);
				else
					Runtime.log(LOG_WARNING, 'FONT: Failed to package character ($i)');
			}
		}
		// raylib's white texels, for shapes drawn from the font's texture.
		for (i in 0...3)
			for (j in 0...3)
				gray.set((atlas.height - 1 - i) * atlas.width + atlas.width - 1 - j, 255);
		var pixels = haxe.io.Bytes.alloc(atlas.width * atlas.height * 2);
		for (i in 0...atlas.width * atlas.height) {
			pixels.set(i * 2, 255);
			pixels.set(i * 2 + 1, gray.get(i));
		}
		atlas.data = pixels;
		atlas.format = PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA;
		atlas.mipmaps = 1;
		glyphRecs.resize(0);
		for (r in recs)
			glyphRecs.push(r);
		return atlas;
	}

	/** raylib's font load, which waits for the file. A page can't wait, so a call doesn't compile on any target: `LoadFontAsync` loads
		it.

		@param fileName  The file.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadFont: Synchronous loading is not supported. See LoadFontAsync(fileName:String, loaded:Font->Void, ?failed:String->Void)")
	static function LoadFont(fileName:String):Font {
		throw "LoadFont is unimplemented";
	}

	/** raylib's font load at a size, which waits for the file. A page can't wait, so a call doesn't compile on any target:
		`LoadFontExAsync` loads it.

		@param fileName  The file.
		@param fontSize  The size.
		@param codepoints  The characters.
		@param codepointCount  How many of them.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadFontEx: Synchronous loading is not supported. See LoadFontExAsync(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font->Void, ?failed:String->Void)")
	static function LoadFontEx(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int):Font {
		throw "LoadFontEx is unimplemented";
	}

	/** raylib's font load from a file's bytes, which rasterizes the glyphs before it returns. They are rasterized off the main thread
		here, so a call doesn't compile on any target: `LoadFontFromMemoryAsync` loads it.

		@param fileType  The file's extension.
		@param fileData  The file's bytes.
		@param dataSize  How many.
		@param fontSize  The size.
		@param codepoints  The characters.
		@param codepointCount  How many of them.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadFontFromMemory: Fonts are rasterized asynchronously. See LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font->Void, ?failed:String->Void)")
	static function LoadFontFromMemory(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int):Font {
		throw "LoadFontFromMemory is unimplemented";
	}

	/** raylib's glyph rasterizing, which returns the glyphs. They are rasterized off the main thread here, so a call doesn't compile on
		any target: `LoadFontDataAsync` rasterizes them.

		@param fileData  The font file's bytes.
		@param dataSize  How many.
		@param fontSize  The size.
		@param codepoints  The characters.
		@param codepointCount  How many of them.
		@param type  The glyphs' kind (`FONT_*`).
		@return  Never returns: a call doesn't compile. */
	@:unsupported("LoadFontData: Fonts are rasterized asynchronously. See LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int, loaded:Array<GlyphInfo>->Void, ?failed:String->Void)")
	static function LoadFontData(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int):Array<GlyphInfo> {
		throw "LoadFontData is unimplemented";
	}

	// raylib's LoadFontData, from the platform's glyphs: a glyph the font lacks is empty, a space is a blank image as wide as its advance,
	// and offsets are from the line's top.
	static function fontData(raster:Array<helix.platform.RasterGlyph>, ascent:Float, fontSize:Int, type:Int):Array<GlyphInfo> {
		return [
			for (r in raster) {
				var glyph = new GlyphInfo();
				glyph.value = r.codepoint;
				glyph.image = new Image();
				if (r.found) {
					glyph.offsetX = r.offsetX;
					glyph.offsetY = r.offsetY;
					if (r.width > 0 && r.height > 0 && !(type == FONT_SDF && r.codepoint == " ".code)) {
						glyph.advanceX = Std.int(r.advance);
						glyph.offsetY += Std.int(ascent);
						glyph.image.data = r.pixels;
						glyph.image.width = r.width;
						glyph.image.height = r.height;
						glyph.image.mipmaps = 1;
						glyph.image.format = PIXELFORMAT_UNCOMPRESSED_GRAYSCALE;
						if (type == FONT_BITMAP)
							for (i in 0...r.pixels.length)
								r.pixels.set(i, r.pixels.get(i) < 80 ? 0 : 255);
					}
					if (r.codepoint == " ".code) {
						glyph.advanceX = Std.int(r.advance);
						glyph.image.data = haxe.io.Bytes.alloc(glyph.advanceX * fontSize);
						glyph.image.width = glyph.advanceX;
						glyph.image.height = fontSize;
						glyph.image.mipmaps = 1;
						glyph.image.format = PIXELFORMAT_UNCOMPRESSED_GRAYSCALE;
					}
				}
				glyph;
			}
		];
	}

	// raylib's LoadFontFromMemory, from the glyphs: packed with 4 texels of padding into the texture, each glyph's image its part of it.
	static function fontOf(glyphs:Array<GlyphInfo>, fontSize:Int):Font {
		var font = new Font();
		font.baseSize = fontSize;
		font.glyphCount = glyphs.length;
		font.glyphs = glyphs;
		font.glyphPadding = 4;
		var atlas = GenImageFontAtlas(glyphs, font.recs, font.glyphCount, font.baseSize, font.glyphPadding, 0);
		font.texture = LoadTextureFromImage(atlas);
		for (i in 0...font.glyphCount) {
			var rec = font.recs[i],
				image = new Image(),
				part = haxe.io.Bytes.alloc(Std.int(rec.width * rec.height) * 2);
			for (y in 0...Std.int(rec.height))
				part.blit(y * Std.int(rec.width) * 2, atlas.data, ((Std.int(rec.y) + y) * atlas.width + Std.int(rec.x)) * 2, Std.int(rec.width) * 2);
			image.data = part;
			image.width = Std.int(rec.width);
			image.height = Std.int(rec.height);
			image.mipmaps = 1;
			image.format = PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA;
			font.glyphs[i].image = image;
		}
		Runtime.log(LOG_INFO, 'FONT: Data loaded successfully (${font.baseSize} pixel size | ${font.glyphCount} glyphs)');
		return font;
	}

	// raylib's LoadBMFont, from what the fonts service read: its size the line height, no padding, each glyph's offset from the line's
	// top and its image its part of the atlas.
	static function fromBmFont(read:helix.services.fonts.Font2D):Font {
		var font = new Font(), atlas = read.atlas;
		font.baseSize = Std.int(read.size);
		font.glyphCount = read.glyphs.length;
		font.glyphPadding = 0;
		font.texture = new Texture2D(Textures.fromImage(atlas.path, atlas), atlas.width, atlas.height);
		for (g in read.glyphs) {
			font.recs.push(new Rectangle(g.x, g.y, g.width, g.height));
			var glyph = new GlyphInfo();
			glyph.value = g.codepoint;
			glyph.offsetX = Std.int(g.offsetX);
			glyph.offsetY = Std.int(g.offsetY + read.ascent);
			glyph.advanceX = Std.int(g.advance);
			glyph.image = new Image();
			// A character placed past its page's edge, which a .fnt may claim, reads as empty there.
			var part = haxe.io.Bytes.alloc(g.width * g.height * 4),
				inside = g.x + g.width <= atlas.width ? g.width : atlas.width - g.x;
			for (row in 0...g.height)
				if (g.y + row < atlas.height && inside > 0)
					part.blit(row * g.width * 4, atlas.pixels, ((g.y + row) * atlas.width + g.x) * 4, inside * 4);
			glyph.image.data = part;
			glyph.image.width = g.width;
			glyph.image.height = g.height;
			glyph.image.mipmaps = 1;
			glyph.image.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
			font.glyphs.push(glyph);
		}
		return font;
	}

	static var textLineSpacing = 2;
	static var fontDefault:Null<Font> = null;

	/** Draws the frames a second, as "60 FPS", in green.

		@param posX  The left edge.
		@param posY  The top edge. */
	static function DrawFPS(posX:Int, posY:Int):Void {
		var fps = GetFPS();
		var color = fps < 15 ? RED : fps < 30 ? ORANGE : LIME;
		DrawText('${fps < 10 ? " " : ""}$fps FPS', posX, posY, 20, color);
	}

	// ---- Text strings ----

	/** Formats text as C's `printf` does. It takes `%d` and `%i`, `%u`, `%f` and `%F` (6 places unless a precision is given, as in
		`%.2f`), `%e`, `%g`, `%x`, `%X`, `%o`, `%c` (a character code), `%s` and `%%`. It also takes C's flags (`-`, `0`, `+`, space,
		`#`), widths and precisions, as in `%5d`, `%-8s`, `%03i` and `%*d`. C's length modifiers (`l`, `ll`, `h`, `z`) are read and
		ignored.

		@param text  The format.
		@param args  The values, one for each conversion.
		@return  The text. */
	static function TextFormat(text:String, args:haxe.extern.Rest<Dynamic>):String {
		var out = new StringBuf();
		var next = 0;
		var i = 0;
		function take():Dynamic
			return next < args.length ? args[next++] : null;
		function digits():Int {
			var n = 0;
			while (i < text.length && text.charCodeAt(i) >= "0".code && text.charCodeAt(i) <= "9".code)
				n = n * 10 + text.charCodeAt(i++) - "0".code;
			return n;
		}
		while (i < text.length) {
			var c = text.charAt(i++);
			if (c != "%") {
				out.add(c);
				continue;
			}
			var flags = "";
			while (i < text.length && "-0+ #".indexOf(text.charAt(i)) >= 0)
				flags += text.charAt(i++);
			var width = 0;
			if (text.charAt(i) == "*") {
				i++;
				width = Std.int(number(take()));
				if (width < 0) {
					flags += "-";
					width = -width;
				}
			} else
				width = digits();
			var precision = -1;
			if (text.charAt(i) == ".") {
				i++;
				if (text.charAt(i) == "*") {
					i++;
					precision = Std.int(number(take()));
				} else
					precision = digits();
			}
			while (i < text.length && "hlLqjzt".indexOf(text.charAt(i)) >= 0)
				i++;
			if (i >= text.length)
				break;
			var conversion = text.charAt(i++);
			if (conversion == "%") {
				out.add("%");
				continue;
			}
			out.add(formatted(conversion, take(), flags, width, precision));
		}
		return out.toString();
	}

	// One conversion of TextFormat's, padded to its width.
	static function formatted(conversion:String, value:Dynamic, flags:String, width:Int, precision:Int):String {
		var sign = "", body = "", numeric = true;
		var v = number(value);
		switch conversion {
			case "d" | "i":
				var whole = Std.int(v);
				sign = whole < 0 ? "-" : flags.indexOf("+") >= 0 ? "+" : flags.indexOf(" ") >= 0 ? " " : "";
				body = wholeDigits(Math.abs(whole));
				while (body.length < precision)
					body = "0" + body;
			case "u":
				var whole:Float = Std.int(v);
				body = wholeDigits(whole < 0 ? whole + 4294967296.0 : whole);
			case "x" | "X" | "o":
				var whole = Std.int(v);
				if (conversion == "o") {
					body = whole == 0 ? "0" : "";
					while (whole != 0) {
						body = (whole & 7) + body;
						whole = whole >>> 3;
					}
				} else {
					body = StringTools.hex(whole);
					if (whole < 0)
						body = body.substr(body.length - 8);
					if (conversion == "x")
						body = body.toLowerCase();
				}
				while (body.length < precision)
					body = "0" + body;
				if (flags.indexOf("#") >= 0 && Std.int(v) != 0)
					body = (conversion == "o" ? "0" : conversion == "x" ? "0x" : "0X") + body;
			case "f" | "F" | "e" | "E" | "g" | "G":
				sign = v < 0 || 1 / v < 0 ? "-" : flags.indexOf("+") >= 0 ? "+" : flags.indexOf(" ") >= 0 ? " " : "";
				var size = Math.abs(v);
				var upper = conversion == conversion.toUpperCase();
				var places = precision < 0 ? 6 : precision;
				if (Math.isNaN(size))
					body = upper ? "NAN" : "nan";
				else if (!Math.isFinite(size))
					body = upper ? "INF" : "inf";
				else if (conversion == "f" || conversion == "F")
					body = fixed(size, places);
				else if (conversion == "e" || conversion == "E")
					body = exponent(size, places, upper);
				else {
					var p = precision < 0 ? 6 : precision == 0 ? 1 : precision;
					var e = size == 0 ? 0 : Std.parseInt(exponent(size, p - 1, false).split("e")[1]);
					body = p > e && e >= -4 ? fixed(size, p - 1 - e) : exponent(size, p - 1, upper);
					if (flags.indexOf("#") < 0)
						body = trimmed(body);
				}
				if (!Math.isFinite(size))
					numeric = false;
			case "c":
				numeric = false;
				body = String.fromCharCode(Std.int(v));
			case _:
				numeric = false;
				body = value == null ? "(null)" : Std.string(value);
				if (precision >= 0 && conversion == "s")
					body = body.substr(0, precision);
		}
		var length = sign.length + body.length;
		if (width <= length)
			return sign + body;
		var fill = StringTools.rpad("", " ", width - length);
		if (flags.indexOf("-") >= 0)
			return sign + body + fill;
		var zeros = numeric && flags.indexOf("0") >= 0 && !(precision >= 0 && "dixXou".indexOf(conversion) >= 0);
		return zeros ? sign + StringTools.rpad("", "0", width - length) + body : fill + sign + body;
	}

	// A value of TextFormat's as a number: an Int's or a Float's own, a Bool's 1 or 0, text's as parsed.
	static function number(value:Dynamic):Float {
		if (value == null)
			return 0;
		if (Std.isOfType(value, Int))
			return (value : Int);
		if (Std.isOfType(value, Float))
			return (value : Float);
		if (Std.isOfType(value, Bool))
			return value ? 1 : 0;
		return Std.parseFloat(Std.string(value));
	}

	// A whole number held in a Float, in decimal digits, however large.
	static function wholeDigits(x:Float):String {
		if (x < 2147483648.0)
			return Std.string(Std.int(x));
		var out = "";
		while (x >= 1) {
			out = Std.int(x % 10) + out;
			x = Math.ffloor(x / 10);
		}
		return out;
	}

	// A number not below 0 with a number of decimal places, rounded as C rounds it.
	static function fixed(x:Float, places:Int):String {
		var scale = Math.pow(10, places);
		var rounded = scaled(x, scale);
		var whole = Math.ffloor(rounded / scale);
		if (places == 0)
			return wholeDigits(whole);
		var fraction = wholeDigits(rounded - whole * scale);
		while (fraction.length < places)
			fraction = "0" + fraction;
		return wholeDigits(whole) + "." + fraction;
	}

	// x times scale, a power of 10, rounded to a whole number as C's printf rounds: to the nearest, a tie to even, judged on the exact
	// product. A product that rounds to a half is a tie only when the multiplication was exact; its error, found as Dekker's product
	// finds it, says which way it leans.
	static function scaled(x:Float, scale:Float):Float {
		var product = x * scale;
		var whole = Math.ffloor(product);
		var fraction = product - whole;
		if (fraction != 0.5)
			return fraction < 0.5 ? whole : whole + 1;
		var error = productError(x, scale, product);
		return error < 0 ? whole : error > 0 ? whole + 1 : whole % 2 == 0 ? whole : whole + 1;
	}

	// a * b - product, exactly, for product the rounded a * b.
	static function productError(a:Float, b:Float, product:Float):Float {
		var ca = 134217729.0 * a, cb = 134217729.0 * b;
		var aHigh = ca - (ca - a), bHigh = cb - (cb - b);
		var aLow = a - aHigh, bLow = b - bHigh;
		return ((aHigh * bHigh - product) + aHigh * bLow + aLow * bHigh) + aLow * bLow;
	}

	// A number not below 0 as C's %e has it: one digit, the places after it, and the exponent of 10, at least two digits.
	static function exponent(x:Float, places:Int, upper:Bool):String {
		var e = x == 0 ? 0 : Math.floor(Math.log(x) / Math.log(10));
		var mantissa = x == 0 ? "0" : fixed(x / Math.pow(10, e), places);
		// The logarithm can miss by one, and rounding can carry to 10.
		if (x != 0 && Std.parseFloat(mantissa) >= 10) {
			e++;
			mantissa = fixed(x / Math.pow(10, e), places);
		} else if (x != 0 && Std.parseFloat(mantissa) < 1) {
			e--;
			mantissa = fixed(x / Math.pow(10, e), places);
		}
		if (x == 0 && places > 0)
			mantissa = fixed(0, places);
		var power = Std.string(Std.int(Math.abs(e)));
		return mantissa + (upper ? "E" : "e") + (e < 0 ? "-" : "+") + (power.length < 2 ? "0" + power : power);
	}

	// %g's text without the zeros ending its fraction, nor a point left alone.
	static function trimmed(text:String):String {
		var parts = text.split(text.indexOf("E") >= 0 ? "E" : "e");
		var number = parts[0];
		if (number.indexOf(".") >= 0) {
			while (StringTools.endsWith(number, "0"))
				number = number.substr(0, number.length - 1);
			if (StringTools.endsWith(number, "."))
				number = number.substr(0, number.length - 1);
		}
		return parts.length > 1 ? number + (text.indexOf("E") >= 0 ? "E" : "e") + parts[1] : number;
	}
	#end
}
