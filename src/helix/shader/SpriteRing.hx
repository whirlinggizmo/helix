package helix.shader;

import helix.graphics.Graphics;
import helix.graphics.SpriteEffect;

/** A sprite effect of the library: a ring drawn across the sprite's quad, its color the sprite's tint: a selection under a unit, a target on
	the ground, a spell's reach, a range. Drawn, not sampled: the sprite's texture only gives the quad (a 1 x 1 white one does), and its size
	is the ring's. In 3D, a Sprite3D lying on the ground (facing Ground) gives a ring on flat ground. Its parts, each a property: the band
	between inner and outer, edges as soft as softness, a fill inside, dashes round it, spinning, and a pulse. Shared by the sprites given it
	(SpriteEffect): each ring of its own look has a SpriteRing of its own. Built on the program's GPU (Graphics) the first time one is made. */
class SpriteRing extends SpriteEffect {
	/** The band's inner edge, a fraction of the quad's half size (0 at its center, 1 at its sides): .8 by default. */
	public var inner(default, set):Float = .8;

	function set_inner(value:Float):Float {
		inner = clamp(value);
		write();
		return inner;
	}

	/** The band's outer edge, the same: .95 by default (a little in from the sides, so a soft edge and a pulse fit). */
	public var outer(default, set):Float = .95;

	function set_outer(value:Float):Float {
		outer = clamp(value);
		write();
		return outer;
	}

	/** How soft its edges are, a fraction of the quad's half size; never under a pixel. .02 by default. */
	public var softness(default, set):Float = .02;

	function set_softness(value:Float):Float {
		softness = clamp(value);
		write();
		return softness;
	}

	/** How much of the tint fills inside the band, 0 (a ring alone, the default) to 1 (a disc): a spell's area. */
	public var fill(default, set):Float = 0;

	function set_fill(value:Float):Float {
		fill = clamp(value);
		write();
		return fill;
	}

	/** Dashes round it, a whole number: 0 (unbroken, the default), or how many: a range, a "can't go here". */
	public var dashes(default, set):Int = 0;

	function set_dashes(value:Int):Int {
		dashes = value > 0 ? value : 0;
		write();
		return dashes;
	}

	/** The gap's share of each dash, 0 to 1: .4 by default. */
	public var gap(default, set):Float = .4;

	function set_gap(value:Float):Float {
		gap = clamp(value);
		write();
		return gap;
	}

	/** How fast the dashes turn, in turns a second (negative, the other way): 0 by default. */
	public var spin(default, set):Float = 0;

	function set_spin(value:Float):Float {
		spin = Math.isFinite(value) ? value : 0;
		write();
		return spin;
	}

	/** How much it grows and shrinks as it pulses, 0 (still, the default) to 1 (by half its size each way): a destination that throbs. */
	public var pulse(default, set):Float = 0;

	function set_pulse(value:Float):Float {
		pulse = clamp(value);
		write();
		return pulse;
	}

	/** Pulses a second: 1 by default. */
	public var pulseRate(default, set):Float = 1;

	function set_pulseRate(value:Float):Float {
		pulseRate = Math.isFinite(value) && value > 0 ? value : 0;
		write();
		return pulseRate;
	}

	/** A thin unbroken ring, still; set its properties for the rest. */
	public function new() {
		super(ShaderLibrary.get(Graphics.instance, "sprite_ring", SpriteRingPacked.text()));
		write();
	}

	static function clamp(value:Float):Float
		return value > 0 ? (value < 1 ? value : 1) : 0;

	function write():Void {
		parameters.setValues("shape", [inner, outer, softness, fill]);
		parameters.setValues("motion", [dashes, gap, spin, pulse]);
		parameters.setValues("pace", [pulseRate, 0, 0, 0]);
	}
}
