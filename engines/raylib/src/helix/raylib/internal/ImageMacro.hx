package helix.raylib.internal;

#if macro
import haxe.macro.Expr;

using StringTools;

/** Chooses an image file's reader as the program builds (`LoadImageAsync`, `LoadImageFromMemoryAsync`, `LoadTextureAsync`,
	`LoadFontAsync`, `LoadImageAnimAsync` and `LoadImageAnimFromMemoryAsync`), so a program that names no GIF file carries no GIF
	reader. */
@:noCompletion
class ImageMacro {
	/** Returns the call loading an image file by the reader its file needs (`LoadImageAsync`).

		@param fileName  The file's name.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be loaded.
		@return  The call. */
	public static function load(fileName:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		return byName("RTexturesAsync", fileName, ["loadImage", "loadGifImage", "loadPlainImage"], [fileName, loaded, orNull(failed)]);
	}

	/** Returns the call decoding an image file's bytes by the reader its type needs (`LoadImageFromMemoryAsync`).

		@param fileType  The file's extension.
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be decoded.
		@return  The call. */
	public static function loadFromMemory(fileType:Expr, fileData:Expr, dataSize:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		return byType("RTexturesAsync", fileType, ["decodeImage", "decodeGifImage", "decodePlainImage"],
			[fileType, fileData, dataSize, loaded, orNull(failed)]);
	}

	/** Returns the call loading an image file as a texture by the reader its file needs (`LoadTextureAsync`).

		@param fileName  The file's name.
		@param loaded  Receives the texture.
		@param failed  Optional. Receives why it couldn't be loaded.
		@return  The call. */
	public static function loadTexture(fileName:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		return byName("RTexturesAsync", fileName, ["loadTextureFile", "loadGifTexture", "loadPlainTexture"], [fileName, loaded, orNull(failed)]);
	}

	/** Returns the call loading a font file by the reader its file needs (`LoadFontAsync`).

		@param fileName  The file's name.
		@param loaded  Receives the font.
		@param failed  Optional. Receives why it couldn't be loaded.
		@return  The call. */
	public static function loadFont(fileName:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		return byName("RTextAsync", fileName, ["loadFont", "loadGifFont", "loadPlainFont"], [fileName, loaded, orNull(failed)]);
	}

	/** Returns the call loading an animated image by the reader its file needs (`LoadImageAnimAsync`).

		@param fileName  The file's name.
		@param frames  Receives the frame count.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be loaded.
		@return  The call. */
	public static function loadAnim(fileName:Expr, frames:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		return byName("RTexturesAsync", fileName, ["loadImageAnim", "loadGifAnim", "loadStillAnim"], [fileName, frames, loaded, orNull(failed)]);
	}

	/** Returns the call decoding an animated image's bytes by the reader its type needs (`LoadImageAnimFromMemoryAsync`).

		@param fileType  The file's extension.
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param frames  Receives the frame count.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be decoded.
		@return  The call. */
	public static function loadAnimFromMemory(fileType:Expr, fileData:Expr, dataSize:Expr, frames:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		return byType("RTexturesAsync", fileType, ["decodeImageAnim", "decodeGifAnim", "decodeStillAnim"],
			[fileType, fileData, dataSize, frames, loaded, orNull(failed)]);
	}

	// The call to one of a section's readers [choosing as the program runs, GIF, any other]: when the file's name is known as the program
	// builds (ShaderMacro.known), the GIF reader alone for a .gif file (in any case) and the other alone for any other; otherwise the one
	// choosing by the extension as the program runs, which brings both.
	static function byName(section:String, fileName:Expr, readers:Array<String>, args:Array<Expr>):Expr {
		var name = ShaderMacro.known(fileName);
		return call(section, name == null ? readers[0] : name.toLowerCase().endsWith(".gif") ? readers[1] : readers[2], args);
	}

	// As byName, by a type known as the program builds: ".gif" and ".GIF", raylib's two spellings, read as GIF.
	static function byType(section:String, fileType:Expr, readers:Array<String>, args:Array<Expr>):Expr {
		var type = ShaderMacro.known(fileType);
		return call(section, type == null ? readers[0] : type == ".gif" || type == ".GIF" ? readers[1] : readers[2], args);
	}

	static function call(section:String, reader:String, args:Array<Expr>):Expr {
		return macro @:privateAccess $p{["helix", "raylib", "modules", section, reader]}($a{args});
	}

	static function orNull(failed:Null<Expr>):Expr {
		return failed == null ? macro null : failed;
	}
}
#end
