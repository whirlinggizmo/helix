package helix.debug;

import helix.render2d.Batch2D;
import helix.render2d.Text2D;

/** The frame rate and the frame's cost, averaged over half a second, drawn in a corner in screen units (a Camera2D at zoom 1). */
class FpsOverlay {
	var rate = 0.;
	var milliseconds = 0.;

	/** Frames a second over the last half second. */
	public var frameRate(get, never):Float;

	function get_frameRate():Float
		return rate;

	/** The frame's average cost in milliseconds over the last half second. */
	public var frameMs(get, never):Float;

	function get_frameMs():Float
		return milliseconds;

	var frames = 0;
	var time = 0.;
	var cost = 0.;

	/** An overlay showing 0 until half a second of frames has been seen. */
	public function new() {}

	/** dt: the frame's interval; cpu: what the frame cost, in milliseconds (Time.frameCpu). */
	public function update(dt:Float, cpu:Float):Void {
		frames++;
		time += dt;
		cost += cpu;
		if (time >= .5) {
			rate = frames / time;
			milliseconds = cost / frames;
			frames = 0;
			time = 0;
			cost = 0;
		}
	}

	/** Draws the rate and cost with the top-left at x, y; size is the glyph height and color is 0xRRGGBBAA. */
	public function draw(batch:Batch2D, x:Float, y:Float, size = 16., color = 0x7fe07fff):Void
		Text2D.draw(batch, Std.int(rate + .5) + ' FPS  ' + (Math.round(milliseconds * 10) / 10) + ' ms', x, y, size, color);
}
