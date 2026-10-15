package helix.math;

import haxe.io.FPHelper;

/** Trigonometry that gives the same bits on every target, for simulations that must play alike in the browser and natively (an autopilot's
	replay, lockstep, physics). `Math`'s functions don't: V8's and the C library's differ in the last bit for a few percent of angles (`atan2`
	for about a fifth), and a simulation turns that into a different world. These are built from arithmetic alone (and `Math.sqrt` and
	`Math.floor`, exact everywhere), each step its own statement, and within a few ulp of `Math`'s. Drawing doesn't need them. Radians; NaN
	for an infinite or NaN angle, and for `asin` and `acos` past -1..1, as `Math`'s. Any finite angle is reduced exactly: a game's angle that
	keeps growing (an unwrapped spin, a time used as a phase) stays within a few ulp of `Math`'s however large it gets.

	Natively the generated C++ is compiled with `-ffp-contract=off` (GCC and clang): a compiler that fuses a multiply and an add (GCC
	does on arm64, clang by default) would round differently from a target that can't. MSVC's default, /fp:precise, doesn't fuse them. */
@:buildXml('<files id="haxe"><compilerflag value="-ffp-contract=off" unless="windows"/></files>')
class Trig {
	static inline var PI = 3.14159265358979323846;

	// pi/2 in three parts (fdlibm's): k times each is exact for |k| <= 2^20 (about 1.6 million radians); past that, reduceLarge.
	static inline var PIO2_1 = 1.57079632673412561417e+00;
	static inline var PIO2_2 = 6.07710050630396597660e-11;
	static inline var PIO2_3 = 2.02226624879595063154e-21;

	// The largest k reduced by the three parts.
	static inline var MAX_K = 1048576.;

	static inline var TWO24 = 16777216.;
	static inline var TWON24 = 5.9604644775390625e-08;

	// 2/pi's first 1584 bits, 24 a time (fdlibm's two_over_pi): enough to reduce any double exactly.
	static final TWO_OVER_PI:Array<Int> = [
		0xA2F983, 0x6E4E44, 0x1529FC, 0x2757D1, 0xF534DD, 0xC0DB62, 0x95993C, 0x439041, 0xFE5163, 0xABDEBB, 0xC561B7, 0x246E3A, 0x424DD2, 0xE00649, 0x2EEA09,
		0xD1921C, 0xFE1DEB, 0x1CB129, 0xA73EE8, 0x8235F5, 0x2EBB44, 0x84E99C, 0x7026B4, 0x5F7E41, 0x3991D6, 0x398353, 0x39F49C, 0x845F8B, 0xBDF928, 0x3B1FF8,
		0x97FFDE, 0x05980F, 0xEF2F11, 0x8B5A0A, 0x6D1F6D, 0x367ECF, 0x27CB09, 0xB74F46, 0x3F669E, 0x5FEA2D, 0x7527BA, 0xC7EBE5, 0xF17B3D, 0x0739F7, 0x8A5292,
		0xEA6BFB, 0x5FB11F, 0x8D5D08, 0x560330, 0x46FC7B, 0x6BABF0, 0xCFBC20, 0x9AF436, 0x1DA9E3, 0x91615E, 0xE61B08, 0x659985, 0x5F14A0, 0x68408D, 0xFFD880,
		0x4D7327, 0x310606, 0x1556CA, 0x73A8C9, 0x60E27B, 0xC08C6B
	];

	// pi/2 in 24-bit parts (fdlibm's PIo2), from their bits: high words, the low words being 0x40000000, 0, 0x80000000, 0x60000000, 0x80000000.
	static final PIO2_PARTS:Array<Float> = [
		FPHelper.i64ToDouble(0x40000000, 0x3FF921FB),
		FPHelper.i64ToDouble(0, 0x3E74442D),
		FPHelper.i64ToDouble(0x80000000, 0x3CF84698),
		FPHelper.i64ToDouble(0x60000000, 0x3B78CC51),
		FPHelper.i64ToDouble(0x80000000, 0x39F01B83)
	];

	// reduceLarge's working space, kept so a reduction allocates nothing. What goes into the Float arrays must be a Float: the interpreter keeps
	// an Int stored in an Array<Float> an Int, and two of them multiply in 32 bits. Truncations are Math.ffloor (their values aren't negative).
	static final tx:Array<Float> = [0., 0., 0.];
	static final f:Array<Float> = [for (_ in 0...20) 0.];
	static final q:Array<Float> = [for (_ in 0...20) 0.];
	static final fq:Array<Float> = [for (_ in 0...20) 0.];
	static final iq:Array<Int> = [for (_ in 0...20) 0];

