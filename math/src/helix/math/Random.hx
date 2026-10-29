package helix.math;

/** Represents a seeded random number generator that gives the same sequence on every target.

	It is xorshift32 in integer arithmetic, so the interpreter, JS and hxcpp agree bit for bit. A simulation that must replay alike, such
	as a recorded run or a lockstep game, draws from one. A program keeps one generator per stream (play, and a title screen's
	decoration), so that drawing from one doesn't change another's sequence.
	```haxe
	var random = new Random(42);
	var angle = random.nextRange(0, 2 * Math.PI);
	var card = random.pick(deck);
	```
 */
class Random {
	/** Creates a generator.

		@param seed  Optional. The seed; defaults to 12345. A seed of 0 is taken as 1. */
	public function new(seed = 12345)
		this.seed = seed;

	/** Gets or sets the seed the sequence last started from.

		Setting it starts the sequence again from that seed. A seed of 0 is taken as 1. */
	public var seed(default, set):Int;

	function set_seed(value:Int):Int {
		seed = value == 0 ? 1 : value;
		state = seed;
		return value;
	}

	/** Gets or sets where the sequence is now.

		Reading it and setting it back later continues the sequence from that point, so one generator can serve two streams in turn. A state
		of 0 is taken as 1. */
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

	/** Returns the next whole number.

		@return  A number from 0 to 2147483647. */
	public function next():Int
		return step() & 0x7fffffff;

	/** Returns the next whole number below a maximum.

		A maximum of 1 or less returns 0.
		@param max  The maximum, excluded.
		@return  A number from 0 to max - 1. */
	public function nextInt(max:Int):Int
		return max <= 1 ? (max == 1 ? next() * 0 : 0) : next() % max;

	/** Returns the next number from 0 up to 1.

		It has 24 bits, exact in a float on every target.
		@return  A number from 0, included, to 1, excluded. */
	public function nextFloat():Float
		return (step() >>> 8) / 16777216;

	/** Returns the next number in a range.

		Bounds given in the wrong order are swapped.
		@param min  The lower bound, included.
		@param max  The upper bound, excluded.
		@return  A number from min up to max, or min when they're equal. */
	public function nextRange(min:Float, max:Float):Float {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		return min + (max - min) * nextFloat();
	}

	/** Returns true with a chance.

		@param chance  Optional. The chance, from 0 to 1; defaults to 0.5.
		@return  True with that chance. */
	public function nextBool(chance = .5):Bool
		return nextFloat() < chance;

	/** Returns one of the items, each equally likely.

		@param items  The items.
		@return  An item, or null if there are none. */
	public function pick<T>(items:Array<T>):Null<T>
		return items.length == 0 ? null : items[nextInt(items.length)];

	/** Returns the index of one of the weights, each as likely as its weight.

		A weight of 0 or less is never picked.
		@param weights  The weights.
		@return  The index, or -1 if no weight is over 0. */
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

	/** Shuffles items in place, every order equally likely.

		@param items  The items.
		@return  The same array, shuffled. */
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
