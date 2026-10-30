package helix.ray;

/** Represents raylib's `Texture2D`: an image on the GPU. */
@:structInit
class Texture2D {
	/** Gets the texture's handle, 0 for none. */
	public var id:Int;

	/** Gets the width, in pixels. */
	public var width:Int;

	/** Gets the height, in pixels. */
	public var height:Int;

	/** Gets the number of mipmap levels, 1 for none. */
	public var mipmaps:Int;

	/** Gets the pixel format, `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` for every texture loaded here. */
	public var format:Int;

	/** Creates a texture's record. Textures are made by `Raylib.LoadTexture`.

		@param id  The handle.
		@param width  The width, in pixels.
		@param height  The height, in pixels.
		@param mipmaps  The number of mipmap levels.
		@param format  The pixel format. */
	public function new(id:Int = 0, width:Int = 0, height:Int = 0, mipmaps:Int = 1, format:Int = 7) {
		this.id = id;
		this.width = width;
		this.height = height;
		this.mipmaps = mipmaps;
		this.format = format;
	}
}