	// reduceLarge's remainder.
	static var largeR = 0.;

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
		var quadrant:Int, r:Float;
		if (Math.abs(k) <= MAX_K) {
			quadrant = Std.int(k - 4 * Math.ffloor(k * 0.25));
			r = x - k * PIO2_1;
			r = r - k * PIO2_2;
			r = r - k * PIO2_3;
		} else {
			quadrant = reduceLarge(x);
			r = largeR;
		}
		var s = sinReduced(r), c = cosReduced(r);
		switch (quadrant) {
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

	// 2^e, from its bits, for e within a double's normal exponents.
	static inline function pow2(e:Int):Float
		return FPHelper.i64ToDouble(0, (e + 1023) << 20);

	// x = n * pi/2 + r for a large |x|, by Payne and Hanek's method as fdlibm has it (__ieee754_rem_pio2's last case and __kernel_rem_pio2
	// at double precision): x in three 24-bit parts times 2/pi's bits, 24 a time, only those that reach the fraction. Returns n mod 4, and r
	// in largeR. The products of 24-bit parts are exact, so every target gets the same bits.
	static function reduceLarge(x:Float):Int {
		var bits = FPHelper.doubleToI64(x);
		var hx = bits.high;
		var ix = hx & 0x7fffffff;
		// |x| scaled to 2^23..2^24, and its exponent beyond that.
		var e0 = (ix >> 20) - 1046;
		var z = FPHelper.i64ToDouble(bits.low, ix - (e0 << 20));
		for (i in 0...2) {
			tx[i] = Math.ffloor(z);
			z = z - tx[i];
			z = z * TWO24;
		}
		tx[2] = z;
		var nx = 3;
		while (nx > 0 && tx[nx - 1] == 0)
			nx--;
		var n = remPio2(e0, nx);
		if (hx < 0) {
			largeR = -largeR;
			n = -n;
		}
		return n & 3;
	}

	// The sum of tx[0..nx-1] times the bits of 2/pi it needs, shifted by e0, into q[0..i].
	static function product(i:Int, jx:Int):Void {
		var fw = 0.;
		for (j in 0...jx + 1) {
			var p = tx[j] * f[jx + i - j];
			fw = fw + p;
		}
		q[i] = fw;
	}

	// fdlibm's __kernel_rem_pio2 at double precision (prec 2; jk = jp = 4): returns n mod 8 and the remainder in largeR.
	static function remPio2(e0:Int, nx:Int):Int {
		var jk = 4, jp = 4;
		var jx = nx - 1;
		var jv = Std.int((e0 - 3) / 24);
		if (jv < 0)
			jv = 0;
		var q0 = e0 - 24 * (jv + 1);
		var j = jv - jx, m = jx + jk;
		for (i in 0...20)
			f[i] = 0;
		for (i in 0...m + 1) {
			f[i] = j < 0 ? 0. : TWO_OVER_PI[j] * 1.;
			j++;
		}
		for (i in 0...jk + 1)
			product(i, jx);
		var jz = jk, n = 0, ih = 0, z = 0.;
		while (true) {
			// q[] into 24-bit integers iq[], lowest first.
			var i = 0;
			j = jz;
			z = q[jz];
			while (j > 0) {
				var fw = Math.ffloor(TWON24 * z);
				iq[i] = Std.int(z - TWO24 * fw);
				z = q[j - 1] + fw;
				i++;
				j--;
			}
			for (k in jz...20)
				iq[k] = 0;
			// n, the integer part mod 8.
			z = z * pow2(q0);
			z = z - 8 * Math.ffloor(z * 0.125);
			n = Std.int(z);
			z = z - n;
			ih = 0;
			if (q0 > 0) {
				i = iq[jz - 1] >> (24 - q0);
				n += i;
				iq[jz - 1] -= i << (24 - q0);
				ih = iq[jz - 1] >> (23 - q0);
			} else if (q0 == 0)
				ih = iq[jz - 1] >> 23;
			else if (z >= 0.5)
				ih = 2;
			// Past one half: n + 1, and the fraction becomes 1 - q.
			if (ih > 0) {
				n += 1;
				var carry = 0;
				for (k in 0...jz) {
					j = iq[k];
					if (carry == 0) {
						if (j != 0) {
							carry = 1;
							iq[k] = 0x1000000 - j;
						}
					} else
						iq[k] = 0xffffff - j;
				}
				if (q0 == 1)
					iq[jz - 1] &= 0x7fffff;
				else if (q0 == 2)
					iq[jz - 1] &= 0x3fffff;
				if (ih == 2) {
					z = 1 - z;
					if (carry != 0)
						z = z - pow2(q0);
				}
			}
			// A fraction that cancelled to zero needs more of 2/pi's bits.
			if (z == 0) {
				j = 0;
				var k = jz - 1;
				while (k >= jk) {
					j |= iq[k];
					k--;
				}
				if (j == 0) {
					var more = 1;
					while (iq[jk - more] == 0)
						more++;
					for (k in jz + 1...jz + more + 1) {
						f[jx + k] = TWO_OVER_PI[jv + k] * 1.;
						product(k, jx);
					}
					jz += more;
					continue;
				}
			}
			break;
		}
		// The fraction's 24-bit parts, zeros chopped off.
		if (z == 0) {
			jz -= 1;
			q0 -= 24;
			while (iq[jz] == 0) {
				jz--;
				q0 -= 24;
			}
		} else {
			z = z * pow2(-q0);
			if (z >= TWO24) {
				var fw = Math.ffloor(TWON24 * z);
				iq[jz] = Std.int(z - TWO24 * fw);
				jz += 1;
				q0 += 24;
				iq[jz] = Std.int(fw);
			} else
				iq[jz] = Std.int(z);
		}
		// As doubles, then times pi/2's parts.
		var fw = pow2(q0);
		var i = jz;
		while (i >= 0) {
			q[i] = fw * (iq[i] * 1.);
			fw = fw * TWON24;
			i--;
		}
		i = jz;
		while (i >= 0) {
			fw = 0.;
			var k = 0;
			while (k <= jp && k <= jz - i) {
				var p = PIO2_PARTS[k] * q[i + k];
				fw = fw + p;
				k++;
			}
			fq[jz - i] = fw;
			i--;
		}
		fw = 0.;
		i = jz;
		while (i >= 0) {
			fw = fw + fq[i];
			i--;
		}
		largeR = ih == 0 ? fw : -fw;
		return n & 7;
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
