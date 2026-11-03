package helix.render.effects;

/** Represents bloom: light past a threshold spread around it, as a bright light glows in a lens or an eye. It works on linear light.

	The light past `threshold`, eased in over a soft knee, is drawn into half the frame's size and down a chain of halving targets
	through a 13-tap filter, each level then added to the one above through a 3 x 3 tent filter, and the result added to the frame times
	`intensity`. In an RGBA8 frame it blooms what the tone mapping left, past the threshold of display colors. */
class BloomEffect extends ScreenEffect {
	/** Gets or sets the brightness past which light blooms, in linear light: 1 until set. Below 0 is clamped to 0. */
	public var threshold(default, set):Float = 1;

	/** Gets or sets how much of the bloom is added: 0.5 until set. Below 0 is clamped to 0. */
	public var intensity(default, set):Float = .5;

	/** Gets or sets how far it spreads, 0 to 1, the levels' blend: 0.5 until set. Clamped to 0 to 1. */
	public var radius(default, set):Float = .5;

	/** Creates bloom at a threshold of 1, an intensity of 0.5 and a radius of 0.5. */
	public function new() {
		super(true);
	}

	function set_threshold(value:Float):Float {
		throw "helix-render: BloomEffect.set_threshold is not yet built (stage 5, post-processing)";
	}

	function set_intensity(value:Float):Float {
		throw "helix-render: BloomEffect.set_intensity is not yet built (stage 5, post-processing)";
	}

	function set_radius(value:Float):Float {
		throw "helix-render: BloomEffect.set_radius is not yet built (stage 5, post-processing)";
	}
}
