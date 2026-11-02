package helix.render;

import haxe.io.Bytes;

/** One pass of a recorded frame: the screen's, or one into a render target, its clear and its commands in the order recorded. */
@:noCompletion
@:allow(helix.render)
class RenderPass {
	// The render target, or null for the screen's pass; the handle drawn into, as it was when the pass began.
	final target:Null<RenderTarget2D>;
	final handle:Int;
	final width:Int;
	final height:Int;
	// The color it is cleared to, or null: for a target, kept as it is; for the screen, opaque black.
	var clear:Null<Int>;
	final commands:Array<RenderCommand> = [];
	// Texture updates made before the pass begins.
	final updates:Array<() -> Void> = [];
	// The streams its draws read, uploaded as it begins.
	final streams:Array<RenderStream> = [];

	function new(target:Null<RenderTarget2D>, handle:Int, width:Int, height:Int, clear:Null<Int>) {
		this.target = target;
		this.handle = handle;
		this.width = width;
		this.height = height;
		this.clear = clear;
	}

	/** Records a draw and notes the streams it reads. */
	function addDraw(draw:RenderDraw):Void {
		commands.push(Draw(draw));
		for (s in draw.streams)
			if (s != null && streams.indexOf(s) < 0)
				streams.push(s);
	}
}

/** A command in a pass, run in the order recorded. */
@:noCompletion
enum RenderCommand {
	/** A GPU draw. */
	Draw(draw:RenderDraw);

	/** The rectangle the following draws fill, in the pass's pixels from its top left. */
	Viewport(x:Int, y:Int, width:Int, height:Int);

	/** The rectangle the following draws are clipped to, in the pass's pixels from its top left. */
	Scissor(x:Int, y:Int, width:Int, height:Int);

	/** No clip for the following draws. */
	ResetScissor;

	/** A data texture rewritten whole before the following draws: its handle, size in texels and floats as bytes. */
	UpdateData(handle:Int, width:Int, height:Int, data:Bytes);
}
