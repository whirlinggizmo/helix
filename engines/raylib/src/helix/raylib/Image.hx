package helix.raylib;

/** Represents raylib's `Image`: pixels in memory, in one of raylib's pixel formats.

	The bytes are laid out as raylib's are: rows top first, each pixel `GetPixelDataSize(1, 1, format)` bytes; 16-bit values (the packed
	formats, the half floats) and 32-bit floats little-endian. An image with mipmaps holds its smaller levels after it, each half the size
	of the last. The `Image*` functions change an image in place, as raylib's do through its pointer: its fields are replaced. */
class Image {
	/** Gets or sets the pixels, or null for none. */
	public var data:Null<haxe.io.Bytes>;

	/** Gets or sets the width, in pixels. */
	public var width:Int;

	/** Gets or sets the height, in pixels. */
	public var height:Int;

	/** Gets or sets the number of mipmap levels, 1 for the image alone. */
	public var mipmaps:Int;

	/** Gets or sets the pixel format (`PIXELFORMAT_*`). */
	public var format:Int;

	/** Creates an image's record. Its fields are zero and its data null unless given, as raylib's `Image image = { 0 }` is; images are
		made by the `GenImage*` functions and loaded by `LoadImageAsync`.

		@param data  Optional. The pixels.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param mipmaps  The number of mipmap levels.
		@param format  The pixel format (`PIXELFORMAT_*`). */
	public function new(?data:haxe.io.Bytes, width:Int = 0, height:Int = 0, mipmaps:Int = 0, format:Int = 0) {
		this.data = data;
		this.width = width;
		this.height = height;
		this.mipmaps = mipmaps;
		this.format = format;
	}
}
