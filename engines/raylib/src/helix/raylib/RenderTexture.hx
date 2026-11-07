package helix.raylib;

/** Represents raylib's `RenderTexture`, also its `RenderTexture2D`: a texture drawn into between `BeginTextureMode` and `EndTextureMode`.

	The texture is upside down, as in raylib. Drawing it with a negative source height shows it the right way up. */
@:structInit
class RenderTexture {
	/** Gets the render target's handle, 0 for none. */
	public var id:Int;

	/** Gets the color the render texture holds. */
	public var texture:Texture2D;

	/** Gets the depth the render texture is drawn with, which can't be sampled, so its id is 0. */
	public var depth:Texture2D;

	/** Creates a render texture's record. See `Raylib.LoadRenderTexture` for making a render texture.

		@param id  The render target's handle.
		@param texture  Its color.
		@param depth  Its depth. */
	public function new(id:Int = 0, ?texture:Texture2D, ?depth:Texture2D) {
		this.id = id;
		this.texture = texture == null ? new Texture2D() : texture;
		this.depth = depth == null ? new Texture2D() : depth;
	}
}
