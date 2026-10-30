package helix.ray;

/** Represents raylib's `MaterialMap`: one of a material's maps (`MATERIAL_MAP_*`), a texture with a color and a value. */
@:structInit
class MaterialMap {
	/** Gets or sets the texture; id 0 for none, drawn as white. */
	public var texture:Texture2D;

	/** Gets or sets the color. */
	public var color:Color;

	/** Gets or sets the value. */
	public var value:Float;

	/** Creates a MaterialMap.

		@param texture  Gets or sets the texture; id 0 for none, drawn as white.
		@param color  Gets or sets the color.
		@param value  Gets or sets the value. */
	public function new(?texture:Texture2D, ?color:Color, value:Float = 0) {
		this.texture = texture == null ? new Texture2D() : texture;
		this.color = color == null ? new Color() : color;
		this.value = value;
	}
}
