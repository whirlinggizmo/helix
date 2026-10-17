package helix.math;

/** Random numbers from a seed, the same sequence on every target: xorshift32 in integer math alone, so the interpreter, JS and hxcpp agree
	bit for bit, as Trig does. A simulation that must replay (an autopilot's seed, a lockstep game) draws from one of these; what only looks
	random (a particle's spin) may too. A game keeps as many as it has streams: play's, and the title's dressing, so when play starts doesn't
	matter (Asteroids keeps the title's state). */
class Random {
	/** A generator starting from seed (12345 unless given); 0 is taken as 1, as xorshift needs a state other than 0. */
	public function new(seed = 12345)
		this.seed = seed;

	/** The seed the sequence last started from; assigning one starts the sequence again from it (0 is taken as 1). */
	public var seed(default, set):Int;

	function set_seed(value:Int):Int {
		seed = value == 0 ? 1 : value;
		state = seed;
		return value;
	}

	/** Where the sequence is now (seed is where it started): read and assigned back later, the sequence goes on from there (0 is taken as
		1), one generator serving two streams in turn. */
	public var state(default, set):Int;

	function set_state(value:Int):Int {
		state = value == 0 ? 1 : value;
		return value;
	}

	// The generator's step: the whole 32-bit state.
	function step():Int {
		state ^= state << 13;
		state ^= state >>> 17;
		state ^= state << 5;
		return state;
	}

	/** The next whole number, from 0 to 2147483647. */
	public function next():Int
		return step() & 0x7fffffff;

	/** The next whole number from 0 up to but not including max: next() % max, so 0 for a max of 1 or less. */
	public function nextInt(max:Int):Int
		return max <= 1 ? (max == 1 ? next() * 0 : 0) : next() % max;

	/** The next number from 0 up to but not including 1, in 24 bits (exact in a float on every target). */
	public function nextFloat():Float
		return (step() >>> 8) / 16777216;

	/** The next number from min up to but not including max (min when they're equal; swapped when max is less). */
	public function nextRange(min:Float, max:Float):Float {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		return min + (max - min) * nextFloat();
	}

	/** True with the chance given, 0 to 1 (a half when not given). */
	public function nextBool(chance = .5):Bool
		return nextFloat() < chance;

	/** One of items, each as likely; null for none. */
	public function pick<T>(items:Array<T>):Null<T>
		return items.length == 0 ? null : items[nextInt(items.length)];

	/** The index of one of weights, each as likely as its weight (a weight of 0 or less never); -1 for none or no weight over 0. */
	public function pickWeighted(weights:Array<Float>):Int {
		var total = 0.;
		for (w in weights)
			if (w > 0)
				total += w;
		if (total <= 0)
			return -1;
		var at = nextFloat() * total;
		for (i in 0...weights.length) {
			if (weights[i] <= 0)
				continue;
			at -= weights[i];
			if (at < 0)
				return i;
		}
		return weights.length - 1;
	}

	/** Shuffles items in place (Fisher and Yates', from the end: each place swapped with one at or before it) and returns them. */
	public function shuffle<T>(items:Array<T>):Array<T> {
		var i = items.length - 1;
		while (i > 0) {
			var j = nextInt(i + 1), t = items[i];
			items[i] = items[j];
			items[j] = t;
			i--;
		}
		return items;
	}
}
