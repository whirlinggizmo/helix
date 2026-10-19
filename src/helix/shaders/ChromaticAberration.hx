package helix.shaders;

/** Chromatic aberration, a screen effect of the library: red and blue parted from green, red toward the middle and blue away from it, by
	amount at the frame's edges and less toward its middle, as a cheap lens splits colors. */
class ChromaticAberration extends LibraryScreenEffect {
	/** Colors parted by amount pixels at the edges. */
	public function new(amount = 3.) {
		super("chromatic_aberration", ChromaticAberrationPacked.text());
		this.amount = amount;
	}

	/** How far red and blue part from green at the frame's edges, each its way, in the frame's pixels, 0 (none) to 64: 3 by default. */
	public var amount(default, set):Float;

	function set_amount(value:Float):Float
		return amount = writeFloat("amount", value, 0, 64);
}
