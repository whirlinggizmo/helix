package helix.shader;

import helix.graphics.ScreenFrame;
import helix.texture.Texture2D;

/** Bloom, a screen effect of the library: light past a threshold spread around it, as a bright light glows in a lens or an eye. It wants HDR
	(ScreenEffect.hdr), so in a chain with it the scene is drawn in half floats where the GPU can, and the light running past 1 is what blooms;
	it decodes the frame to linear light first. The light past threshold (eased in over a soft knee) is drawn into half the frame's size
	through a 13-tap filter (each group of four weighted by its brightness, so a lone bright texel doesn't flicker), on down a chain of LEVELS
	halving sizes; each level is then added to the one above it drawn larger through a 3 x 3 tent filter, back to half the frame's size,
	and that is added to the frame times intensity. Where the GPU draws no half floats (or after a Tonemap of the chain's own), the frame
	reaching it is tone mapped, 8-bit, and toneMappedThreshold takes threshold's place. Its intermediates are the chain's levels: LEVELS
	going down, then LEVELS - 1 coming back up (ScreenEffect.intermediates). */
class Bloom extends LibraryScreenEffect {
	/** The levels of its chain going down: half the frame's size, a quarter, and so on to a 64th. */
	public static inline var LEVELS = 6;

	/** A bloom of light past 1 (in linear light), its knee half the threshold, added at intensity 1. */
	public function new() {
		super("bloom", BloomPacked.text());
		hdr = true;
		var down = [for (i in 0...LEVELS) Math.pow(.5, i + 1)];
		intermediates = down.concat(down.slice(0, LEVELS - 1));
		threshold = 1;
		knee = .5;
		toneMappedThreshold = .8;
		intensity = 1;
	}

	/** Where the bloom starts in an HDR frame: light (linear, past the exposure) whose brightest channel passes it blooms, the more the further
		past. 0 to 64, 1 by default: light brighter than the screen's white. */
	public var threshold(default, set):Float;

	function set_threshold(value:Float):Float
		return threshold = value > 0 ? (value < 64 ? value : 64) : 0;

	/** How softly light past the threshold comes in: the width of the knee either side of it, a share of the threshold, 0 (a hard cut) to 1;
		.5 by default. */
	public var knee(default, set):Float;

	function set_knee(value:Float):Float
		return knee = value > 0 ? (value < 1 ? value : 1) : 0;

	/** Where the bloom starts in a frame already tone mapped (8-bit, where the GPU draws no half floats), in linear light 0 to 1: .8 by
		default, the brightest of what's there. */
	public var toneMappedThreshold(default, set):Float;

	function set_toneMappedThreshold(value:Float):Float
		return toneMappedThreshold = value > 0 ? (value < 1 ? value : 1) : 0;

	/** How much of the bloom is added to the frame, 0 (none) to 16: 1 by default. At 1 the light past the threshold is added again, spread. */
	public var intensity(default, set):Float;

	function set_intensity(value:Float):Float {
		intensity = value > 0 ? (value < 16 ? value : 16) : 0;
		// The levels are summed coming up, so their average is what's added.
		parameters.setFloat("intensity", intensity / LEVELS);
		return intensity;
	}

	/** Draws the chain: the light past the threshold into the first level, down the levels, and back up them. */
	override public function drawIntermediates(frame:ScreenFrame):Void {
		var levels = frame.intermediates;
		var at = frame.source.format == Rgba16f ? threshold : toneMappedThreshold;
		parameters.setFloat("threshold", at);
		parameters.setFloat("knee", at * knee);
		var from = frame.source;
		for (i in 0...LEVELS) {
			step(i == 0 ? 0 : 1, from, from);
			drawInto(levels[i], from, frame.time);
			from = levels[i];
		}
		// Up: each level coming up is the level going down at its size plus the one below drawn larger.
		var i = LEVELS - 2;
		while (i >= 0) {
			var into = levels[LEVELS + i];
			step(2, from, levels[i]);
			drawInto(into, from, frame.time);
			from = into;
			i--;
		}
	}

	/** Adds the bloom to the frame, over the open pass's viewport. */
	override public function draw(frame:ScreenFrame):Void {
		step(3, frame.source, frame.intermediates[LEVELS]);
		drawPass(frame.source, frame.width, frame.height, frame.time);
	}

	// A step of the chain: its mode, the texture it reads as the frame (from, whose texel it steps by) and the one it adds (added).
	function step(mode:Int, from:Texture2D, added:Texture2D):Void {
		parameters.setFloat("mode", mode);
		parameters.setValues("texel", [1 / from.width, 1 / from.height]);
		parameters.setTexture("bloom_texture", added);
	}
}
