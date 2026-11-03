package helix.raylib;

/** Represents raylib's `RenderTexture`, which is also its `RenderTexture2D`: a texture drawn into between `BeginTextureMode` and
	`EndTextureMode`. As in raylib, its texture is upside down: draw it with a negative source height to show it the right way up. */
@:structInit
class RenderTexture {
	/** Gets the render target's handle, 0 for none. */
	public var id:Int;

	/** Gets the color it is drawn into. */
	public var texture:Texture2D;

	/** Gets the depth it is drawn with; it can't be sampled here, so its id is 0. */
	public var depth:Texture2D;

	/** Creates a render texture's record. Render textures are made by `Raylib.LoadRenderTexture`.

		@param id  The render target's handle.
		@param texture  Its color.
		@param depth  Its depth. */
	public function new(id:Int = 0, ?texture:Texture2D, ?depth:Texture2D) {
		this.id = id;
		this.texture = texture == null ? new Texture2D() : texture;
		this.depth = depth == null ? new Texture2D() : depth;
	}
}
