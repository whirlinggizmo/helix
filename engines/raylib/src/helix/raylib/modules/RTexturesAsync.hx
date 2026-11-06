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
import helix.raylib.modules.RTextAsync.*;
import helix.raylib.modules.RModelsAsync.*;
import helix.raylib.modules.RAudioAsync.*;
#end

/** Holds the async versions of rtextures' image and texture loads and writes, helix-raylib's own in place of raylib's calls that wait
	for a file, the GPU or a write. Each is written here, and `helix.raylib.extras.Textures` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RTexturesAsync {
	#if !macro
	// LoadImageAsync's call where its file's name isn't known as the program builds (extras.Textures.LoadImageAsync): a GIF file's first frame
	// or the other decodes, picked by its extension as it runs, so both are in the program.
	static function loadImage(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifImage(fileName, loaded, failed);
		else
			loadPlainImage(fileName, loaded, failed);
	}

	// LoadImageAsync's call for a GIF file: its first frame, kept as the file's image.
	static function loadGifImage(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		gifFile("LoadImageAsync", path, () -> {
			var image = Runtime.image(path);
			loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height));
		}, failed);
	}

	// Brings a GIF file into memory, its first frame composited as raylib 5.5's LoadImage reads it (gifFrames) and kept as the file's
	// image (Runtime.images), then calls done; a file that can't be read or is no GIF is refused for the load named.
	static function gifFile(name:String, path:String, done:Void->Void, failed:Null<String->Void>):Void {
		Runtime.fetch(path, error -> {
			if (error != null) {
				refuse(name, error, failed);
				return;
			}
			if (!Runtime.images.exists(path)) {
				var frame = gifFrames(name, path, Runtime.files.get(path), false, failed);
				if (frame == null)
					return;
				Runtime.images.set(path, new helix.services.images.Image(path, frame.width, frame.height, frame.data));
			}
			done();
		});
	}

	// LoadImageAsync's call for any other file.
	static function loadPlainImage(fileName:String, loaded:Image->Void, ?failed:String->Void):Void {
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
		Runtime.fetchImage(path, error -> {
			if (error != null) {
				refuse("LoadImageAsync", error, failed);
				return;
			}
			var image = Runtime.image(path);
			loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height));
		});
	}

	/** Loads an image's raw pixels from a file, answering when they are read: helix-raylib's own, in place of raylib's `LoadImageRaw`. The
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

	// LoadImageFromMemoryAsync's call where its type isn't known as the program builds (extras.Textures.LoadImageFromMemoryAsync): raylib's two
	// spellings of ".gif" read as GIF, any other type decoded as the rest are, so both are in the program.
	static function decodeImage(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileType == ".gif" || fileType == ".GIF")
			decodeGifImage(fileType, fileData, dataSize, loaded, failed);
		else
			decodePlainImage(fileType, fileData, dataSize, loaded, failed);
	}

	// LoadImageFromMemoryAsync's call for a GIF file's bytes: its first frame.
	static function decodeGifImage(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.later(() -> {
			var frame = gifFrames("LoadImageFromMemoryAsync", "IMAGE", data, false, failed);
			if (frame != null)
				loaded(frame);
		});
	}

	// LoadImageFromMemoryAsync's call for any other type.
	static function decodePlainImage(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.imaging();
		Runtime.later(() -> decoded("LoadImageFromMemoryAsync", fileType == null ? "" : fileType.toLowerCase(), data, loaded, failed));
	}

	// LoadImageAnimAsync's call where its file's name isn't known as the program builds (extras.Textures.LoadImageAnimAsync): the GIF reader or
	// the image load picked by its extension as it runs, so both are in the program.
	static function loadImageAnim(fileName:String, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifAnim(fileName, frames, loaded, failed);
		else
			loadStillAnim(fileName, frames, loaded, failed);
	}

	// LoadImageAnimAsync's call for a GIF file.
	static function loadGifAnim(fileName:String, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetch(path, error -> {
			if (error != null)
				refuse("LoadImageAnimAsync", error, failed);
			else
				gifAnim("LoadImageAnimAsync", path, Runtime.files.get(path), frames, loaded, failed);
		});
	}

	// LoadImageAnimAsync's call for any other file: the image, one frame.
	static function loadStillAnim(fileName:String, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		loadPlainImage(fileName, image -> {
			frames[0] = 1;
			loaded(image);
		}, error -> refuse("LoadImageAnimAsync", error, failed));
	}

	// LoadImageAnimFromMemoryAsync's call where its type isn't known as the program builds: raylib's two spellings of ".gif" read as GIF.
	static function decodeImageAnim(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileType == ".gif" || fileType == ".GIF")
			decodeGifAnim(fileType, fileData, dataSize, frames, loaded, failed);
		else
			decodeStillAnim(fileType, fileData, dataSize, frames, loaded, failed);
	}

	// LoadImageAnimFromMemoryAsync's call for a GIF file's bytes.
	static function decodeGifAnim(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		if (fileData == null || dataSize == 0) {
			Runtime.later(() -> refuse("LoadImageAnimFromMemoryAsync", "IMAGE: Invalid file data", failed));
			return;
		}
		var data = dataSize < fileData.length ? fileData.sub(0, dataSize) : fileData;
		Runtime.later(() -> gifAnim("LoadImageAnimFromMemoryAsync", "IMAGE", data, frames, loaded, failed));
	}

	// LoadImageAnimFromMemoryAsync's call for any other type: the image, one frame.
	static function decodeStillAnim(fileType:String, fileData:haxe.io.Bytes, dataSize:Int, frames:Array<Int>, loaded:Image->Void, ?failed:String->Void):Void {
		decodePlainImage(fileType, fileData, dataSize, image -> {
			frames[0] = 1;
			loaded(image);
		}, error -> refuse("LoadImageAnimFromMemoryAsync", error, failed));
	}

	// A GIF file's frames, as raylib 5.5's LoadImageAnim gives them (gifFrames), and their count.
	static function gifAnim(name:String, what:String, data:haxe.io.Bytes, frames:Array<Int>, loaded:Image->Void, failed:Null<String->Void>):Void {
		var all = gifFrames(name, what, data, true, failed);
		if (all == null)
			return;
		frames[0] = Std.int(all.data.length / (all.width * all.height * 4));
		loaded(all);
	}

	// A broken GIF file's frames before its break, as stb_image keeps them: the most frames that read (GifFile.read's limit), or null
	// when not even the first does.
	static function gifBefore(data:haxe.io.Bytes):Null<helix.formats.gif.GifFile> {
		var read:Null<helix.formats.gif.GifFile> = null;
		while (true) {
			var count = read == null ? 1 : read.frames.length + 1;
			var next = try helix.formats.gif.GifFile.read(data, count) catch (e:String) null;
			if (next == null || next.frames.length < count)
				return read;
			read = next;
		}
	}

	// A GIF file's frames as one image, the screen's size, each frame after the last, composited as raylib 5.5 composites them
	// (stb_image's GIF reader): every frame (LoadImageAnim) or the first alone (LoadImage). As stb, the first alone is read with
	// nothing after it, and every frame of a file broken after some are those before the break (gifBefore), so a file broken after its
	// first frame loads it. helix-formats reads the file; the frames are drawn here by stb's rules. The screen starts transparent. Before each frame, a last frame disposed of to the background or the
	// previous frame has its rectangle put back as it was before it was drawn (stb restores both so, and for Previous from the third
	// frame on reads before its own buffer: docs/DECISIONS.md 24). After the first frame, when the background index isn't 0, the
	// pixels outside its rectangle take the global table's color there, opaque, its bytes in stb's palette order (blue, green, red), or
	// opaque black where the table has none. A file that can't be read, or has no frames, is refused for the load named, giving null.
	static function gifFrames(name:String, what:String, data:haxe.io.Bytes, all:Bool, failed:Null<String->Void>):Null<Image> {
		var gif = try helix.formats.gif.GifFile.read(data, all ? null : 1) catch (e:String) {
			var before = all ? gifBefore(data) : null;
			if (before == null) {
				refuse(name, '$what: $e', failed);
				return null;
			}
			before;
		}
		var width = gif.width,
			height = gif.height,
			size = width * height * 4,
			count = gif.frames.length;
		if (count == 0 || size * 1.0 * count > 0x7FFFFFFF) {
			refuse(name, count == 0 ? '$what: a GIF file with no frames' : '$what: $count frames of $width x $height pixels, over 2 GB', failed);
			return null;
		}
		var pixels = haxe.io.Bytes.alloc(size * count),
			screen = haxe.io.Bytes.alloc(size),
			before = haxe.io.Bytes.alloc(size);
		for (n in 0...count) {
			var frame = gif.frames[n];
			if (n > 0) {
				var last = gif.frames[n - 1];
				if (last.disposal == helix.formats.gif.GifDisposal.Background || last.disposal == helix.formats.gif.GifDisposal.Previous)
					for (row in last.y...last.y + last.height)
						screen.blit((row * width + last.x) * 4, before, (row * width + last.x) * 4, last.width * 4);
			}
			before.blit(0, screen, 0, size);
			var colors = frame.colors, i = 0;
			for (row in 0...frame.height) {
				var p = ((frame.y + row) * width + frame.x) * 4;
				for (_ in 0...frame.width) {
					var index = frame.indices.get(i++);
					if (index != frame.transparentIndex && index < colors.length) {
						var color = colors[index];
						screen.set(p, (color >> 16) & 0xFF);
						screen.set(p + 1, (color >> 8) & 0xFF);
						screen.set(p + 2, color & 0xFF);
						screen.set(p + 3, 255);
					}
					p += 4;
				}
			}
			if (n == 0 && gif.backgroundIndex > 0) {
				var color = gif.colors != null && gif.backgroundIndex < gif.colors.length ? gif.colors[gif.backgroundIndex] : 0xFF000000;
				for (y in 0...height)
					for (x in 0...width)
						if (x < frame.x || x >= frame.x + frame.width || y < frame.y || y >= frame.y + frame.height) {
							var p = (y * width + x) * 4;
							screen.set(p, color & 0xFF);
							screen.set(p + 1, (color >> 8) & 0xFF);
							screen.set(p + 2, (color >> 16) & 0xFF);
							screen.set(p + 3, 255);
						}
			}
			pixels.blit(n * size, screen, 0, size);
		}
		return rgba(pixels, width, height);
	}

	// LoadTextureAsync's call where its file's name isn't known as the program builds (extras.Textures.LoadTextureAsync): a GIF file's first
	// frame or the platform's decode, picked by its extension as it runs, so both are in the program.
	static function loadTextureFile(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		if (isGif(fileName))
			loadGifTexture(fileName, loaded, failed);
		else
			loadPlainTexture(fileName, loaded, failed);
	}

	// LoadTextureAsync's call for a GIF file: its first frame, kept as the file's image so later loads share its texture.
	static function loadGifTexture(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		gifFile("LoadTextureAsync", path, () -> loaded(RTextures.loadTexture(path)), failed);
	}

	// LoadTextureAsync's call for any other file.
	static function loadPlainTexture(fileName:String, loaded:Texture2D->Void, ?failed:String->Void):Void {
		var path = normalize(fileName);
		Runtime.fetchImage(path, error -> error == null ? loaded(RTextures.loadTexture(path)) : refuse("LoadTextureAsync", error, failed));
	}

	/** Reads a texture's pixels, answering when they are read: helix-raylib's own, in place of raylib's `LoadImageFromTexture`, as the GPU
		answers later. A texture on the GPU (one drawn, or a render texture) is read back from it as the frames drawn so far left it; a
		render texture's rows come bottom first, as raylib's do, so it reads upside down as raylib's does. A texture updated this frame
		(`UpdateTexture`) is read once the frame is drawn, so the update shows. One not drawn yet is read from memory (raylib's default
		texture is its white pixel). The image is RGBA, whatever the texture's format. A cubemap's can't be read.

		@param texture  The texture.
		@param loaded  Receives the image, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8`.
		@param failed  Optional. Receives why it couldn't be read; when omitted, it is logged. */
	static function LoadImageFromTextureAsync(texture:Texture2D, loaded:Image->Void, ?failed:String->Void):Void {
		var gpu = Textures.isCube(texture.id) ? 0 : Textures.onGpu(texture.id);
		if (gpu == 0) {
			var image = Textures.imageOf(texture.id);
			Runtime.later(() -> image == null ? refuse("LoadImageFromTextureAsync", 'TEXTURE: [ID ${texture.id}] Failed to retrieve pixel data',
				failed) : loaded(rgba(image.pixels.sub(0, image.pixels.length), image.width, image.height)));
			return;
		}
		function read():Void {
			var during = true;
			Runtime.graphics.readPixels(gpu, (pixels, width, height) -> {
				var image = rgba(pixels, width, height);
				if (texture.flipped)
					ImageFlipVertical(image);
				Runtime.log(LOG_INFO, 'TEXTURE: [ID ${texture.id}] Pixel data retrieved successfully');
				during ? Runtime.later(() -> loaded(image)) : loaded(image);
			},
				error -> during ? Runtime.later(() -> refuse("LoadImageFromTextureAsync", error, failed)) : refuse("LoadImageFromTextureAsync", error, failed));
			during = false;
		}
		if (Runtime.frame.isUpdating(gpu))
			Runtime.frame.afterDraw(read);
		else
			read();
	}

	/** Reads the screen, answering as the next frame ends: helix-raylib's own, in place of raylib's `LoadImageFromScreen`, as the GPU
		answers later. The image is the framebuffer's size, as raylib 6.2's is (5.5 scaled the screen's size by its DPI instead), rows top
		first, its alpha opaque.

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

	/** Writes an image to a file through `SaveFileDataAsync`, as raylib's default build's `ExportImage` writes it: ".png" (any
		uncompressed format; a format other than 8-bit grayscale, grayscale and alpha, RGB or RGBA is written as RGBA), ".qoi" (RGB or
		RGBA alone) or ".raw" (the pixels as they are). helix-raylib's own, answering once the file is written. The file is kept as
		`SaveFileDataAsync` keeps it; `TakeScreenshotAsync` writes a real file.

		@param image  The image.
		@param fileName  The file; its extension chooses the format.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't, such as an empty image or another extension; when omitted, it is logged. */
	static function ExportImageAsync(image:Image, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		var file = image.width == 0 || image.height == 0 || image.data == null ? null : RTextures.encodeImage(image, fileName);
		exportData("ExportImageAsync", fileName, file, "Image exported successfully", "Failed to export image", done, failed);
	}

	/** Writes an image as a C header through `SaveFileTextAsync`, as raylib's `ExportImageAsCode` does: its size and format as defines,
		and its pixels (the first level's) as an array of bytes, 20 a line. helix-raylib's own, answering once the file is written.

		@param image  The image.
		@param fileName  The file; its name, upper case, names the defines and the array.
		@param done  Optional. Called once the file is written, at a later poll.
		@param failed  Optional. Receives why it wasn't; when omitted, it is logged. */
	static function ExportImageAsCodeAsync(image:Image, fileName:String, ?done:Void->Void, ?failed:String->Void):Void {
		exportText("ExportImageAsCodeAsync", fileName, RTextures.imageAsCode(image, fileName), "Image as code exported successfully", done, failed);
	}

	// Whether a file's extension is .gif, in any case.
	static function isGif(fileName:String):Bool {
		return haxe.io.Path.extension(normalize(fileName)).toLowerCase() == "gif";
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
			loaded(new Image(qoi.pixels, qoi.width, qoi.height, 1,
				qoi.channelCount == 4 ? PIXELFORMAT_UNCOMPRESSED_R8G8B8A8 : PIXELFORMAT_UNCOMPRESSED_R8G8B8));
			return;
		}
		if (!isDecoded(fileType.substr(1))) {
			refuse(name, 'IMAGE: Data format not supported: $fileType', failed);
			return;
		}
		Runtime.decoding.decode(data, image -> loaded(rgba(image.pixels, image.width, image.height)), error -> refuse(name, error, failed));
	}
	#end
}
