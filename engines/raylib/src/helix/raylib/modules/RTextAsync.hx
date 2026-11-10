package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.Animations;
import helix.raylib.internal.Models;
import helix.raylib.internal.ObjModels;
import helix.formats.obj.MtlFile;
import helix.formats.obj.ObjFile;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.internal.CallbackFiles;
import helix.raylib.internal.WaveReader;
import helix.raylib.internal.Waves;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
import helix.raylib.internal.Answers.*;
import helix.raylib.modules.RWindowAsync.*;
import helix.raylib.modules.RFilesAsync.*;
import helix.raylib.modules.RTexturesAsync.*;
import helix.raylib.modules.RModelsAsync.*;
import helix.raylib.modules.RAudioAsync.*;
#end

/** Provides the async versions of rtext's font loads and writes. Each replaces a raylib call that waits for a file, the glyphs or a
	write.

	`helix.raylib.Raylib` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RTextAsync {
	#if !macro
	// LoadFontAsync's call where its file's name isn't known as the program builds (Raylib.LoadFontAsync): a GIF image's glyphs or the
	// other readers, picked by its extension as it runs, so the GIF reader is in the program.
	static function loadFont(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifFont(fileName, loaded, failed);
		else
			loadPlainFont(fileName, loaded, failed);
	}

	// LoadFontAsync's call for a GIF file: the glyphs of its first frame.
	static function loadGifFont(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
		loadGifImage(fileName, image -> loaded(imageFont(image)), message -> refuse("LoadFontAsync", message, failed));
	}

	// A font of an image's glyphs, as LoadFontAsync reads one.
	static function imageFont(image:Image):Font {
		var font = LoadFontFromImage(image, MAGENTA, 32);
		SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
		return font;
	}

	// LoadFontAsync's call for any other file.
	static function loadPlainFont(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
		var path = normalize(fileName),
			type = haxe.io.Path.extension(path).toLowerCase();
		if (type == "fnt") {
			Runtime.fonts().loadBmFont(path, font -> {
				var made = RText.fromBmFont(font);
				SetTextureFilter(made.texture, TEXTURE_FILTER_POINT);
				loaded(made);
			}, message -> refuse("LoadFontAsync", message, failed));
			return;
		}
		if (isDecoded(type) || type == "qoi") {
			loadPlainImage(path, image -> loaded(imageFont(image)), message -> refuse("LoadFontAsync", message, failed));
			return;
		}
		if (type != "ttf" && type != "otf") {
			Runtime.later(() -> refuse("LoadFontAsync", '$path: .$type fonts aren\'t in helix-raylib yet', failed));
			return;
		}
		LoadFontExAsync(path, 32, null, 95, font -> {
			SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
			loaded(font);
		}, failed);
	}

	/** Asynchronously loads a TrueType or OpenType font file at a size, replacing raylib's `LoadFontEx`. See `LoadFontFromMemoryAsync` for making a font from bytes already loaded.

		The font holds only the characters the file has. `glyphCount` may be fewer than asked for, and a character it lacks draws as its '?'.

		Each Unicode space the file has (U+0020, U+00A0, U+2000 to U+200A, U+3000 and the others) is a blank glyph as wide as its advance.

		@param fileName  The file, as the program names it.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
		@param loaded  Receives the font once its glyphs are ready.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadFontExAsync(fileName:String, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, loaded:Font->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> {
			if (error != null)
				refuse("LoadFontExAsync", error, failed);
			else
				LoadFontFromMemoryAsync("." + haxe.io.Path.extension(path), Runtime.files.get(path), Runtime.files.get(path).length, fontSize, codepoints,
					codepointCount, loaded, message -> refuse("LoadFontExAsync", '$path: $message', failed));
		});
	}

	/** Asynchronously makes a font from a TrueType or OpenType file's bytes, replacing raylib's `LoadFontFromMemory`. See `LoadFontExAsync` for loading a file by its name.
		The glyphs are rasterized off the main thread.

		The font holds only the characters the file has, as `LoadFontExAsync`'s does. With none of them, it is the default font.

		@param fileType  The file's extension, ".ttf" or ".otf". Any other is refused.
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95.
		@param loaded  Receives the font once its glyphs are ready.
		@param failed  Optional. Receives why it couldn't be made; when omitted, it is logged. */
	static function LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int,
			loaded:Font->Void, ?failed:String->Void):Void {
		var type = fileType.toLowerCase();
		if (type != ".ttf" && type != ".otf") {
			Runtime.later(() -> refuse("LoadFontFromMemoryAsync", '$fileType fonts aren\'t in helix-raylib yet', failed));
			return;
		}
		var count = codepointCount > 0 ? codepointCount : 95;
		var wanted = codepoints == null ? [for (i in 0...count) 32 + i] : codepoints.slice(0, count);
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.fonts()
			.rasterize(data, fontSize, wanted, (glyphs, ascent, _, _) -> loaded(RText.fontOf(RText.foundGlyphs(glyphs, ascent, fontSize), fontSize)),
				message -> refuse("LoadFontFromMemoryAsync", message, failed));
	}

	/** Asynchronously rasterizes a TrueType or OpenType font's glyphs, each with its own image. See
		`LoadFontFromMemoryAsync` for a font ready to draw, replacing raylib's `LoadFontData`.

		Each glyph's image is 8-bit grayscale, for `GenImageFontAtlas`.

		Under `FONT_SDF` the images hold signed distances, with 4 texels of padding, 128 on the outline and 64 for each texel.

		@param fileData  The font file's bytes.
		@param dataSize  How many of them.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95.
		@param type  `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances. Any
			other is taken as `FONT_DEFAULT`.
		@param loaded  Receives the glyphs once they are ready.
		@param failed  Optional. Receives why the font couldn't be read; when omitted, it is logged. */
	static function LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int,
			loaded:Array<GlyphInfo>->Void, ?failed:String->Void):Void {
		var count = codepointCount > 0 ? codepointCount : 95;
		var wanted = codepoints == null ? [for (i in 0...count) 32 + i] : codepoints.slice(0, count);
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		var fonts = Runtime.fonts();
		// raylib's type is a value the program passes as it runs, so each kind's rasterizing is in the program that calls it.
		var rasterize = type == FONT_SDF ? fonts.rasterizeDistanceField : type == FONT_BITMAP ? fonts.rasterizeBitmap : fonts.rasterize;
		rasterize(data, fontSize, wanted, (glyphs, ascent, _, _) -> loaded(RText.fontData(glyphs, ascent, fontSize, type)),
			message -> refuse("LoadFontDataAsync", message, failed));
	}

	/** Asynchronously writes a font as a C header, the text raylib 5.5's `ExportFontAsCode` writes.
		The file is written through `SaveFileTextAsync`, replacing raylib's `ExportFontAsCode`.

		The header holds the texture's pixels, each glyph's rectangle, character, offsets and advance, and a function loading the font. The
		file's name, in Pascal case, names them.

		The pixels are in the texture's format (gray and alpha for the default font and a TrueType font's), compressed as `CompressData`
		compresses them, 20 bytes a line.

		The pixels are those the font's texture was made from, or the texture's own while it hasn't been drawn.

		A texture made otherwise and already on the GPU (a render texture's) is written as an empty image, as raylib writes a texture it
		can't read back.

		@param font  The font.
		@param fileName  The file.
		@param done  Optional. Called once the file is written, or once it is refused, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportFontAsCodeAsync(font:Font, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportFontAsCodeAsync", fileName, RText.fontAsCode(font, fileName), "Font as code exported successfully", done, failed);
	}
	#end
}
