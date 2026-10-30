package helix.services.images;

import haxe.io.Bytes;

/** Represents a decoded image: its size and its pixels. */
class Image {
	/** Gets the path it was loaded from, or "" for one decoded from bytes. */
	public final path:String;

	/** Gets the width, in pixels. */
	public final width:Int;

	/** Gets the height, in pixels. */
	public final height:Int;

	/** Gets the pixels: 8-bit red, green, blue and alpha, `width * height * 4` bytes, rows top first, alpha not premultiplied. */
	public final pixels:Bytes;

	/** Creates an image. Images are made by `Images.load` and `Images.decode`.

		@param path  The path it was loaded from, or "".
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param pixels  The pixels. */
	public function new(path:String, width:Int, height:Int, pixels:Bytes) {
		this.path = path;
		this.width = width;
		this.height = height;
		this.pixels = pixels;
	}
}
