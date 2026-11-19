package helix.math;

/** Represents a seeded random number generator that produces the same sequence on every target.

	It is xoshiro128**, its state made from the seed by SplitMix64, as raylib's rprand is, so a seed produces raylib's numbers. It is
	written in 32-bit integer arithmetic, so the interpreter, JS and hxcpp agree bit for bit. A simulation that must replay alike, such
	as a recorded run or a lockstep game, draws from one. A program keeps one generator per stream (play, and a title screen's
	decoration), so that drawing from one doesn't change another's sequence.
	```haxe
	var random = new Random(42);
	var angle = random.nextRange(0, 2 * Math.PI);
	var card = random.pick(deck);
	```

	The points, directions, rotations and bell-shaped numbers it makes agree on every target too, made with `Trig` and arithmetic alone.

	Natively the generated C++ is compiled with `-fwrapv` and `-ffp-contract=off` on GCC and clang. Haxe's Int wraps on overflow, and
	C++'s int doesn't, so without `-fwrapv` a compiler may change the sequence. Without `-ffp-contract=off` fused multiply-adds may
	change a number's rounding. */
@:buildXml("<files id='haxe'><compilerflag value='-fwrapv' unless='windows'/><compilerflag value='-ffp-contract=off' unless='windows'/></files>")
class Random {
	// xoshiro128**'s four words.
	final words = new haxe.ds.Vector<Int>(4);
	// SplitMix64's state while seeding, as its high and low halves: haxe.Int64 doesn't compute alike on every target.
	var mixHigh = 0;
	var mixLow = 0;

	/** Creates a generator.

		@param seed  Optional. The seed, read as unsigned; defaults to 12345. */
	public function new(seed = 12345)
		this.seed = seed;

	/** Gets or sets the seed the sequence last started from.

		Setting it starts the sequence again from that seed. Every seed, 0 among them, produces a sequence of its own. */
	public var seed(default, set):Int;

	function set_seed(value:Int):Int {
		mixHigh = 0;
		mixLow = value;
		for (i in 0...2) {
			mixNext();
			words[i * 2] = mixedLow;
			mixNext();
			words[i * 2 + 1] = mixedHigh;
		}
		return seed = value;
	}

	/** Gets or sets where the sequence is now, as xoshiro128**'s four 32-bit words.

		Reading it and setting it back later continues the sequence from that point, so one generator can serve two streams in turn. The
		words are copied both ways.
		@throws String  When set to anything but four words, or to four zeros, from which the sequence would be zeros alone. */
	public var state(get, set):Array<Int>;

	function get_state():Array<Int>
		return [for (w in words) w];

	function set_state(value:Array<Int>):Array<Int> {
		if (value == null || value.length != 4 || (value[0] | value[1] | value[2] | value[3]) == 0)
			throw "A Random's state is four words, not all zero";
		for (i in 0...4)
			words[i] = value[i];
		return value;
	}

	/** Returns the next 32 bits.

		@return  Any whole number a 32-bit Int holds, read as unsigned where a range is made from it. */
	public function nextBits():Int {
		var s = words;
		var result = rotate(s[1] * 5 | 0, 7) * 9 | 0;
		var t = s[1] << 9;
		s[2] ^= s[0];
		s[3] ^= s[1];
		s[1] ^= s[2];
		s[0] ^= s[3];
		s[2] ^= t;
		s[3] = rotate(s[3], 11);
		return result;
	}

	/** Returns the next whole number.

		@return  A number from 0 to 2147483647: the next 32 bits' top 31. */
	public function next():Int
		return nextBits() >>> 1;

	/** Returns the next whole number below a maximum.

		It is the next 32 bits, unsigned, modulo max, as raylib's `GetRandomValue(0, max - 1)` is. A maximum of 1 or less returns 0, a
		number drawn all the same.
		@param max  The maximum, excluded.
		@return  A number from 0 to max - 1. */
	public function nextInt(max:Int):Int {
		var bits = unsigned(nextBits());
		return max <= 1 ? 0 : Std.int(bits % max);
	}

	/** Returns the next number from 0 up to 1.

		It has 24 bits, exact in a float on every target.
		@return  A number from 0, included, to 1, excluded. */
	public function nextFloat():Float
		return (nextBits() >>> 8) / 16777216;

