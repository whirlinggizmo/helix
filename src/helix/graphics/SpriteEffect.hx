package helix.graphics;

import haxe.io.Bytes;
import helix.texture.Texture2D;
import helix.texture.Sampling;

/** A sprite effect: a Shader of kind sprite (its fragment stage including helix_sprite) that sprites draw through (Node2D.effect: a
	sprite's, a shape's, a text's or a drawing's own drawing; Batch2D.effect; and a Renderer3D's Sprite3D.effect through its shader's sprite3D variant) in place of the framework's sprite programs, with its own parameters and textures set by name (parameters), kept across the
	shader's reloads. The library's are in helix.shader (SpriteOutline, SpriteFlash, SpriteDissolve, PaletteSwap); an app's own is a
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

	// What a draw through program (its shader, or its sprite3D variant) of texture, sampled by sampling, binds at time: its uniform blocks by
	// slot (block 0 the draw's own, block0; 1 the framework's, the texture's size and the time; the rest its parameters, brought to time), and
	// into textures and samplings its textures by slot (the sprite's at 0, its own after, one unset drawn as the sprite's).

	@:allow(helix.render2d.Batch2D)
	@:allow(helix.render3d.Sprites3D)
	function bind(program:Shader, texture:Texture2D, sampling:Sampling, time:Float, block0:Bytes, textures:Array<Int>,
			samplings:Array<Sampling>):Array<Null<Bytes>> {
		var blocks:Array<Null<Bytes>> = [for (size in program.blockSizes) size > 0 ? Bytes.alloc(size) : null];
		if (blocks.length > 0)
			blocks[0] = block0;
		if (blocks.length > 1 && blocks[1] != null) {
			blocks[1].setFloat(0, texture.width);
			blocks[1].setFloat(4, texture.height);
			blocks[1].setFloat(8, time);
		}
		prepare(time);
		parameters.write(blocks);
		var own = parameters.textureSlots;
		for (slot in program.textureSlots) {
			while (textures.length < slot) {
				textures.push(0);
				samplings.push(Sampling.NEAREST);
			}
			var t = slot > 0 && own.exists(slot) ? own[slot] : null;
			textures.push(t != null ? t.handle : texture.handle);
			samplings.push(t != null ? t.sampling : sampling);
		}
		return blocks;
	}
}
