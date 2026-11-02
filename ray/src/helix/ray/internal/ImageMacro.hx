package helix.ray.internal;

#if macro
import haxe.macro.Expr;

using StringTools;

/** Chooses an animated image's reader as the program builds (`Raylib.LoadImageAnimAsync` and `LoadImageAnimFromMemoryAsync`), so a
	program that names no GIF file carries no GIF reader. */
@:noCompletion
class ImageMacro {
	/** Returns the call loading an animated image by the reader its file needs: when its name is known as the program builds
		(`ShaderMacro.known`), the GIF reader alone for a .gif file and the image load alone for any other; otherwise the call choosing by
		the extension as the program runs, which brings both.

		@param fileName  The file's name.
		@param frames  Receives the frame count.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be loaded.
		@return  The call. */
	public static function loadAnim(fileName:Expr, frames:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		var name = ShaderMacro.known(fileName), reader = "loadImageAnim";
		if (name != null)
			reader = name.toLowerCase().endsWith(".gif") ? "loadGifAnim" : "loadStillAnim";
		if (failed == null)
			failed = macro null;
		return macro @:privateAccess $p{["helix", "ray", "raylib", "RAsync", reader]}($fileName, $frames, $loaded, $failed);
	}

	/** Returns the call decoding an animated image's bytes by the reader its type needs: when the type is known as the program builds,
		the GIF reader alone for ".gif" or ".GIF" (raylib's two spellings) and the image decode alone for any other; otherwise the call
		choosing as the program runs, which brings both.

		@param fileType  The file's extension.
		@param fileData  The file's bytes.
		@param dataSize  How many of them.
		@param frames  Receives the frame count.
		@param loaded  Receives the image.
		@param failed  Optional. Receives why it couldn't be decoded.
		@return  The call. */
	public static function loadAnimFromMemory(fileType:Expr, fileData:Expr, dataSize:Expr, frames:Expr, loaded:Expr, failed:Null<Expr>):Expr {
		var type = ShaderMacro.known(fileType), reader = "decodeImageAnim";
		if (type != null)
			reader = type == ".gif" || type == ".GIF" ? "decodeGifAnim" : "decodeStillAnim";
		if (failed == null)
			failed = macro null;
		return macro @:privateAccess $p{["helix", "ray", "raylib", "RAsync", reader]}($fileType, $fileData, $dataSize, $frames, $loaded, $failed);
	}
}
#end
