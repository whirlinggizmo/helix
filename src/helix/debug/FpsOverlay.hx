package helix.debug;

import helix.render2d.Drawing2D;

/** The frame rate and the frame's cost, averaged over half a second, as a node (docs/DISPLAY_MODEL.md): put it on the stage where it should
	show (its top-left at its position, in the stage's units), and update it each frame; it draws its line again when the numbers change. */
class FpsOverlay extends Drawing2D {
	var rate = 0.;
	var milliseconds = 0.;
	var frames = 0;
	var time = 0.;
	var cost = 0.;
	var shownText = "";

	/** An overlay showing 0 until half a second of frames has been seen, size tall (16 unless given) in color (0xAARRGGBB, a light green
		unless given). */
	public function new(size = 16., color = 0xff7fe07f) {
		super();
		this.size = size;
		this.color = color;
		pickable = false;
		show();
	}

	/** The glyph height, in the stage's units. */
	public var size:Float;

	/** Its color, 0xAARRGGBB. */
	public var color:Int;

	/** Frames a second over the last half second. */
	public var frameRate(get, never):Float;

	function get_frameRate():Float
		return rate;

	/** The frame's average cost in milliseconds over the last half second. */
	public var frameMs(get, never):Float;

	function get_frameMs():Float
		return milliseconds;

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
		show();
	}

	// The line drawn again when it reads differently.
	function show():Void {
		var text = Std.int(rate + .5) + ' FPS  ' + (Math.round(milliseconds * 10) / 10) + ' ms';
		if (text == shownText && callCount > 0)
			return;
		shownText = text;
		clear();
		drawText(text, 0, 0, size, color);
	}
}
