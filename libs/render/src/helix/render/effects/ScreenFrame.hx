package helix.render.effects;

import helix.render.RenderTarget2D;
import helix.render.Texture2D;
import helix.services.shaders.ShaderValues;

/** Represents what a screen effect draws from in a `PostProcess` chain, this frame: the frame it changes, its size, the time, and the
	intermediate targets it asked for. */
class ScreenFrame {
	/** Gets the frame the effect changes: the source, or the step before's result. */
	public final source:Texture2D;

	/** Gets the frame's width, in pixels. */
	public final width:Int;

	/** Gets the frame's height, in pixels. */
	public final height:Int;

	/** Gets the seconds `PostProcess.draw` was given. */
	public final time:Float;

	/** Gets the effect's intermediate targets, in the order of its `ScreenEffect.intermediates`. */
	public final intermediates:Array<RenderTarget2D>;

	@:allow(helix.render)
	function new(source:Texture2D, width:Int, height:Int, time:Float, intermediates:Array<RenderTarget2D>) {
		this.source = source;
		this.width = width;
		this.height = height;
		this.time = time;
		this.intermediates = intermediates;
	}

	/** Draws a screen shader once over a whole target, reading a texture as `sourceTexture` (its size, in texels, as `sourceSize`) and
		`time`, filled by name over the values given.

		Into an intermediate it is a target pass of its own, cleared to transparent black; omitted, it draws the effect's result where the
		chain draws it (only in `ScreenEffect.draw`).
		@param values  The values over the shader: a shader from `ScreenEffect.compileShader`, and its own uniforms.
		@param source  The texture it reads.
		@param target  Optional. The intermediate to draw into; the effect's result when omitted. */
	public function drawPass(values:ShaderValues, source:Texture2D, ?target:RenderTarget2D):Void {
		throw "helix-render: ScreenFrame.drawPass is not yet built (stage 5, post-processing)";
	}
}
