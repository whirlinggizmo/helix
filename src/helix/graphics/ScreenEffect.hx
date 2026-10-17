package helix.graphics;

import haxe.io.Bytes;
import helix.render2d.Texture2D;

/** A screen effect: a Shader of kind screen drawn over a whole frame (one triangle over the viewport), with its own parameters and textures set
	by name (parameters), kept across the shader's reloads. PostProcess chains them; draw draws one into the open pass. */
class ScreenEffect {
	var gpu:IGraphics;
	var alpha:Bool;

	/** An effect drawing with shader (kind screen) on gpu, blended over what's there when alpha, else replacing it. Throws for a shader of another
		kind. */
	public function new(gpu:IGraphics, shader:Shader, alpha = false) {
		if (shader.kind != "screen")
			throw 'A ${shader.kind} shader is not a screen effect';
		this.gpu = gpu;
		this.shader = shader;
		this.alpha = alpha;
		parameters = new ShaderParameters(shader);
	}

	/** Its shader. */
	public var shader(default, null):Shader;

	/** Its shader's own parameters and textures, set by name. */
	public var parameters(default, null):ShaderParameters;

	/** Whether PostProcess draws it. */
	public var enabled:Bool = true;

	/** Draws the effect over the open pass's viewport, reading source (the frame it changes), width x height pixels, seconds since it began. A
		texture of its own that isn't set is drawn as source. */
	public function draw(source:Texture2D, width:Int, height:Int, time:Float):Void {
		var blocks = [for (size in shader.blockSizes) size > 0 ? Bytes.alloc(size) : null];
		// The framework's: block 1 is the frame's size and the time (block 0 the adapter's clip scale).
		if (blocks.length > 1 && blocks[1] != null) {
			blocks[1].setFloat(0, width);
			blocks[1].setFloat(4, height);
			blocks[1].setFloat(8, time);
		}
		parameters.write(blocks);
		var own = parameters.textureSlots, textures = [], samplings = [];
		for (slot in shader.textureSlots) {
			// Slot 0 is the frame; the effect's own are theirs, or the frame.
			var texture = slot > 0 && own.exists(slot) ? own[slot] : source;
			while (textures.length < slot) {
				textures.push(0);
				samplings.push(Sampling.NEAREST);
			}
			textures.push(texture.handle);
			samplings.push(texture.sampling);
		}
		gpu.draw(Pipelines.of(gpu).screen(shader.handle, alpha ? Alpha : Opaque), [], 0, 0, 3, 0, 1, textures, samplings, blocks);
	}
}
