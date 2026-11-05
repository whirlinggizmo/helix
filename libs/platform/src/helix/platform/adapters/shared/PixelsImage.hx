package helix.platform.adapters.shared;

import haxe.io.Bytes;
import helix.platform.IDecodedImage;

/** Provides `IDecodedImage` over pixels already decoded: what the native decoders give `decodeForGpu`, and any decoder without a GPU image
	of its own. */
@:noCompletion
class PixelsImage implements IDecodedImage {
	public var width(get, never):Int;

	final w:Int;

	function get_width():Int
		return w;

	public var height(get, never):Int;

	final h:Int;

	function get_height():Int
		return h;

	/** Gets 0: there is no browser image, the pixels are the image. */
	public var bitmapHandle(get, never):Int;

	function get_bitmapHandle():Int
		return 0;

	var rgba:Null<Bytes>;

	/** Makes the image of pixels.

		@param width  Its width, in pixels.
		@param height  Its height, in pixels.
		@param pixels  Its pixels, 8-bit RGBA with rows top to bottom, `width * height * 4` bytes. */
	public function new(width:Int, height:Int, pixels:Bytes) {
		w = width;
		h = height;
		rgba = pixels;
	}

	/** Returns the pixels it was made of.

		@return  The pixels.
		@throws String  It was disposed. */
	public function pixels():Bytes {
		if (rgba == null)
			throw "The image was disposed";
		return rgba;
	}

	public function dispose():Void
		rgba = null;
}
