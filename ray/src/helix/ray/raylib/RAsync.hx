package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.internal.CallbackFiles;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.RAsync.*;
#end

/** Holds the async loads, helix-ray's own in place of raylib's loads that wait for a file, written here; `Raylib` forwards to each
	(`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RAsync {
	#if !macro
	// ---- The async loads: helix-ray's own, not raylib's ----

	/** Loads an image file as a texture, answering when it is ready: helix-ray's own, in place of raylib's `LoadTexture`, as a page
		can't wait for a file. A file loaded again shares its first load's texture, and the image goes to the GPU when first drawn. The
		answer comes at a later frame, never during the call.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the texture.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadTextureAsync(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> error == null ? loaded(RTextures.loadTexture(path)) : refuse("LoadTextureAsync", error, failed));
	}

	/** Loads a model from a glTF or GLB file, with its images and the files it points to, answering when it is ready: helix-ray's own,
		in place of raylib's `LoadModel`. A file loaded again shares its first load's meshes and textures, with materials of its own.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the model.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadModelAsync(fileName:String, loaded:Model->Void, ?failed:String->Void):Void {
		var path = normalize(fileName), lower = path.toLowerCase();
		if (!(StringTools.endsWith(lower, ".glb") || StringTools.endsWith(lower, ".gltf"))) {
			Runtime.later(() -> refuse("LoadModelAsync", '$path: only glTF and GLB are read here', failed));
			return;
		}
		if (Models.isKept(path)) {
			Runtime.later(() -> loaded(RModels.loadModel(path)));
			return;
		}
		Runtime.loading();
		Runtime.models.load(path, read -> {
			Models.keep(read, defaultShader());
			loaded(RModels.loadModel(path));
		}, error -> refuse("LoadModelAsync", error, failed));
	}

	/** Loads a sound file and decodes it, answering when it is ready to play at once: helix-ray's own, in place of raylib's `LoadSound`.
		A file loaded again shares its first load's decoded sound. `InitAudioDevice` comes first.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the sound.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadSoundAsync(fileName:String, loaded:Sound->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		if (Runtime.audio == null) {
			Runtime.later(() -> refuse("LoadSoundAsync", '$path: InitAudioDevice first', failed));
			return;
		}
		var sound = RAudio.loadSound(path);
		var entry = sounds.get(path);
		if (entry.loaded != null)
			Runtime.later(() -> loaded(sound));
		else
			entry.answers.push(error -> error == null ? loaded(sound) : refuse("LoadSoundAsync", error, failed));
	}

	/** Reads a text file, answering when it is read: helix-ray's own, in place of raylib's `LoadFileText`. The program's
		`SetLoadFileTextCallback` answers first, then what `SaveFileText` wrote, then the program's files.

		@param fileName  The file.
		@param loaded  Receives its text.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		var given = RCore.loadText == null ? null : RCore.loadText(path);
		if (given != null) {
			Runtime.later(() -> loaded(given));
			return;
		}
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED + path)) {
				var text = saves.getString(SAVED + path, "");
				Runtime.later(() -> loaded(text));
				return;
			}
			Runtime.fetch(path, error -> error == null ? loaded(Runtime.files.get(path).toString()) : refuse("LoadFileTextAsync", error, failed));
		});
	}

	/** Reads a file's bytes, answering when they are read: helix-ray's own, in place of raylib's `LoadFileData`. The program's
		`SetLoadFileDataCallback` answers first, then what `SaveFileData` wrote, then the program's files.

		@param fileName  The file.
		@param loaded  Receives its bytes.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadFileDataAsync(fileName:String, loaded:haxe.io.Bytes->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.withSaves(_ -> {
			var bytes = RCore.dataNow(path);
			if (bytes != null) {
				Runtime.later(() -> loaded(bytes));
				return;
			}
			Runtime.fetch(path, error -> error == null ? loaded(Runtime.files.get(path)) : refuse("LoadFileDataAsync", error, failed));
		});
	}

	/** Answers whether a file exists: helix-ray's own, in place of raylib's `FileExists`. One `SaveFileText` or `SaveFileData` wrote
		exists, as does one of the program's; finding one of the program's reads it, so a load of it after answers at once. The answer
		comes at a later frame, never during the call.

		@param fileName  The file.
		@param answer  Receives true when it exists. */
	static function FileExistsAsync(fileName:String, answer:Bool->Void):Void {
		var path = normalize(fileName);
		Runtime.withSaves(saves -> {
			if (saves.hasKey(SAVED + path)
				|| saves.hasKey(SAVED_DATA + path)
				|| Runtime.files.exists(path)
				|| Runtime.images.exists(path))
				Runtime.later(() -> answer(true));
			else
				Runtime.fetch(path, error -> answer(error == null));
		});
	}

	/** Loads a font file, answering when its glyphs are ready: helix-ray's own, in place of raylib's `LoadFont`. A TrueType or OpenType
		file gives its printable ASCII at 32 pixels; a BMFont (.fnt, the text format) its characters and pages, the pages stacked onto
		one texture, as raylib's; an image (PNG, JPEG, BMP, TGA or QOI) its glyphs on a `MAGENTA` key from the space on, as
		`LoadFontFromImage` reads them; each drawn with `TEXTURE_FILTER_POINT`.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadFontAsync(fileName:String, loaded:Font->Void, ?failed:String->Void):Void {
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
			LoadImageAsync(path, image -> {
				var font = LoadFontFromImage(image, MAGENTA, 32);
				SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
				loaded(font);
			}, message -> refuse("LoadFontAsync", message, failed));
			return;
		}
		if (type != "ttf" && type != "otf") {
			Runtime.later(() -> refuse("LoadFontAsync", '$path: .$type fonts aren\'t in helix-ray yet', failed));
			return;
		}
		LoadFontExAsync(path, 32, null, 95, font -> {
			SetTextureFilter(font.texture, TEXTURE_FILTER_POINT);
			loaded(font);
		}, failed);
	}

	/** Loads a TrueType or OpenType font file at a size, answering when its glyphs are ready: helix-ray's own, in place of raylib's
		`LoadFontEx`.

		@param fileName  The file, as the program names it.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95, the printable ASCII when `codepoints` is null.
		@param loaded  Receives the font.
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

	/** Makes a font from a TrueType or OpenType file's bytes, answering when its glyphs are ready: helix-ray's own, in place of raylib's
		`LoadFontFromMemory`, as the glyphs are rasterized off the main thread.

		@param fileType  The file's extension, ".ttf" or ".otf".
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be made; when omitted, it is logged. */
	static function LoadFontFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int,
			loaded:Font->Void, ?failed:String->Void):Void {
		var type = fileType.toLowerCase();
		if (type != ".ttf" && type != ".otf") {
			Runtime.later(() -> refuse("LoadFontFromMemoryAsync", '$fileType fonts aren\'t in helix-ray yet', failed));
			return;
		}
		LoadFontDataAsync(fileData, dataSize, fontSize, codepoints, codepointCount, FONT_DEFAULT, glyphs -> loaded(RText.fontOf(glyphs, fontSize)),
			message -> refuse("LoadFontFromMemoryAsync", message, failed));
	}

	/** Rasterizes a TrueType or OpenType font's glyphs, answering when they are ready: helix-ray's own, in place of raylib's
		`LoadFontData`. Each glyph has its own image, 8-bit grayscale, for `GenImageFontAtlas`; `FONT_SDF` makes them signed distances, with
		4 texels of padding, 128 on the outline and 64 a texel.

		@param fileData  The font file's bytes.
		@param dataSize  How many of them.
		@param fontSize  The glyphs' size: the height of a line, in pixels.
		@param codepoints  The characters, or null for those from the space on.
		@param codepointCount  How many characters; 0 for 95.
		@param type  `FONT_DEFAULT` for antialiased glyphs, `FONT_BITMAP` for glyphs with no gray, `FONT_SDF` for signed distances.
		@param loaded  Receives the glyphs.
		@param failed  Optional. Receives why the font couldn't be read; when omitted, it is logged. */
	static function LoadFontDataAsync(fileData:haxe.io.Bytes, dataSize:Int, fontSize:Int, codepoints:Array<Int>, codepointCount:Int, type:Int,
			loaded:Array<GlyphInfo>->Void, ?failed:String->Void):Void {
		var count = codepointCount > 0 ? codepointCount : 95;
		var wanted = codepoints == null ? [for (i in 0...count) 32 + i] : codepoints.slice(0, count);
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.rasterizer()
			.rasterize(data, fontSize, wanted, type == FONT_SDF, (glyphs, ascent, _, _) -> loaded(RText.fontData(glyphs, ascent, fontSize, type)),
				message -> refuse("LoadFontDataAsync", message, failed));
	}

	/** Loads an image file, answering when it is decoded: helix-ray's own, in place of raylib's `LoadImage`, as a page can't wait for a
		file. A PNG, JPEG, BMP or TGA file is decoded by the platform, so it gives `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` whatever its
		channels, where raylib's gives a grayscale file grayscale; a QOI file gives its own channels, RGB or RGBA, as raylib's. The answer
		comes at a later frame, never during the call.

		@param fileName  The file, as the program names it.
		@param loaded  Receives the image, its pixels its own.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadImageAsync(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
		var path = normalize(fileName),
			type = haxe.io.Path.extension(path).toLowerCase();
		if (type == "qoi") {
			Runtime.fetch(path, error -> {
				if (error != null)
					refuse("LoadImageAsync", error, failed);
				else
					decoded("LoadImageAsync", "." + type, Runtime.files.get(path), loaded, failed);
			});
			return;
		}
		if (!isDecoded(type)) {
			Runtime.later(() -> refuse("LoadImageAsync", '$path: .$type images aren\'t read here', failed));
			return;
		}
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse("LoadImageAsync", error, failed);
				return;
			}
			var image = Runtime.image(path);
			loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height));
		});
	}

	/** Loads an image's raw pixels from a file, answering when they are read: helix-ray's own, in place of raylib's `LoadImageRaw`. The
		file holds the pixels in a format, after a header of some bytes; a file too small for them fails.

		@param fileName  The file.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param format  The pixel format (`PIXELFORMAT_*`).
		@param headerSize  The bytes before the pixels, skipped when the file holds them and the pixels.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be loaded; when omitted, it is logged. */
	static function LoadImageRawAsync(fileName:String, width:Int, height:Int, format:Int, headerSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		LoadFileDataAsync(fileName, bytes -> {
			var size = GetPixelDataSize(width, height, format);
			if (size > bytes.length) {
				refuse("LoadImageRawAsync", '${normalize(fileName)}: ${bytes.length} bytes, too few for $width x $height pixels', failed);
				return;
			}
			var start = headerSize > 0 && headerSize + size <= bytes.length ? headerSize : 0;
			loaded(new Image(bytes.sub(start, size), width, height, 1, format));
		}, error -> refuse("LoadImageRawAsync", error, failed));
	}

	/** Decodes an image file's bytes, answering when it is decoded: helix-ray's own, in place of raylib's `LoadImageFromMemory`, as
		images are decoded asynchronously. The formats and channels are `LoadImageAsync`'s.

		@param fileType  The file's extension: ".png", ".jpg", ".jpeg", ".bmp", ".tga" or ".qoi".
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be decoded; when omitted, it is logged. */
	static function LoadImageFromMemoryAsync(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.loading();
		Runtime.later(() -> decoded("LoadImageFromMemoryAsync", fileType == null ? "" : fileType.toLowerCase(), data, loaded, failed));
	}

	/** Reads a texture's pixels, answering when they are read: helix-ray's own, in place of raylib's `LoadImageFromTexture`, as the GPU
		answers later. A render texture's are read back from the GPU after the frame it was drawn in, rows bottom first as raylib's are,
		so it reads upside down as raylib's does. Another texture's pixels are what went to the GPU, while they are in memory: before it
		is first drawn, or when it was loaded from a file; once only on the GPU they can't be read here, and it fails.

		@param texture  The texture.
		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image->Void, ?failed:String->Void):Void {
		if (texture.flipped) {
			var answered = false, during = true;
			Runtime.graphics.readPixels(Textures.handle(texture.id), (pixels, width, height) -> {
				var image = rgba(pixels, width, height);
				ImageFlipVertical(image);
				Runtime.log(LOG_INFO, 'TEXTURE: [ID ${texture.id}] Pixel data retrieved successfully');
				during ? Runtime.later(() -> loaded(image)) : loaded(image);
			},
				error -> during ? Runtime.later(() -> refuse("LoadImageFromTextureAsync", error, failed)) : refuse("LoadImageFromTextureAsync", error, failed));
			during = false;
			return;
		}
		var image = Textures.imageOf(texture.id);
		Runtime.later(() -> image == null ? refuse("LoadImageFromTextureAsync",
			'TEXTURE: [ID ${texture.id}] Failed to retrieve pixel data: its pixels are on the GPU alone',
			failed) : loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height)));
	}

	/** Reads the screen, answering as the next frame ends: helix-ray's own, in place of raylib's `LoadImageFromScreen`, as the GPU
		answers later. The image is the framebuffer's size, rows top first, its alpha opaque, as raylib's.

		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadImageFromScreenAsync(loaded:Image->Void, ?failed:String->Void):Void {
		if (Runtime.frame == null) {
			Runtime.later(() -> refuse("LoadImageFromScreenAsync", "InitWindow first", failed));
			return;
		}
		Runtime.screenshots().captureFrame(captured -> {
			var pixels = captured.pixels;
			for (i in 0...captured.width * captured.height)
				pixels.set(i * 4 + 3, 255);
			loaded(rgba(pixels, captured.width, captured.height));
		}, error -> refuse("LoadImageFromScreenAsync", error, failed));
	}

	// Whether an image file's extension is one the platform decodes.
	static function isDecoded(type:String):Bool {
		return type == "png" || type == "jpg" || type == "jpeg" || type == "bmp" || type == "tga";
	}

	// An image of RGBA pixels, which it keeps.
	static function rgba(pixels:haxe.io.Bytes, width:Int, height:Int):Image {
		return new Image(pixels, width, height, 1, PIXELFORMAT_UNCOMPRESSED_R8G8B8A8);
	}

	// An image file's bytes decoded, by its extension: QOI here, with its channels, the rest by the platform, as RGBA.
	static function decoded(name:String, fileType:String, data:haxe.io.Bytes, loaded:Image->Void, failed:Null<String->Void>):Void {
		if (fileType == ".qoi") {
			var qoi = try helix.formats.qoi.QoiFile.read(data) catch (e:Dynamic) null;
			if (qoi == null) {
				refuse(name, "IMAGE: Failed to load image data", failed);
				return;
			}
			loaded(new Image(qoi.pixels, qoi.width, qoi.height, 1, qoi.channels == 4 ? PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 : PIXELFORMAT_UNCOMPRESSED_R8G8B8));
			return;
		}
		if (!isDecoded(fileType.substr(1))) {
			refuse(name, 'IMAGE: Data format not supported: $fileType', failed);
			return;
		}
		Runtime.decoding.decode(data, image -> loaded(rgba(image.pixels, image.width, image.height)), error -> refuse(name, error, failed));
	}

	// Answers a load that failed: to the program's failed callback, or logged. Every error names the file, as the services' do.
	static function refuse(name:String, error:String, failed:Null<String->Void>):Void {
		if (failed != null)
			failed(error);
		else
			Runtime.log(4, '$name: $error');
	}
	#end
}
