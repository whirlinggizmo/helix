package helix.math;

import haxe.io.FPHelper;

/** Provides trigonometry that gives the same bits on every target.

	A simulation that must play alike on every target (a recorded run's replay, a lockstep game, physics) uses these in place
	of `Math`'s, whose last bit differs between targets for some angles. Drawing doesn't need them. Results are within a few ulp of
	`Math`'s. Angles are in radians, of any size: an angle that keeps growing stays as accurate however large it gets. An infinite or NaN
	angle gives NaN, as do `asin` and `acos` outside -1 to 1.

	Natively the generated C++ is compiled with `-ffp-contract=off` on GCC and clang, so that fused multiply-adds don't change the
	rounding. */
@:buildXml("<files id='haxe'><compilerflag value='-ffp-contract=off' unless='windows'/></files>")
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

	// Adding this and taking it away rounds a number below 2^51 to the nearest whole number (1.5 * 2^52: a double that size holds no
	// fraction), with no call.
	static inline var ROUND = 6755399441055744.;

	// remainderLarge's quarter turns mod 4.
	static var largeQuadrant = 0.;

	/** Returns the sine of an angle.

		@param x  The angle, in radians.
		@return  The sine. */
	public static function sin(x:Float):Float {
		if (x == 0)
			return x; // a zero keeps its sign, as Math's
		var k = quarterTurns(x), r = remainder(x, k), quadrant = quadrant(k);
		return quadrant == 0 ? sinReduced(r) : quadrant == 1 ? cosReduced(r) : quadrant == 2 ? -sinReduced(r) : -cosReduced(r);
	}

	/** Returns the cosine of an angle.

		@param x  The angle, in radians.
		@return  The cosine. */
	public static function cos(x:Float):Float {
		var k = quarterTurns(x), r = remainder(x, k), quadrant = quadrant(k);
		return quadrant == 0 ? cosReduced(r) : quadrant == 1 ? -sinReduced(r) : quadrant == 2 ? -cosReduced(r) : sinReduced(r);
	}

	/** Returns the tangent of an angle.

		@param x  The angle, in radians.
		@return  The tangent. */
	public static function tan(x:Float):Float {
		if (x == 0)
			return x; // a zero keeps its sign, as Math's
		var k = quarterTurns(x), r = remainder(x, k), quadrant = quadrant(k);
		var s = sinReduced(r), c = cosReduced(r);
		return quadrant == 0 ? s / c : quadrant == 1 ? c / -s : quadrant == 2 ? -s / -c : -c / s;
	}

	/** Returns the cosine and the sine of an angle together, each as `cos` and `sin` give it, for less than the two calls cost.

		@param x  The angle, in radians.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The cosine in x and the sine in y: the point at the angle on a circle of radius 1. */
	public static function cosSin(x:Float, ?out:Vector2):Vector2 {
		if (out == null)
			out = new Vector2();
		if (x == 0)
			return out.set(1, x); // a zero keeps its sign, as sin's
		var k = quarterTurns(x), r = remainder(x, k), quadrant = quadrant(k);
		var s = sinReduced(r), c = cosReduced(r);
		return quadrant == 0 ? out.set(c, s) : quadrant == 1 ? out.set(-s, c) : quadrant == 2 ? out.set(-c, -s) : out.set(s, -c);
	}

	/** Returns the angle of a point from the +x axis, as `Math.atan2` does.

		@param y  The point's y coordinate.
		@param x  The point's x coordinate.
		@return  The angle, in radians, from -π to π. */
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

	/** Returns the angle whose sine is a value.

		@param x  The sine, from -1 to 1.
		@return  The angle, in radians, from -π/2 to π/2, or NaN if x is outside -1 to 1. */
	public static function asin(x:Float):Float {
		if (!(x >= -1 && x <= 1))
			return Math.NaN;
		if (x == 1 || x == -1)
			return x * PI / 2;
		var root = Math.sqrt((1 - x) * (1 + x));
		return atanOf(x / root);
	}

	/** Returns the angle whose cosine is a value.

		@param x  The cosine, from -1 to 1.
		@return  The angle, in radians, from 0 to π, or NaN if x is outside -1 to 1. */
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

	// An angle x is k quarter turns and a remainder r, |r| <= pi/4: x = k * pi/2 + r. sin, cos and tan are sinReduced's and cosReduced's
	// of r, by k mod 4. These three are inline and keep nothing, so an angle within MAX_K quarter turns is reduced without a call.
	// k: the whole number nearest x / (pi/2). Past MAX_K, or NaN, for an x that remainderLarge reduces.
	static inline function quarterTurns(x:Float):Float
		return (x * 0.63661977236758134308 + ROUND) - ROUND;

	// r, for x and its k.
	static inline function remainder(x:Float, k:Float):Float
		return Math.abs(k) <= MAX_K ? ((x - k * PIO2_1) - k * PIO2_2) - k * PIO2_3 : remainderLarge(x);

	// k mod 4, read after remainder. It is k less 4 times the whole part of k / 4, whose fraction is 0, 1/4, 1/2 or 3/4: 3/8 less rounds to
	// the whole part.
	static inline function quadrant(k:Float):Float
		return Math.abs(k) <= MAX_K ? k - 4 * (((k * 0.25 - 0.375) + ROUND) - ROUND) : largeQuadrant;

	// r for an x past MAX_K quarter turns, its quarter turns mod 4 left in largeQuadrant. An infinite or NaN x gives NaN, which the
	// polynomials pass on.
	static function remainderLarge(x:Float):Float {
		if (!Math.isFinite(x)) {
			largeQuadrant = 0;
			return Math.NaN;
		}
		largeQuadrant = reduceLarge(x);
		return largeR;
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

	// The sine of |r| <= pi/4: fdlibm's polynomial (__kernel_sin), r + r^3 (S1 + S2 r^2 + ... + S6 r^10), within 2^-58 of the sine.
	static function sinReduced(r:Float):Float {
		var z = r * r, w = z * z;
		var p = 8.33333333332248946124e-03
			+ z * (-1.98412698298579493134e-04 + z * 2.75573137070700676789e-06)
			+ z * w * (-2.50507602534068634195e-08 + z * 1.58969099521155010221e-10);
		return r + z * r * (-1.66666666666666324348e-01 + z * p);
	}

	// The cosine of |r| <= pi/4: fdlibm's polynomial (__kernel_cos), 1 - r^2 / 2 + C1 r^4 + ... + C6 r^14, within 2^-58 of the cosine.
	static function cosReduced(r:Float):Float {
		var z = r * r, w = z * z;
		var p = z * (4.16666666666666019037e-02 + z * (-1.38888888888741095749e-03 + z * 2.48015872894767294178e-05))
			+ w * w * (-2.75573143513906633035e-07 + z * (2.08757232129817482790e-09 + z * -1.13596475577881948265e-11));
		// 1 - z / 2 rounded, and what the rounding dropped added back with the small terms.
		var half = 0.5 * z, c = 1 - half;
		return c + (((1 - c) - half) + z * p);
	}

	// atan of |x| <= tan(pi/8): fdlibm's polynomial (atan's, for |x| < 7/16), x - x^3 (T0 + T1 x^2 + ... + T10 x^20), its even and odd
	// terms summed apart.
	static function atanReduced(x:Float):Float {
		var z = x * x, w = z * z;
		var even = z * (3.33333333333329318027e-01
			+ w * (1.42857142725034663711e-01
				+ w * (9.09088713343650656196e-02 + w * (6.66107313738753120669e-02 + w * (4.97687799461593236017e-02 + w * 1.62858201153657823623e-02)))));
		var odd = w * (-1.99999999998764832476e-01
			+ w * (-1.11111104054623557880e-01 + w * (-7.69187620504482999495e-02 + w * (-5.83357013379057348645e-02 + w * -3.65315727442169155270e-02))));
		return x - x * (even + odd);
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
