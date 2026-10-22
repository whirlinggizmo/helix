package helix.shader;

import helix.graphics.ScreenFrame;

/** Blur, a screen effect of the library: the frame blurred, a Gaussian over radius pixels either way, in two passes (across, into a texture
	at resolution of the frame's size, then down, from it drawn larger). Its one intermediate is that texture (ScreenEffect.intermediates). */
class Blur extends LibraryScreenEffect {
	/** A blur of radius pixels (the frame's) drawn at resolution of the frame's size. */
	public function new(radius = 8., resolution = .5) {
		super("blur", BlurPacked.text());
		this.radius = radius;
		this.resolution = resolution;
	}

	/** How far it reaches either way, in the frame's pixels, 0 (none) to 128: 8 by default. Its standard deviation is a third of it. */
	public var radius(default, set):Float;

	function set_radius(value:Float):Float
		return radius = value > 0 ? (value < 128 ? value : 128) : 0;

	/** The size of its first pass's texture, a fraction of the frame's each way, 1/16 to 1: .5 by default. Smaller is cheaper and, for a
		wide radius, no worse. */
	public var resolution(default, set):Float;

	function set_resolution(value:Float):Float {
		resolution = value > 1 / 16 ? (value < 1 ? value : 1) : 1 / 16;
		intermediates = [resolution];
		return resolution;
	}

	/** Draws the pass across, from the frame into its texture. */
	override public function drawIntermediates(frame:ScreenFrame):Void {
		parameters.setValues("spacing", [radius / 8 / frame.width, 0]);
		drawInto(frame.intermediates[0], frame.source, frame.time);
	}

	/** Draws the pass down, from its texture over the open pass's viewport. */
	override public function draw(frame:ScreenFrame):Void {
		parameters.setValues("spacing", [0, radius / 8 / frame.height]);
		drawPass(frame.intermediates[0], frame.width, frame.height, frame.time);
	}
}
