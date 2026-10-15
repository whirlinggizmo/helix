package helix.math;

/** Trigonometry that gives the same bits on every target, for simulations that must play alike in the browser and natively (an autopilot's
	replay, lockstep, physics). `Math`'s functions don't: V8's and the C library's differ in the last bit for a few percent of angles (`atan2`
	for about a fifth), and a simulation turns that into a different world. These are built from arithmetic alone (and `Math.sqrt` and
	`Math.floor`, exact everywhere), each step its own statement, and within a few ulp of `Math`'s. Drawing doesn't need them. Radians; NaN
	for an infinite or NaN angle, and for `asin` and `acos` past -1..1, as `Math`'s.

	Natively the generated C++ is compiled with `-ffp-contract=off` (GCC, MinGW and clang): a compiler that fuses a multiply and an add (GCC
	does on arm64, clang by default) would round differently from a target that can't. MSVC's default, /fp:precise, doesn't fuse them. */
@:buildXml('<files id="haxe"><compilerflag value="-ffp-contract=off" unless="windows"/><compilerflag value="-ffp-contract=off" if="mingw"/></files>')
class Trig {
	static inline var PI = 3.14159265358979323846;

	// pi/2 in three parts (fdlibm's): k times each is exact for |k| < 2^20, so the reduction is exact well past any angle a game turns through.
	static inline var PIO2_1 = 1.57079632673412561417e+00;
	static inline var PIO2_2 = 6.07710050630396597660e-11;
	static inline var PIO2_3 = 2.02226624879595063154e-21;

	static var sine = 0.;
	static var cosine = 0.;

	/** The sine of x. */
	public static function sin(x:Float):Float {
		if (!Math.isFinite(x))
			return Math.NaN;
		if (x == 0)
			return x; // a zero keeps its sign, as Math's
		sinCos(x);
		return sine;
	}

	/** The cosine of x. */
	public static function cos(x:Float):Float {
		if (!Math.isFinite(x))
			return Math.NaN;
		sinCos(x);
		return cosine;
	}

	/** The tangent of x. */
	public static function tan(x:Float):Float {
		if (!Math.isFinite(x))
			return Math.NaN;
		if (x == 0)
			return x; // a zero keeps its sign, as Math's
		sinCos(x);
		return sine / cosine;
	}

	/** The angle of (x, y) from the +x axis, -pi..pi, as `Math.atan2(y, x)`. */
	public static function atan2(y:Float, x:Float):Float {
		if (Math.isNaN(y) || Math.isNaN(x))
			return Math.NaN;
		if (x == 0 && y == 0)
			return negative(x) ? (negative(y) ? -PI : PI) : y;
		if (!Math.isFinite(y) || !Math.isFinite(x))
			return Math.atan2(y, x); // the infinities' fixed angles, the same everywhere
		if (x > 0)
			return atanOf(y / x);
		if (x < 0) {
			var a = atanOf(y / x);
			return negative(y) ? a - PI : a + PI;
		}
		return y > 0 ? PI / 2 : -PI / 2;
	}

	/** The angle whose sine is x, -pi/2..pi/2. */
	public static function asin(x:Float):Float {
		if (!(x >= -1 && x <= 1))
			return Math.NaN;
		if (x == 1 || x == -1)
			return x * PI / 2;
		var root = Math.sqrt((1 - x) * (1 + x));
		return atanOf(x / root);
	}

	/** The angle whose cosine is x, 0..pi. */
	public static function acos(x:Float):Float {
		if (!(x >= -1 && x <= 1))
			return Math.NaN;
		if (x == 0)
			return PI / 2;
		var root = Math.sqrt((1 - x) * (1 + x));
		var a = atanOf(root / x);
		return x > 0 ? a : a + PI;
	}

	// Whether x is negative, -0 included (1 / -0 is -infinity).
	static inline function negative(x:Float):Bool
		return x < 0 || x == 0 && 1 / x < 0;

	// sine and cosine of x: x = k * pi/2 + r with |r| <= pi/4, then a Taylor polynomial each whose next term is below a double's precision.
	static function sinCos(x:Float):Void {
		var k = Math.ffloor(x * 0.63661977236758134308 + 0.5);
		var quadrant = k - 4 * Math.ffloor(k * 0.25);
		var r = x - k * PIO2_1;
		r = r - k * PIO2_2;
		r = r - k * PIO2_3;
		var s = sinReduced(r), c = cosReduced(r);
		switch (Std.int(quadrant)) {
			case 0:
				sine = s;
				cosine = c;
			case 1:
				sine = c;
				cosine = -s;
			case 2:
				sine = -s;
				cosine = -c;
			default:
				sine = -c;
				cosine = s;
		}
	}

	static function sinReduced(r:Float):Float {
		var r2 = r * r;
		var p = 2.8114572543455206e-15; // 1/17!
		p = p * r2;
		p = p - 7.6471637318198164e-13; // -1/15!
		p = p * r2;
		p = p + 1.6059043836821613e-10; // 1/13!
		p = p * r2;
		p = p - 2.5052108385441720e-08; // -1/11!
		p = p * r2;
		p = p + 2.7557319223985893e-06; // 1/9!
		p = p * r2;
		p = p - 1.9841269841269841e-04; // -1/7!
		p = p * r2;
		p = p + 8.3333333333333333e-03; // 1/5!
		p = p * r2;
		p = p - 1.6666666666666667e-01; // -1/3!
		p = p * r2;
		p = p * r;
		return r + p;
	}

	static function cosReduced(r:Float):Float {
		var r2 = r * r;
		var p = -1.5619206968586225e-16; // -1/18!
		p = p * r2;
		p = p + 4.7794773323873853e-14; // 1/16!
		p = p * r2;
		p = p - 1.1470745597729725e-11; // -1/14!
		p = p * r2;
		p = p + 2.0876756987868099e-09; // 1/12!
		p = p * r2;
		p = p - 2.7557319223985888e-07; // -1/10!
		p = p * r2;
		p = p + 2.4801587301587302e-05; // 1/8!
		p = p * r2;
		p = p - 1.3888888888888889e-03; // -1/6!
		p = p * r2;
		p = p + 4.1666666666666667e-02; // 1/4!
		p = p * r2;
		p = p - 0.5;
		p = p * r2;
		return 1 + p;
	}

	// atan of |x| <= tan(pi/8): x - x^3/3 + x^5/5 - ..., to x^43 (the next term below 1e-18).
	static function atanReduced(x:Float):Float {
		var x2 = x * x;
		var p = 0.;
		var n = 43;
		while (n >= 3) {
			p = p * x2;
			p = p + (Std.int((n - 1) / 2) % 2 == 0 ? 1 : -1) / n;
			n -= 2;
		}
		p = p * x2;
		p = p * x;
		return x + p;
	}

	// atan of any finite x: reduced by atan(x) = pi/4 + atan((x - 1) / (x + 1)) and atan(x) = pi/2 - atan(1 / x).
	static function atanOf(x:Float):Float {
		if (x == 0)
			return x; // keeps a zero's sign: -0 + 0 would be +0
		var t = x < 0 ? -x : x;
		var a:Float;
		if (t <= 0.41421356237309504880)
			a = atanReduced(t);
		else if (t <= 2.41421356237309504880)
			a = PI / 4 + atanReduced((t - 1) / (t + 1));
		else
			a = PI / 2 - atanReduced(1 / t);
		return x < 0 ? -a : a;
	}
}
