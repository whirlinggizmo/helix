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
		var m = Matrix3D.fromTranslation(-origin.x, -origin.y, 0);
		m = Matrix3D.compose(m, Matrix3D.fromRotation(0, 0, 1, rotation * DEG2RAD));
		m = Matrix3D.compose(m, Matrix3D.fromTranslation(position.x, position.y, 0));
		frame.cut();
		frame.view = Matrix3D.compose(m, view);
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
		// raylib's float arithmetic, each step rounded to single precision.
		inline function f32(x:Float):Float
			return helix.ray.internal.Pixels.f32(x);
		fontSize = f32(fontSize);
		var width = 0., widest = 0., height = fontSize, count = 0, most = 0, scale = f32(fontSize / font.baseSize);
		for (codepoint in new haxe.iterators.StringIteratorUnicode(text)) {
			count++;
			var index = GetGlyphIndex(font, codepoint);
			if (codepoint != "\n".code) {
				var glyph = font.glyphs[index];
				width = f32(width + (glyph.advanceX > 0 ? glyph.advanceX : f32(f32(font.recs[index].width) + glyph.offsetX)));
			} else {
				if (widest < width)
					widest = width;
				count = 0;
				width = 0;
				height = f32(height + f32(fontSize + textLineSpacing));
			}
			if (most < count)
				most = count;
		}
		if (widest < width)
			widest = width;
		return new Vector2(f32(f32(widest * scale) + f32((most - 1) * f32(spacing))), height);
	}

	/** Returns where a character is in a font's glyphs: its own, else the question mark's, else the first.

		@param font  The font.
		@param codepoint  The character.
		@return  The index; 0 for a font that isn't valid (`IsFontValid`). */
	static function GetGlyphIndex(font:Font, codepoint:Int):Int {
		if (!IsFontValid(font))
			return 0;
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

	/** Returns raylib's default font: 224 glyphs, Latin-1 from the space, 10 pixels high, made at its first use as raylib makes it, each
		glyph's image its part of the font's image (`PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA`, white), so `ImageText` draws with it. Its
		texture goes to the GPU when first drawn.

		@return  The font. */
	static function GetFontDefault():Font {
		if (fontDefault != null)
			return fontDefault;
		var size = 128, pixels = haxe.io.Bytes.alloc(size * size * 2);
		// White, opaque where a glyph's bit is set, clear elsewhere.
		for (i in 0...size * size >> 5) {
			var word = DefaultFont.BITS[i];
			for (j in 0...32)
				pixels.setUInt16((i * 32 + j) * 2, (word >>> j) & 1 == 1 ? 0xffff : 0x00ff);
		}
		var image = new Image(pixels, size, size, 1, PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA);
		var font = new Font();
		font.glyphCount = DefaultFont.WIDTHS.length;
		font.glyphPadding = 0;
		font.texture = LoadTextureFromImage(image);
		keepAtlas(font, image);
		// raylib's layout: rows of glyphs a pixel apart, a row ending where the next glyph would reach the texture's edge.
		var line = 0, x = 1, test = 1;
		for (i in 0...font.glyphCount) {
			var w = DefaultFont.WIDTHS[i];
			var rec = new Rectangle(x, 1 + line * (DefaultFont.HEIGHT + 1), w, DefaultFont.HEIGHT);
			test += w + 1;
			if (test >= font.texture.width) {
				line++;
				x = 2 + w;
				test = x;
				rec.x = 1;
				rec.y = 1 + line * (DefaultFont.HEIGHT + 1);
			} else
				x = test;
			font.recs.push(rec);
			var glyph = new GlyphInfo();
			glyph.value = 32 + i;
			glyph.image = ImageFromImage(image, rec);
			font.glyphs.push(glyph);
		}
		font.baseSize = DefaultFont.HEIGHT;
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

	/** Writes a font as a C header through `SaveFileText`, the text raylib 5.5's writes: its texture's pixels in the texture's format
		(gray and alpha for the default font and a TrueType font's), compressed as `CompressData` compresses them, 20 bytes a line; each
		glyph's rectangle and its character, offsets and advance; and a function loading it. The file's name, in Pascal case, names
		them. The pixels are those the font's texture was made from, or the texture's own while it hasn't been drawn; one made otherwise
		and already on the GPU (a render texture's) is written as an empty image, as raylib writes a texture it can't read back.

		@param font  The font.
		@param fileName  The file.
		@return  True when it was written. */
	static function ExportFontAsCode(font:Font, fileName:String):Bool {
		var name = TextToPascal(GetFileNameWithoutExt(fileName));
		var upperName = TextToUpper(name);
		var text = new StringBuf();
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n");
		text.add("//                                                                                    //\n");
		text.add("// FontAsCode exporter v1.0 - Font data exported as an array of bytes                 //\n");
		text.add("//                                                                                    //\n");
		text.add("// more info and bugs-report:  github.com/raysan5/raylib                              //\n");
		text.add("// feedback and support:       ray[at]raylib.com                                      //\n");
		text.add("//                                                                                    //\n");
		text.add("// Copyright (c) 2018-2024 Ramon Santamaria (@raysan5)                                //\n");
		text.add("//                                                                                    //\n");
		text.add("// ---------------------------------------------------------------------------------- //\n");
		text.add("//                                                                                    //\n");
		text.add("// TODO: Fill the information and license of the exported font here:                  //\n");
		text.add("//                                                                                    //\n");
		text.add("// Font name:    ....                                                                 //\n");
		text.add("// Font creator: ....                                                                 //\n");
		text.add("// Font LICENSE: ....                                                                 //\n");
		text.add("//                                                                                    //\n");
		text.add("////////////////////////////////////////////////////////////////////////////////////////\n\n");
		var image = atlasOf(font);
		if (image.format != PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA)
			Runtime.log(LOG_WARNING, "Font export as code: Font image format is not GRAY+ALPHA!");
		var imageDataSize = GetPixelDataSize(image.width, image.height, image.format);
		var data = image.data == null ? haxe.io.Bytes.alloc(0) : image.data;
		var compDataSize = [0];
		var compData = CompressData(data, imageDataSize < data.length ? imageDataSize : data.length, compDataSize);
		inline function hex(b:Int):String
			return StringTools.hex(b, 2).toLowerCase();
		text.add('#define COMPRESSED_DATA_SIZE_FONT_$upperName ${compDataSize[0]}\n\n');
		text.add("// Font image pixels data compressed (DEFLATE)\n");
		text.add("// NOTE: Original pixel data simplified to GRAYSCALE\n");
		text.add('static unsigned char fontData_$name[COMPRESSED_DATA_SIZE_FONT_$upperName] = { ');
		for (i in 0...compDataSize[0] - 1)
			text.add(i % 20 == 0 ? '0x${hex(compData.get(i))},\n    ' : '0x${hex(compData.get(i))}, ');
		text.add('0x${hex(compData.get(compDataSize[0] - 1))} };\n\n');
		text.add("// Font characters rectangles data\n");
		text.add('static Rectangle fontRecs_$name[${font.glyphCount}] = {\n');
		for (i in 0...font.glyphCount) {
			var r = font.recs[i];
			text.add('    { ${whole(r.x)}, ${whole(r.y)}, ${whole(r.width)} , ${whole(r.height)} },\n');
		}
		text.add("};\n\n");
		text.add("// Font glyphs info data\n");
		text.add("// NOTE: No glyphs.image data provided\n");
		text.add('static GlyphInfo fontGlyphs_$name[${font.glyphCount}] = {\n');
		for (i in 0...font.glyphCount) {
			var g = font.glyphs[i];
			text.add('    { ${g.value}, ${g.offsetX}, ${g.offsetY}, ${g.advanceX}, { 0 }},\n');
		}
		text.add("};\n\n");
		text.add('// Font loading function: $name\n');
		text.add('static Font LoadFont_$name(void)\n{\n');
		text.add("    Font font = { 0 };\n\n");
		text.add('    font.baseSize = ${font.baseSize};\n');
		text.add('    font.glyphCount = ${font.glyphCount};\n');
		text.add('    font.glyphPadding = ${font.glyphPadding};\n\n');
		text.add("    // Custom font loading\n");
		text.add("    // NOTE: Compressed font image data (DEFLATE), it requires DecompressData() function\n");
		text.add('    int fontDataSize_$name = 0;\n');
		text.add('    unsigned char *data = DecompressData(fontData_$name, COMPRESSED_DATA_SIZE_FONT_$upperName, &fontDataSize_$name);\n');
		text.add('    Image imFont = { data, ${image.width}, ${image.height}, 1, ${image.format} };\n\n');
		text.add("    // Load texture from image\n");
		text.add("    if (isGpuReady) font.texture = LoadTextureFromImage(imFont);\n");
		text.add("    UnloadImage(imFont);  // Uncompressed data can be unloaded from memory\n\n");
		text.add("    // Assign glyph recs and info data directly\n");
		text.add("    // WARNING: This font data must not be unloaded\n");
		text.add('    font.recs = fontRecs_$name;\n');
		text.add('    font.glyphs = fontGlyphs_$name;\n\n');
		text.add("    return font;\n");
		text.add("}\n");
		var success = SaveFileText(fileName, text.toString());
		if (success)
			Runtime.log(LOG_INFO, 'FILEIO: [$fileName] Font as code exported successfully');
		else
			Runtime.log(LOG_WARNING, 'FILEIO: [$fileName] Failed to export font as code');
		return success;
	}

	// A font's texture's pixels as raylib's LoadImageFromTexture reads them back from the GPU, in the texture's format: the image the
	// texture was made from, or the texture's own in memory (RGBA) made its format; an empty image, as raylib's for a texture it can't
	// read, for one on the GPU alone.
	static function atlasOf(font:Font):Image {
		var texture = font.texture;
		if (texture == null)
			return new Image();
		if (font.atlas != null && font.atlasTexture == texture.id && font.atlas.format == texture.format) {
			var a = font.atlas;
			return new Image(a.data, a.width, a.height, 1, a.format);
		}
		var memory = Textures.onGpu(texture.id) == 0 ? Textures.imageOf(texture.id) : null;
		if (memory == null) {
			Runtime.log(LOG_WARNING, 'TEXTURE: [ID ${texture.id}] Failed to retrieve pixel data');
			return new Image();
		}
		var image = new Image(memory.pixels, memory.width, memory.height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
		if (texture.format == PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA || texture.format == PIXELFORMAT_UNCOMPRESSED_GRAYSCALE) {
			// Gray textures are white with their gray in red: taken back as they were sent.
			var alpha = texture.format == PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA,
				count = image.width * image.height;
			var out = haxe.io.Bytes.alloc(count * (alpha ? 2 : 1));
			for (i in 0...count) {
				out.set(alpha ? i * 2 : i, memory.pixels.get(i * 4));
				if (alpha)
					out.set(i * 2 + 1, memory.pixels.get(i * 4 + 3));
			}
			return new Image(out, image.width, image.height, 1, texture.format);
		}
		ImageFormat(image, texture.format);
		return image;
	}

	// A number as C's printf writes it with %1.0f: rounded to the nearest whole, a half to the even one, -0 for a negative rounded to 0.
	static function whole(x:Float):String {
		var floor = Math.ffloor(x), rest = x - floor;
		var rounded = rest > 0.5 ? floor + 1 : rest < 0.5 ? floor : (floor % 2 == 0 ? floor : floor + 1);
		return rounded == 0 && (x < 0 || 1 / x < 0) ? "-0" : Std.string(Std.int(rounded));
	}

	// Keeps the image a font's texture was made from, for ExportFontAsCode.
	static function keepAtlas(font:Font, image:Image):Void {
		font.atlas = image;
		font.atlasTexture = font.texture.id;
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

		Its size is estimated from the glyphs' widths, a power of two wide; when packing rows in order (`packMethod` 0) runs out of rows,
		it is made twice as high, as many times as it needs, so every glyph has its place. The skyline packer (1) leaves a glyph that
		doesn't fit out, with a warning, placed at 2147483648 across and down, as raylib's.

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
			Runtime.log(LOG_WARNING, "FONT: Provided glyphs info not valid, returning empty image atlas");
			return atlas;
		}
		glyphCount = glyphCount > 0 ? glyphCount : 95;
		var total = 0;
		for (i in 0...glyphCount)
			total += glyphs[i].image.width + 2 * padding;
		var padded = fontSize + 2 * padding;
		// raylib's estimate, in single precision as it works it out.
		inline function f32(x:Float):Float
			return helix.ray.internal.Pixels.f32(x);
		var area = f32(total * padded * f32(1.2)),
			size = Std.int(Math.pow(2, Math.fceil(f32(f32(Math.log(f32(Math.sqrt(area)))) / f32(Math.log(2))))));
		atlas.width = size;
		atlas.height = area < Std.int(size * size / 2) ? Std.int(size / 2) : size;
		var gray = haxe.io.Bytes.alloc(atlas.width * atlas.height);
		var recs = [for (_ in 0...glyphCount) new Rectangle()];
		// A glyph's texels inside the atlas, those past its edges left out.
		inline function blit(glyph:GlyphInfo, left:Int, top:Int)
			for (y in 0...glyph.image.height)
				for (x in 0...glyph.image.width)
					if (left + x >= 0 && left + x < atlas.width && top + y >= 0 && top + y < atlas.height)
						gray.set((top + y) * atlas.width + left + x, (glyph.image.data : haxe.io.Bytes).get(y * glyph.image.width + x));
		if (packMethod == 0) {
			var x = padding, y = padding;
			for (i in 0...glyphCount) {
				var glyph = glyphs[i];
				if (x >= atlas.width - glyph.image.width - 2 * padding) {
					x = padding;
					y += fontSize + 2 * padding;
					// Out of rows: the atlas is made twice as high, keeping what it holds.
					if (y > atlas.height - fontSize - padding) {
						Runtime.log(LOG_WARNING, "FONT: Updating atlas size to fit all characters");
						var taller = haxe.io.Bytes.alloc(atlas.width * atlas.height * 2);
						taller.blit(0, gray, 0, gray.length);
						gray = taller;
						atlas.height *= 2;
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
				else {
					// A glyph left out is placed where stb_rect_pack marks it, at its largest coordinate, as a float.
					recs[i].x = recs[i].y = f32(2147483647.0 + padding);
					Runtime.log(LOG_WARNING, 'FONT: Failed to package glyph (0x${StringTools.hex(glyph.value, 2).toLowerCase()})');
				}
			}
		}
		// raylib's white texels, for shapes drawn from the font's texture, in an atlas big enough for them.
		if (atlas.width >= 3 && atlas.height >= 3)
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

	/** Makes a font from an image of glyphs, as raylib's does: the glyphs in rows on a key color, the key's border before the first
		glyph giving the space between glyphs and between rows; each glyph a run of pixels that aren't the key, numbered from a first
		character. The key becomes clear on the font's texture. An image with no such border gives the default font. A glyph's height
		ends at the image's bottom and its width at its right edge, as raylib's scan has them. At most 256 glyphs are read, where
		raylib's writes past its 256.

		@param image  The image, in any uncompressed format.
		@param key  The color around the glyphs.
		@param firstChar  The first glyph's character.
		@return  The font. */
	static function LoadFontFromImage(image:Image, key:Color, firstChar:Int):Font {
		var defaults = GetFontDefault();
		var font = new Font();
		font.baseSize = defaults.baseSize;
		font.glyphCount = defaults.glyphCount;
		font.glyphPadding = defaults.glyphPadding;
		font.texture = defaults.texture;
		font.atlas = defaults.atlas;
		font.atlasTexture = defaults.atlasTexture;
		font.recs = defaults.recs;
		font.glyphs = defaults.glyphs;
		var width = image.width, height = image.height, count = width * height;
		var pixels = helix.ray.internal.Pixels.colors(image.data, width, height, image.format);
		var k = helix.ray.internal.Pixels.ofColor(key);
		// A pixel past the image reads as the key, where raylib's reads past its pixels.
		inline function isKey(i:Int):Bool
			return i < 0 || i >= count || pixels.getInt32(i * 4) == k;
		var x = 0, y = 0;
		while (y < height) {
			x = 0;
			while (x < width && isKey(y * width + x))
				x++;
			if (!isKey(y * width + x))
				break;
			y++;
		}
		if (x == 0 || y == 0)
			return font;
		var charSpacing = x, lineSpacing = y, charHeight = 0;
		while (lineSpacing + charHeight < height && !isKey((lineSpacing + charHeight) * width + charSpacing))
			charHeight++;
		var values:Array<Int> = [], recs:Array<Rectangle> = [];
		var lineToRead = 0, xPosToRead = charSpacing;
		while (lineSpacing + lineToRead * (charHeight + lineSpacing) < height) {
			var row = (lineSpacing + (charHeight + lineSpacing) * lineToRead) * width;
			while (xPosToRead < width && !isKey(row + xPosToRead) && values.length < 256) {
				var charWidth = 0;
				while (xPosToRead + charWidth < width && !isKey(row + xPosToRead + charWidth))
					charWidth++;
				values.push(firstChar + values.length);
				recs.push(new Rectangle(xPosToRead, lineSpacing + lineToRead * (charHeight + lineSpacing), charWidth, charHeight));
				xPosToRead += charWidth + charSpacing;
			}
			lineToRead++;
			xPosToRead = charSpacing;
		}
		for (i in 0...count)
			if (pixels.getInt32(i * 4) == k)
				pixels.setInt32(i * 4, 0);
		var fontClear = new Image(pixels, width, height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
		font.texture = LoadTextureFromImage(fontClear);
		keepAtlas(font, fontClear);
		font.glyphCount = values.length;
		font.glyphPadding = 0;
		font.recs = recs;
		font.glyphs = [];
		for (i in 0...values.length) {
			var glyph = new GlyphInfo();
			glyph.value = values[i];
			glyph.image = ImageFromImage(fontClear, recs[i]);
			font.glyphs.push(glyph);
		}
		font.baseSize = recs.length > 0 ? Std.int(recs[0].height) : 0;
		return font;
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

	// raylib 6.2's LoadFontData, as its LoadFontEx and LoadFontFromMemory take it: only the glyphs the font has, so a character it lacks
	// draws as its '?'; each Unicode space a blank image as wide as its advance (none when that isn't above 0); offsets from the line's
	// top.
	static function foundGlyphs(raster:Array<helix.platform.RasterGlyph>, ascent:Float, fontSize:Int):Array<GlyphInfo> {
		var glyphs = [];
		for (r in raster) {
			if (!r.found)
				continue;
			var glyph = new GlyphInfo();
			glyph.value = r.codepoint;
			glyph.image = new Image();
			glyph.offsetX = r.offsetX;
			glyph.offsetY = r.offsetY;
			if (r.width > 0 && r.height > 0) {
				glyph.advanceX = Std.int(r.advance);
				glyph.offsetY += Std.int(ascent);
				glyph.image.data = r.pixels;
				glyph.image.width = r.width;
				glyph.image.height = r.height;
				glyph.image.mipmaps = 1;
				glyph.image.format = PIXELFORMAT_UNCOMPRESSED_GRAYSCALE;
			}
			if (SPACES.indexOf(r.codepoint) >= 0) {
				glyph.advanceX = Std.int(r.advance);
				glyph.image = new Image();
				glyph.image.width = glyph.advanceX;
				glyph.image.height = fontSize;
				glyph.image.mipmaps = 1;
				glyph.image.format = PIXELFORMAT_UNCOMPRESSED_GRAYSCALE;
				if (glyph.advanceX > 0)
					glyph.image.data = haxe.io.Bytes.alloc(glyph.advanceX * fontSize);
				else
					glyph.advanceX = 0;
			}
			glyphs.push(glyph);
		}
		if (glyphs.length < raster.length)
			Runtime.log(LOG_WARNING, 'FONT: Requested codepoints glyphs found: [${glyphs.length}/${raster.length}]');
		return glyphs;
	}

	// The Unicode spaces raylib 6.2 gives blank glyphs: the ASCII space, the no-break space, the Ogham space mark, U+2000 to U+200A, the
	// narrow no-break space, the medium mathematical space and the ideographic space.
	static final SPACES = [
		0x20, 0xA0, 0x1680, 0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007, 0x2008, 0x2009, 0x200A, 0x202F, 0x205F, 0x3000
	];

	// raylib's LoadFontFromMemory, from the glyphs: packed with 4 texels of padding into the texture, each glyph's image its part of it;
	// the default font when there are none.
	static function fontOf(glyphs:Array<GlyphInfo>, fontSize:Int):Font {
		if (glyphs.length == 0) {
			Runtime.log(LOG_WARNING, "FONT: Font is not supported by LoadFontEx/LoadFontFromMemory or no glyphs found, reverted to default font");
			return GetFontDefault();
		}
		var font = new Font();
		font.baseSize = fontSize;
		font.glyphCount = glyphs.length;
		font.glyphs = glyphs;
		font.glyphPadding = 4;
		var atlas = GenImageFontAtlas(glyphs, font.recs, font.glyphCount, font.baseSize, font.glyphPadding, 0);
		font.texture = LoadTextureFromImage(atlas);
		keepAtlas(font, atlas);
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
		keepAtlas(font, new Image(atlas.pixels, atlas.width, atlas.height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8));
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

	// raylib's MAX_TEXT_BUFFER_LENGTH, the bytes of the buffer its text functions write into, its terminating 0 among them, and
	// MAX_TEXTSPLIT_COUNT, the most pieces TextSplit gives.
	static inline final BUFFER = 1024;
	static inline final SPLIT = 128;

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

		As raylib's, the text is at most 1023 UTF-8 bytes: longer, it is cut to its first 1020 and "..." ends it.

		@param text  The format.
		@param args  The values, one for each conversion.
		@return  The text; empty for a null format. */
	static function TextFormat(text:String, args:haxe.extern.Rest<Dynamic>):String {
		if (text == null)
			return "";
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
		// raylib's buffer of 1024 bytes: text that doesn't fit is cut, "..." over its last three.
		var result = out.toString(), bytes = utf8(result);
		return bytes.length >= BUFFER ? decoded(bytes, 0, BUFFER - 4) + "..." : result;
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

	/** raylib's copy into a C buffer. A Haxe string can't be written into, so a call doesn't compile on any target: assign it instead.

		@param dst  The text written into.
		@param src  The text copied.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("TextCopy: A String can't be written into. Assign it instead: dst = src")
	static function TextCopy(dst:String, src:String):Int {
		throw "TextCopy is unimplemented";
	}

	/** raylib's append into a C buffer at a cursor. A Haxe string can't be written into, so a call doesn't compile on any target: join
		the text instead.

		@param text  The text written into.
		@param append  The text appended.
		@param position  The cursor, in bytes.
		@return  Never returns: a call doesn't compile. */
	@:unsupported("TextAppend: A String can't be written into. Join the text instead: text += append")
	static function TextAppend(text:String, append:String, position:Array<Int>):Void {
		throw "TextAppend is unimplemented";
	}

	/** Returns whether two texts are the same.

		@param text1  The first text.
		@param text2  The second text.
		@return  True when they are; false when either is null. */
	static function TextIsEqual(text1:String, text2:String):Bool {
		return text1 != null && text2 != null && text1 == text2;
	}

	/** Returns the length of text in UTF-8 bytes, as raylib counts it: "héllo" is 6. The text functions' positions and lengths are all
		in these bytes, where `String.length` counts otherwise, and not alike on every target.

		@param text  The text.
		@return  The length, in bytes; 0 for null text. */
	static function TextLength(text:String):Int {
		if (text == null)
			return 0;
		var length = 0;
		for (codepoint in new haxe.iterators.StringIteratorUnicode(text))
			length += codepoint < 0x80 ? 1 : codepoint < 0x800 ? 2 : codepoint < 0x10000 ? 3 : 4;
		return length;
	}

	/** Returns a piece of text, by its place in UTF-8 bytes. The piece ends with the text, and is at most 1023 bytes, as raylib's.

		A character the piece cuts through is a "?" for each of its bytes taken, as raylib draws it.

		@param text  The text.
		@param position  Where the piece starts, in bytes from the start.
		@param length  How long it is, in bytes.
		@return  The piece; empty for null text, a position below 0 or at or past the end, or a length below 1. */
	static function TextSubtext(text:String, position:Int, length:Int):String {
		if (text == null || position < 0 || length <= 0)
			return "";
		var bytes = utf8(text), total = bytes.length;
		if (position >= total)
			return "";
		if (length > total - position)
			length = total - position;
		if (length >= BUFFER)
			length = BUFFER - 1;
		return decoded(bytes, position, position + length);
	}

	/** Returns text with every piece of it that matches replaced, from the start, each match after the one before.

		@param text  The text.
		@param replace  The text replaced.
		@param by  The text put in its place.
		@return  The new text; null when any is null or `replace` is empty. */
	static function TextReplace(text:String, replace:String, by:String):String {
		if (text == null || replace == null || by == null || replace.length == 0)
			return null;
		return text.split(replace).join(by);
	}

	/** Returns text with other text put in at a place in UTF-8 bytes. As raylib's, the result is at most 1022 bytes.

		A character the place cuts through is a "?" for each of its bytes, as raylib draws it.

		@param text  The text.
		@param insert  The text put in.
		@param position  Where, in bytes from the start, clamped to the end.
		@return  The new text; empty when either is null, the position is below 0, or the result is too long. */
	static function TextInsert(text:String, insert:String, position:Int):String {
		var inserted = insertedAt(text, insert, position);
		return inserted == null || inserted.length >= BUFFER - 1 ? "" : decoded(inserted, 0, inserted.length);
	}

	// raylib's TextInsert's bytes, before its limit: null when it gives nothing.
	static function insertedAt(text:String, insert:String, position:Int):Null<Array<Int>> {
		if (text == null || insert == null || position < 0)
			return null;
		var bytes = utf8(text);
		if (position > bytes.length)
			position = bytes.length;
		return bytes.slice(0, position).concat(utf8(insert)).concat(bytes.slice(position));
	}

	/** Returns texts joined into one, a delimiter between each two.

		As raylib's, the result is at most 1023 UTF-8 bytes: a text that would take it past them, with its delimiter, is left out, and the
		texts after it are still joined.

		@param textList  The texts; a null one is empty.
		@param count  How many of them.
		@param delimiter  The text between them; null for none.
		@return  The joined text. */
	static function TextJoin(textList:Array<String>, count:Int, delimiter:String):String {
		var out = [], between = utf8(delimiter);
		for (i in 0...count) {
			var piece = utf8(textList[i]);
			if (out.length + piece.length + between.length < BUFFER) {
				out = out.concat(piece);
				if (between.length > 0 && i < count - 1)
					out = out.concat(between);
			}
		}
		return decoded(out, 0, out.length);
	}

	/** Returns the pieces of text between a delimiter: one more than the delimiters it holds, an empty one between two together.

		As raylib's, the delimiter is one byte (its low 8 bits), only the text's first 1023 UTF-8 bytes are read, and there are at most 128
		pieces, the last of them empty when the text holds more. A character a piece cuts through is a "?" for each of its bytes.

		@param text  The text.
		@param delimiter  The byte between pieces, such as `",".code`.
		@param count  Receives how many pieces there are, at its index 0; 0 for null text.
		@return  The pieces; none for null text. */
	static function TextSplit(text:String, delimiter:Int, count:Array<Int>):Array<String> {
		var pieces = [];
		if (text != null) {
			var bytes = utf8(text), byte = delimiter & 0xFF, start = 0, end = bytes.length < BUFFER - 1 ? bytes.length : BUFFER - 1;
			for (i in 0...end) {
				if (bytes[i] == byte && byte != 0) {
					pieces.push(decoded(bytes, start, i));
					start = i + 1;
					if (pieces.length + 1 == SPLIT) {
						end = start;
						break;
					}
				}
			}
			pieces.push(decoded(bytes, start, end));
		}
		if (count != null)
			count[0] = pieces.length;
		return pieces;
	}

	/** Returns where text is first found in other text, in UTF-8 bytes from the start, as `TextSubtext` takes it.

		@param text  The text searched.
		@param find  The text found; empty text is found at 0.
		@return  The position, in bytes; -1 when it isn't there or either is null. */
	static function TextFindIndex(text:String, find:String):Int {
		if (text == null || find == null)
			return -1;
		var index = text.indexOf(find);
		return index < 0 ? -1 : TextLength(text.substr(0, index));
	}

	/** Returns text with its letters a to z made capitals, as raylib makes them. Other letters, as "é", are unchanged.

		@param text  The text.
		@return  The new text; empty for null text. */
	static function TextToUpper(text:String):String {
		var out = new StringBuf();
		if (text != null)
			for (codepoint in new haxe.iterators.StringIteratorUnicode(text))
				out.addChar(upper(codepoint));
		return out.toString();
	}

	/** Returns text with its capitals A to Z made lower case, as raylib makes them. Other letters, as "É", are unchanged.

		@param text  The text.
		@return  The new text; empty for null text. */
	static function TextToLower(text:String):String {
		var out = new StringBuf();
		if (text != null)
			for (codepoint in new haxe.iterators.StringIteratorUnicode(text))
				out.addChar(lower(codepoint));
		return out.toString();
	}

	/** Returns snake-case text in Pascal case: "hello_world" is "HelloWorld". Each run of underscores is dropped, and the first letter
		and the one after each run are made capitals if they are a to z. As raylib's, the result is at most 1023 UTF-8 bytes.

		@param text  The text.
		@return  The new text; empty for null text. */
	static function TextToPascal(text:String):String {
		return joinedWords(text, true);
	}

	/** Returns Pascal- or camel-case text, or words, in snake case: "helloWorld" and "Hello World" are "hello_world", "HTTPServer" is
		"http_server". Each capital A to Z is made lower case, an underscore before it when it follows a letter a to z, or a capital with
		a letter a to z after it; a space is an underscore. No underscore is added where the text so far ends in one, nor at its start.

		As raylib's, the result is at most 1023 UTF-8 bytes.

		@param text  The text.
		@return  The new text; empty for null text. */
	static function TextToSnake(text:String):String {
		var bytes = utf8(text), out = [];
		inline function at(k:Int)
			return k < bytes.length ? bytes[k] : 0;
		inline function isLower(c:Int)
			return c >= "a".code && c <= "z".code;
		inline function isUpper(c:Int)
			return c >= "A".code && c <= "Z".code;
		var j = 0;
		while (out.length < BUFFER - 1 && at(j) != 0) {
			var c = at(j);
			if (c == " ".code) {
				if (out.length > 0 && out[out.length - 1] != "_".code)
					out.push("_".code);
			} else if (isUpper(c)) {
				if (out.length > 0 && out[out.length - 1] != "_".code) {
					var before = at(j - 1), after = at(j + 1);
					if ((isLower(before) || (isUpper(before) && isLower(after))) && out.length < BUFFER - 2)
						out.push("_".code);
				}
				out.push(c + 32);
			} else
				out.push(c);
			j++;
		}
		return decoded(out, 0, out.length);
	}

	/** Returns snake-case text in camel case: "hello_world" is "helloWorld". Each run of underscores is dropped, the letter after it
		made a capital if it is a to z, and the first letter made lower case if it is A to Z. As raylib's, the result is at most 1023
		UTF-8 bytes.

		@param text  The text.
		@return  The new text; empty for null text. */
	static function TextToCamel(text:String):String {
		return joinedWords(text, false);
	}

	/** Returns the whole number text starts with, as raylib reads it: an optional "+" or "-", then the digits up to the first that
		isn't one. Nothing else is skipped, spaces neither; a number past 32 bits wraps.

		@param text  The text.
		@return  The number; 0 when it starts with none, or for null text. */
	static function TextToInteger(text:String):Int {
		if (text == null)
			return 0;
		var value = 0, sign = 1, i = 0;
		var codepoints = [for (c in new haxe.iterators.StringIteratorUnicode(text)) c];
		if (codepoints.length > 0 && (codepoints[0] == "+".code || codepoints[0] == "-".code)) {
			if (codepoints[0] == "-".code)
				sign = -1;
			i++;
		}
		while (i < codepoints.length && codepoints[i] >= "0".code && codepoints[i] <= "9".code)
			value = (value * 10 + codepoints[i++] - "0".code) | 0;
		return (value * sign) | 0;
	}

	/** Returns the number text starts with, as raylib reads it: an optional "+" or "-", digits, then a "." and more digits. An exponent,
		as in "1e3", isn't read, and nothing is skipped.

		It is worked out in 32-bit floats, digit by digit, as raylib works it, so the result is the float raylib returns: "0.1" is
		0.100000001490116.

		@param text  The text.
		@return  The number; 0 when it starts with none, or for null text. */
	static function TextToFloat(text:String):Float {
		if (text == null)
			return 0;
		inline function f32(x:Float):Float
			return haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(x));
		var value = 0., sign = 1., i = 0;
		var codepoints = [for (c in new haxe.iterators.StringIteratorUnicode(text)) c];
		inline function digit(at:Int)
			return at < codepoints.length && codepoints[at] >= "0".code && codepoints[at] <= "9".code;
		if (codepoints.length > 0 && (codepoints[0] == "+".code || codepoints[0] == "-".code)) {
			if (codepoints[0] == "-".code)
				sign = -1;
			i++;
		}
		while (digit(i))
			value = f32(f32(value * 10) + (codepoints[i++] - "0".code));
		if (i < codepoints.length && codepoints[i++] == ".".code) {
			var divisor = 10.;
			while (digit(i)) {
				value = f32(value + f32((codepoints[i++] - "0".code) / divisor));
				divisor = f32(divisor * 10);
			}
		}
		return value * sign;
	}

	// ---- Codepoints ----

	/** Returns the text of characters.

		@param codepoints  The characters' codes.
		@param length  How many of them.
		@return  The text; a code past 0x10FFFF adds nothing. */
	static function LoadUTF8(codepoints:Array<Int>, length:Int):String {
		var bytes = [];
		for (i in 0...length)
			encode(codepoints[i], bytes);
		return decoded(bytes, 0, bytes.length);
	}

	/** Does nothing: text from `LoadUTF8` is freed by the garbage collector.

		@param text  The text. */
	static function UnloadUTF8(text:String):Void {}

	/** Returns the codes of text's characters.

		@param text  The text.
		@param count  Receives how many there are, at its index 0; 0 for null text.
		@return  The codes; null for null text. */
	static function LoadCodepoints(text:String, count:Array<Int>):Array<Int> {
		if (text == null) {
			if (count != null)
				count[0] = 0;
			return null;
		}
		var bytes = utf8(text), codepoints = [], size = [0], i = 0;
		while (i < bytes.length) {
			codepoints.push(next(bytes, i, size));
			i += size[0];
		}
		if (count != null)
			count[0] = codepoints.length;
		return codepoints;
	}

	/** Does nothing: codes from `LoadCodepoints` are freed by the garbage collector.

		@param codepoints  The codes. */
	static function UnloadCodepoints(codepoints:Array<Int>):Void {}

	/** Returns how many characters text holds: "héllo→" holds 6, in 9 bytes.

		@param text  The text.
		@return  The count; 0 for null text. */
	static function GetCodepointCount(text:String):Int {
		var bytes = utf8(text), size = [0], i = 0, count = 0;
		while (i < bytes.length) {
			next(bytes, i, size);
			i += size[0];
			count++;
		}
		return count;
	}

	/** Returns the code of text's first character, checked as RFC 3629 has UTF-8, as raylib checks it.

		@param text  The text.
		@param codepointSize  Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by; 1 for empty or
			null text.
		@return  The code; 0 for empty text, '?' (0x3F) for null text. */
	static function GetCodepoint(text:String, codepointSize:Array<Int>):Int {
		var bytes = utf8(text, 4), size = [1];
		var codepoint = text == null ? "?".code : checked(bytes, size);
		if (codepointSize != null)
			codepointSize[0] = size[0];
		return codepoint;
	}

	/** Returns the code of text's first character.

		@param text  The text.
		@param codepointSize  Receives the character's length in UTF-8 bytes, at its index 0: what to move past it by, as in
			`TextSubtext(text, codepointSize[0], TextLength(text))`; 1 for empty or null text.
		@return  The code; 0 for empty text, '?' (0x3F) for null text. */
	static function GetCodepointNext(text:String, codepointSize:Array<Int>):Int {
		var bytes = utf8(text, 4), size = [1];
		var codepoint = text == null ? "?".code : next(bytes, 0, size);
		if (codepointSize != null)
			codepointSize[0] = size[0];
		return codepoint;
	}

	/** Returns the code of text's last character: the one before where it ends, as raylib's finds the one before a place in text.

		@param text  The text; `TextSubtext(text, 0, position)` gives the character before a position.
		@param codepointSize  Receives the character's length in UTF-8 bytes, at its index 0: what to move back by; 1 for empty or null
			text.
		@return  The code; '?' (0x3F) for empty or null text. */
	static function GetCodepointPrevious(text:String, codepointSize:Array<Int>):Int {
		var bytes = utf8(text), i = bytes.length, size = [1];
		do
			i-- while (i >= 0 && bytes[i] & 0xC0 == 0x80);
		var codepoint = "?".code;
		if (i >= 0) {
			var found = [0];
			codepoint = next(bytes, i, found);
			if (codepoint != 0)
				size[0] = found[0];
		}
		if (codepointSize != null)
			codepointSize[0] = size[0];
		return codepoint;
	}

	/** Returns a character as text.

		@param codepoint  The character's code.
		@param utf8Size  Receives its length in UTF-8 bytes, at its index 0; 0 for a code past 0x10FFFF.
		@return  The text; empty for a code past 0x10FFFF. */
	static function CodepointToUTF8(codepoint:Int, utf8Size:Array<Int>):String {
		var bytes = [];
		encode(codepoint, bytes);
		if (utf8Size != null)
			utf8Size[0] = bytes.length;
		return decoded(bytes, 0, bytes.length);
	}

	// Text's UTF-8 bytes, as raylib holds it; with most, only as many characters as reach it.
	static function utf8(text:String, most = 0x7FFFFFFF):Array<Int> {
		var bytes = [];
		if (text != null)
			for (codepoint in new haxe.iterators.StringIteratorUnicode(text)) {
				if (bytes.length >= most)
					break;
				encode(codepoint, bytes);
			}
		return bytes;
	}

	// raylib's CodepointToUTF8: a code's UTF-8 bytes added to bytes, a negative one's low byte, none for one past 0x10FFFF.
	static function encode(codepoint:Int, bytes:Array<Int>):Void {
		if (codepoint <= 0x7F)
			bytes.push(codepoint & 0xFF);
		else if (codepoint <= 0x7FF) {
			bytes.push(((codepoint >> 6) & 0x1F) | 0xC0);
			bytes.push((codepoint & 0x3F) | 0x80);
		} else if (codepoint <= 0xFFFF) {
			bytes.push(((codepoint >> 12) & 0x0F) | 0xE0);
			bytes.push(((codepoint >> 6) & 0x3F) | 0x80);
			bytes.push((codepoint & 0x3F) | 0x80);
		} else if (codepoint <= 0x10FFFF) {
			bytes.push(((codepoint >> 18) & 0x07) | 0xF0);
			bytes.push(((codepoint >> 12) & 0x3F) | 0x80);
			bytes.push(((codepoint >> 6) & 0x3F) | 0x80);
			bytes.push((codepoint & 0x3F) | 0x80);
		}
	}

	// raylib's GetCodepointNext on bytes from i, a byte past their end read as C's terminating 0; size receives the bytes it took, 1 for
	// a malformed one, read as '?'.
	static function next(bytes:Array<Int>, i:Int, size:Array<Int>):Int {
		inline function at(k:Int)
			return i + k < bytes.length ? bytes[i + k] : 0;
		inline function tail(k:Int)
			return at(k) & 0xC0 == 0x80;
		var b = at(0);
		size[0] = 1;
		if (b & 0xF8 == 0xF0) {
			if (!tail(1) || !tail(2) || !tail(3))
				return "?".code;
			size[0] = 4;
			return ((b & 0x07) << 18) | ((at(1) & 0x3F) << 12) | ((at(2) & 0x3F) << 6) | (at(3) & 0x3F);
		}
		if (b & 0xF0 == 0xE0) {
			if (!tail(1) || !tail(2))
				return "?".code;
			size[0] = 3;
			return ((b & 0x0F) << 12) | ((at(1) & 0x3F) << 6) | (at(2) & 0x3F);
		}
		if (b & 0xE0 == 0xC0) {
			if (!tail(1))
				return "?".code;
			size[0] = 2;
			return ((b & 0x1F) << 6) | (at(1) & 0x3F);
		}
		return b & 0x80 == 0 ? b : "?".code;
	}

	// raylib's GetCodepoint on bytes from 0, which checks each sequence as RFC 3629 has it; size receives the bytes it took.
	static function checked(bytes:Array<Int>, size:Array<Int>):Int {
		inline function at(k:Int)
			return k < bytes.length ? bytes[k] : 0;
		inline function bad(k:Int)
			return at(k) == 0 || at(k) >> 6 != 2;
		var octet = at(0), codepoint = "?".code;
		size[0] = 1;
		if (octet <= 0x7F)
			return octet;
		if (octet & 0xE0 == 0xC0) {
			if (bad(1)) {
				size[0] = 2;
				return codepoint;
			}
			if (octet >= 0xC2 && octet <= 0xDF) {
				codepoint = ((octet & 0x1F) << 6) | (at(1) & 0x3F);
				size[0] = 2;
			}
		} else if (octet & 0xF0 == 0xE0) {
			for (k in 1...3)
				if (bad(k)) {
					size[0] = k + 1;
					return "?".code;
				}
			if ((octet == 0xE0 && !(at(1) >= 0xA0 && at(1) <= 0xBF)) || (octet == 0xED && !(at(1) >= 0x80 && at(1) <= 0x9F))) {
				size[0] = 2;
				return codepoint;
			}
			codepoint = ((octet & 0xF) << 12) | ((at(1) & 0x3F) << 6) | (at(2) & 0x3F);
			size[0] = 3;
		} else if (octet & 0xF8 == 0xF0) {
			if (octet > 0xF4)
				return codepoint;
			for (k in 1...4)
				if (bad(k)) {
					size[0] = k + 1;
					return "?".code;
				}
			if ((octet == 0xF0 && !(at(1) >= 0x90 && at(1) <= 0xBF)) || (octet == 0xF4 && !(at(1) >= 0x80 && at(1) <= 0x8F))) {
				size[0] = 2;
				return codepoint;
			}
			codepoint = ((octet & 0x7) << 18) | ((at(1) & 0x3F) << 12) | ((at(2) & 0x3F) << 6) | (at(3) & 0x3F);
			size[0] = 4;
		}
		return codepoint > 0x10FFFF ? "?".code : codepoint;
	}

	// Text from bytes start to end, read as raylib reads them to draw: a malformed byte, or one of a character cut at end, is a '?', and
	// so is a code no String can hold (a surrogate, one past 0x10FFFF).
	static function decoded(bytes:Array<Int>, start:Int, end:Int):String {
		var out = new StringBuf(), size = [0], i = 0;
		var piece = start == 0 && end == bytes.length ? bytes : bytes.slice(start, end);
		while (i < piece.length) {
			var codepoint = next(piece, i, size);
			out.addChar(codepoint > 0x10FFFF || (codepoint >= 0xD800 && codepoint <= 0xDFFF) ? "?".code : codepoint);
			i += size[0];
		}
		return out.toString();
	}

	// A letter a to z as a capital, anything else unchanged.
	static inline function upper(codepoint:Int):Int {
		return codepoint >= "a".code && codepoint <= "z".code ? codepoint - 32 : codepoint;
	}

	// A capital A to Z in lower case, anything else unchanged.
	static inline function lower(codepoint:Int):Int {
		return codepoint >= "A".code && codepoint <= "Z".code ? codepoint + 32 : codepoint;
	}

	// TextToPascal (capital) and TextToCamel, raylib 6.2's on the text's UTF-8 bytes: the first made a capital or lower case, each run
	// of underscores after it dropped and the byte after the run made a capital, at most 1023 bytes written (5.5's ended the text at an
	// underscore not followed by a to z).
	static function joinedWords(text:String, capital:Bool):String {
		var bytes = utf8(text);
		if (bytes.length == 0)
			return "";
		inline function at(k:Int)
			return k < bytes.length ? bytes[k] : 0;
		var out = [capital ? upper(bytes[0]) : lower(bytes[0])], j = 1;
		while (out.length < BUFFER - 1 && at(j) != 0) {
			if (at(j) != "_".code)
				out.push(at(j));
			else {
				while (at(j) == "_".code)
					j++;
				if (at(j) == 0)
					break;
				out.push(upper(at(j)));
			}
			j++;
		}
		return decoded(out, 0, out.length);
	}
	#end
}