	/** Returns the next number in a range.

		Bounds provided in the wrong order are swapped.
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

	/** Returns a number from a normal (bell-shaped) distribution.

		@param mean  Optional. The middle of the bell; defaults to 0.
		@param deviation  Optional. The bell's standard deviation; defaults to 1.
		@return  The number. */
	public function nextGaussian(mean = 0., deviation = 1.):Float {
		// Box and Muller's: a radius from one number above 0, an angle from another.
		var radius = Math.sqrt(-2 * log(((nextBits() >>> 8) + 1) / 16777216));
		var angle = TAU * nextFloat();
		return mean + deviation * (radius * Trig.cos(angle));
	}

	/** Returns a point inside a circle around the origin, every place as likely as another.

		@param radius  Optional. The circle's radius; defaults to 1.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point. */
	public function nextInCircle(radius = 1., ?out:Vector2):Vector2 {
		var distance = radius * Math.sqrt(nextFloat());
		var around = Trig.turn(TAU * nextFloat());
		var x = around.cos * distance, y = around.sin * distance;
		return out == null ? new Vector2(x, y) : out.set(x, y);
	}

	/** Returns a point on a circle around the origin: a direction in 2D at radius 1.

		@param radius  Optional. The circle's radius; defaults to 1.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point. */
	public function nextOnCircle(radius = 1., ?out:Vector2):Vector2 {
		var around = Trig.turn(TAU * nextFloat());
		var x = around.cos * radius, y = around.sin * radius;
		return out == null ? new Vector2(x, y) : out.set(x, y);
	}

	/** Returns a point inside a sphere around the origin, every place as likely as another.

		@param radius  Optional. The sphere's radius; defaults to 1.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point. */
	public function nextInSphere(radius = 1., ?out:Vector3):Vector3 {
		// The greatest of three numbers is spread as a cube root is, which a point's distance from the middle must be.
		var distance = nextFloat();
		var second = nextFloat();
		var third = nextFloat();
		if (second > distance)
			distance = second;
		if (third > distance)
			distance = third;
		return nextOnSphere(radius * distance, out);
	}

