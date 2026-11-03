package helix.raylib;

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

	/** Gets the pixel format: the image's for a texture made of one (`LoadTextureFromImage`; a glTF model's roughness and metalness
		maps are `PIXELFORMAT_UNCOMPRESSED_GRAYSCALE`), `PIXELFORMAT_UNCOMPRESSED_R8G8B8A8` for the rest. Its pixels are RGBA on the GPU
		either way. */
	public var format:Int;

	// A render texture's color, which raylib stores bottom row first, so it draws upside down unless flipped as raylib's programs do.
	@:allow(helix.raylib)
	var flipped = false;

	// A material map's copy (`MaterialMap.texture`), which holds the map's count: `UnloadTexture` given it lets go of one of the program's
	// holds when there is one, else of the map's (`spent`), and leaves its id while the texture lives, as the map still draws it.
	@:allow(helix.raylib)
	var mapped = false;

	// Whether a map's copy has let go of the map's count already, through `UnloadTexture`, so the map doesn't again.
	@:allow(helix.raylib)
	var spent = false;

	/** Creates a texture's record. Textures are made by `Raylib.LoadTextureAsync`.

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
