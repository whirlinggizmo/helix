package helix.graphics;

import haxe.io.Bytes;
import helix.render2d.Texture2D;

/** A screen effect: a Shader of kind screen drawn over a whole frame (one triangle over the viewport), with its own parameters and textures set
	by name (parameters), kept across the shader's reloads. PostProcess chains them (PostProcess.add); drawPass draws its shader once into the
	open pass. An effect of several passes (a subclass: a blur, a bloom's downsample chain) asks for intermediates, draws into them before its
	last pass (drawIntermediates, each step a ScreenEffect of its own drawn with drawInto) and reads more than one of them through its own
	textures (parameters.setTexture). */
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

	/** Whether it reads an HDR frame: in a chain with one, PostProcess draws the scene in half floats where the GPU can (IGraphics.canRender),
		its colors running past 1, and tone maps it after the last such effect (helix.shaders.Tonemap). False (the default) for an effect that
		reads the frame as the screen shows it, tone mapped, 0 to 1. */
	public var hdr:Bool = false;

	/** The textures it draws through before its last pass, each its size as a fraction of the frame's each way (.5: half; at least a pixel):
		PostProcess makes them in the frame's format, without depth, and hands them over in ScreenFrame.intermediates. Empty (the default) for
		an effect of one pass. */
	public var intermediates(default, null):Array<Float> = [];

	/** Draws its passes before the last into frame.intermediates, each a target pass (drawInto), before the screen's pass: nothing for an
		effect of one pass (the default). */
	public function drawIntermediates(frame:ScreenFrame):Void {}

	/** Draws its last pass over the open pass's viewport, frame.width x frame.height pixels: by default its shader once, reading frame.source. */
	public function draw(frame:ScreenFrame):Void
		drawPass(frame.source, frame.width, frame.height, frame.time);

	/** Draws its shader once into target in a target pass of its own (cleared to transparent black), reading source, time seconds since it
		began: one step of an effect of several passes. Before the screen's pass, outside any other. */
	public function drawInto(target:Texture2D, source:Texture2D, time:Float):Void {
		gpu.beginTargetPass(target.handle, 0x00000000);
		drawPass(source, target.width, target.height, time);
		gpu.endTargetPass();
	}

	/** Draws its shader once over the open pass's viewport, reading source (the frame it changes), width x height pixels, seconds since it
		began. A texture of its own that isn't set is drawn as source. */
	public function drawPass(source:Texture2D, width:Int, height:Int, time:Float):Void {
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
