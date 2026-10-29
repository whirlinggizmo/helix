package helix.platform;

import haxe.io.Bytes;

/** Defines image decoding: a PNG, JPEG, BMP, TGA or GIF file (its first frame) into 8-bit RGBA, rows top to bottom, not premultiplied. */
interface IImageDecoder extends IPollable {
	/** Decodes a file, off the main thread where the platform can.

		One of `decoded` or `failed` is called once, on the main thread, never during this call.
		@param encoded  The file's bytes.
		@param decoded  Receives the pixels, `width * height * 4` bytes, and the image's width and height.
		@param failed  Receives why the file can't be read. */
	function decode(encoded:Bytes, decoded:(pixels:Bytes, width:Int, height:Int) -> Void, failed:String->Void):Void;

	/** Delivers what finished on the platform's threads since the last poll; call once a frame. */
	function poll():Void;

	/** Closes the decoder; a decode still running finishes without answering. */
	function dispose():Void;
}