	/** Returns a point on a sphere around the origin: a direction in 3D at radius 1.

		@param radius  Optional. The sphere's radius; defaults to 1.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point. */
	public function nextOnSphere(radius = 1., ?out:Vector3):Vector3 {
		// A height evenly between the poles, and a place around the ring at that height.
		var height = 2 * nextFloat() - 1;
		var around = Trig.turn(TAU * nextFloat());
		var ring = Math.sqrt(1 - height * height) * radius;
		var x = around.cos * ring, y = around.sin * ring, z = height * radius;
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	/** Returns a direction within an angle of another, every direction in that cone as likely as another.

		@param direction  The cone's middle; it needn't be of length 1.
		@param radians  The most the direction strays from the middle, clamped to 0 to pi.
		@param out  Optional. The vector to fill; a new one when omitted. It may be the middle.
		@return  The direction, of length 1; of length 0 when the middle is. */
	public function nextInCone(direction:Vector3, radians:Float, ?out:Vector3):Vector3 {
		var dx = direction.x, dy = direction.y, dz = direction.z;
		var length = Math.sqrt(dx * dx + dy * dy + dz * dz);
		var across = nextFloat();
		var around = Trig.turn(TAU * nextFloat());
		if (length == 0)
			return out == null ? new Vector3() : out.set(0, 0, 0);
		dx /= length;
		dy /= length;
		dz /= length;
		// Two directions square to the middle and to each other, the first from the axis the middle lies least along.
		var ax = dx < 0 ? -dx : dx,
			ay = dy < 0 ? -dy : dy,
			az = dz < 0 ? -dz : dz;
		var px, py, pz;
		if (az < ax && az < ay) {
			px = dy;
			py = -dx;
			pz = 0.;
		} else if (ay < ax) {
			px = -dz;
			py = 0.;
			pz = dx;
		} else {
			px = 0.;
			py = dz;
			pz = -dy;
		}
		var scale = 1 / Math.sqrt(px * px + py * py + pz * pz);
		px *= scale;
		py *= scale;
		pz *= scale;
		var qx = dy * pz - dz * py,
			qy = dz * px - dx * pz,
			qz = dx * py - dy * px;
		// The cosine of the angle off the middle, evenly from the cone's edge to 1: even over the cone's cap.
		var along = 1 - across * (1 - Trig.cos(radians < 0 ? 0 : radians > Math.PI ? Math.PI : radians));
		var off = Math.sqrt(1 - along * along > 0 ? 1 - along * along : 0);
		var x = dx * along + (px * around.cos + qx * around.sin) * off,
			y = dy * along + (py * around.cos + qy * around.sin) * off,
			z = dz * along + (pz * around.cos + qz * around.sin) * off;
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	/** Returns a rotation, every rotation as likely as another.

		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public function nextRotation(?out:Quaternion):Quaternion {
		// Shoemake's: two points on two circles, whose squared radii add to 1.
		var split = nextFloat();
		var first = Trig.turn(TAU * nextFloat());
		var second = Trig.turn(TAU * nextFloat());
		var inner = Math.sqrt(1 - split), outer = Math.sqrt(split);
		var x = first.sin * inner,
			y = first.cos * inner,
			z = second.sin * outer,
			w = second.cos * outer;
		return out == null ? new Quaternion(x, y, z, w) : out.set(x, y, z, w);
	}

	// A whole turn, in radians.
	static inline var TAU = 6.283185307179586;

	// The natural logarithm of a number above 0 and no more than 1, the same bits on every target, where Math.log's last bit differs:
	// fdlibm's (e_log.c). The number is 2^k times 1 + f, 1 + f from the square root of 1/2 up to the square root of 2.
	static function log(x:Float):Float {
		var k = 0.;
		while (x < 0.70710678118654752440) {
			x *= 2;
			k--;
		}
		var f = x - 1, s = f / (2 + f);
		var z = s * s, w = z * z;
		var even = w * (3.999999999940941908e-01 + w * (2.222219843214978396e-01 + w * 1.531383769920937332e-01));
		var odd = z * (6.666666666666735130e-01 + w * (2.857142874366239149e-01 + w * (1.818357216161805012e-01 + w * 1.479819860511658591e-01)));
		var half = 0.5 * f * f;
		return s * (half + (odd + even)) + k * 1.90821492927058770002e-10 - half + f + k * 6.93147180369123816490e-01;
	}

	// SplitMix64's next 64 bits, into mixedHigh and mixedLow.
	var mixedHigh = 0;
	var mixedLow = 0;

	function mixNext():Void {
		var sum = unsigned(mixLow) + unsigned(0x7f4a7c15);
		mixLow = word(sum);
		mixHigh = word(unsigned(mixHigh) + unsigned(0x9e3779b9) + (sum >= 4294967296.0 ? 1 : 0));
		var high = mixHigh, low = mixLow;
		// z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9
		low ^= (low >>> 30) | (high << 2);
		high ^= high >>> 30;
		multiply64(high, low, 0xbf58476d, 0x1ce4e5b9);
		high = productHigh;
		low = productLow;
		// z = (z ^ (z >> 27)) * 0x94d049bb133111eb
		low ^= (low >>> 27) | (high << 5);
		high ^= high >>> 27;
		multiply64(high, low, 0x94d049bb, 0x133111eb);
		high = productHigh;
		low = productLow;
		// z ^ (z >> 31)
		mixedHigh = high ^ (high >>> 31);
		mixedLow = low ^ ((low >>> 31) | (high << 1));
	}

	// The low 64 bits of a product of two 64-bit numbers, each passed as its halves, into productHigh and productLow.
	static var productHigh = 0;
	static var productLow = 0;

	static function multiply64(aHigh:Int, aLow:Int, bHigh:Int, bLow:Int):Void {
		multiply32(aLow, bLow);
		var high = productHigh, low = productLow;
		multiply32(aHigh, bLow);
		var cross = unsigned(productLow);
		multiply32(aLow, bHigh);
		cross += unsigned(productLow);
		productHigh = word(unsigned(high) + cross);
		productLow = low;
	}

	// The 64-bit product of two unsigned 32-bit numbers, exact in 16-bit parts, into productHigh and productLow.
	static function multiply32(a:Int, b:Int):Void {
		// Each part is made a float by a multiplication by 1.0: Haxe's interpreter multiplies two Ints as Ints, overflowing, even typed Float.
		var a0 = (a & 0xffff) * 1.0,
			a1 = (a >>> 16) * 1.0,
			b0 = (b & 0xffff) * 1.0,
			b1 = (b >>> 16) * 1.0;
		var middle = a0 * b1 + a1 * b0;
		var low = a0 * b0 + (middle % 65536) * 65536;
		var carry = Math.ffloor(low / 4294967296.0);
		productHigh = word(a1 * b1 + Math.ffloor(middle / 65536) + carry);
		productLow = word(low - carry * 4294967296.0);
	}

	// A whole number below 2^53 as its low 32 bits.
	static function word(value:Float):Int {
		var low = value % 4294967296.0;
		return low >= 2147483648.0 ? Std.int(low - 4294967296.0) : Std.int(low);
	}

	static inline function rotate(x:Int, k:Int):Int
		return (x << k) | (x >>> (32 - k));

	static inline function unsigned(value:Int):Float
		return value < 0 ? value + 4294967296.0 : value;
}
