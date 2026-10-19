package helix.graphics;

/** A sprite effect: a Shader of kind sprite (its fragment stage including helix_sprite) that 2D sprites draw through (Sprite2D.effect,
	Batch2D.effect) in place of the framework's sprite program, with its own parameters and textures set by name (parameters), kept across the
	shader's reloads. The library's are in helix.shaders (SpriteOutline, SpriteFlash, SpriteDissolve, PaletteSwap); an app's own is a
	.hxshader (Shaders.load) made into one with new. An effect is shared, not a sprite's own: every sprite drawn with it in a frame draws with
	its parameters as they are when the batch ends, and the sprites drawn with one effect one after another, of one texture, are one draw. A
	sprite wanting values of its own (its own flash) has an effect of its own, a draw of its own. */
class SpriteEffect {
	/** An effect drawing with shader (kind sprite). Throws for a shader of another kind. */
	public function new(shader:Shader) {
		if (shader.kind != "sprite")
			throw 'A ${shader.kind} shader is not a sprite effect';
		this.shader = shader;
		parameters = new ShaderParameters(shader);
	}

	/** Its shader. */
	public var shader(default, null):Shader;

	/** Its shader's own parameters and textures, set by name. A texture of its own that isn't set is drawn as the sprite's. */
	public var parameters(default, null):ShaderParameters;

	/** Brings its parameters to time, seconds of the batch's clock (Batch2D.time), just before a batch draws with it (once for each draw):
		nothing by default; an effect changing over time (SpriteFlash's fade) overrides it. */
	public function prepare(time:Float):Void {}
}
