package helix.raylib;

/** Represents raylib's `MaterialMap`: one of a material's maps (`MATERIAL_MAP_*`), a texture with a color and a value.

	The map holds a count on its texture (docs/DECISIONS.md 25): assigning one keeps a copy of its record, retains it and releases the
	texture it replaces, so a texture the program unloads after giving it to a map lives until the map lets go of it. */
@:structInit
class MaterialMap {
	/** Gets or sets the texture; id 0 for none, drawn as white. Assigning keeps a copy of the record, counted as one of the texture's
		holders, and releases the texture it replaces; the material releases it when it is freed. */
	public var texture(default, set):Texture2D;

	/** Gets or sets the color. */
	public var color:Color;

	/** Gets or sets the value. */
	public var value:Float;

	/** Creates a MaterialMap.

		@param texture  Optional. The texture, counted as `texture`'s assignment counts it; none when omitted.
		@param color  Optional. The color; transparent black when omitted.
		@param value  The value. */
	public function new(?texture:Texture2D, ?color:Color, value:Float = 0) {
		this.texture = texture == null ? new Texture2D() : texture;
		this.color = color == null ? new Color() : color;
		this.value = value;
	}

	function set_texture(t:Texture2D):Texture2D {
		if (t == texture)
			return t;
		var kept = new Texture2D(t.id, t.width, t.height, t.mipmaps, t.format);
		kept.flipped = t.flipped;
		kept.mapped = true;
		helix.raylib.internal.Textures.retain(kept.id);
		var old = texture;
		texture = kept;
		if (old != null)
			helix.raylib.internal.Models.releaseTexture(old);
		return kept;
	}
}
