import helix.math.Trig;

/** helix.math.Trig against Math: within a few ulp over many angles, and the special values (zeros, infinities, NaN, the quadrants). Whether it
	gives the same bits on every target is tests/trig's check. */
class TrigTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// Within n ulp of expected, by relative error, or both tiny.
	static function close(actual:Float, expected:Float, n = 4.):Bool
		return actual == expected || Math.abs(actual - expected) <= n * 2.220446049250313e-16 * Math.max(Math.abs(expected), 1e-300);

	// As close, or, near a zero of sin, cos or tan of x, within |x| times 2^-60: where a C runtime's argument reduction loses its relative
	// accuracy (Windows' is off by 51 ulp at sin(9 pi), 3.6e-20 from the true value; Trig and glibc agree with it to the last bit).
	static function closeAt(actual:Float, expected:Float, n:Float, x:Float):Bool
		return close(actual, expected, n) || Math.abs(actual - expected) <= Math.abs(x) * 8.673617379884035e-19;

	static function main():Void {
		var seed = 12345.;
		function next():Float {
			seed = (seed * 16807) % 2147483647;
			return seed / 1073741823.5 - 1;
		}
		var worst = 0;
		for (range in [Math.PI, 100., 10000.]) {
			var ok = true, okTan = true, okAtan = true, okInverse = true;
			for (_ in 0...20000) {
				var x = next() * range, y = next() * range, u = next();
				ok = ok && closeAt(Trig.sin(x), Math.sin(x), 8, x) && closeAt(Trig.cos(x), Math.cos(x), 8, x);
				okTan = okTan && closeAt(Trig.tan(x), Math.tan(x), 16, x);
				okAtan = okAtan && close(Trig.atan2(y, x), Math.atan2(y, x));
				okInverse = okInverse && close(Trig.asin(u), Math.asin(u), 8) && close(Trig.acos(u), Math.acos(u), 8);
			}
			check(ok, 'sin and cos agree with Math within ±$range');
			check(okTan, 'tan agrees with Math within ±$range');
			check(okAtan, 'atan2 agrees with Math within ±$range');
			check(okInverse, "asin and acos agree with Math");
		}
		// Past the three-part reduction (|x| about 1.6 million), up to the largest double, against glibc's sin and cos (Python's math on Linux):
		// a fixed reference, as the C runtime under the interpreter may not be one (Windows' is off by about 2e-15 at 2e6 radians, more beyond).
		// 1e22 and 2^1023 are fdlibm's hard cases; 6381956970095103 * 2^797 is the double nearest a multiple of pi/2 (Kahan and McDonald).
		var large:Array<Array<Float>> = [
			[1700000.0, 0.5711113510481804, -0.8208725995572772],
			[-2500000.0, -0.7795270639555267, -0.6263685469121802],
			[123456789.0, 0.9901147518020355, 0.14025968153390964],
			[-9876543210.0, 0.20091212066709271, -0.9796092689276943],
			[1000000000000.0, -0.6112387023768895, 0.7914463018528902],
			[3141592653589790.0, 0.09671855950742554, -0.9953117703748955],
			[1e+22, -0.8522008497671888, 0.523214785395139],
			[-6.02214076e+23, -0.8814547285026539, 0.47226852700588967],
			[1e+50, -0.4805001434937588, 0.8769946477045781],
			[-1.234e+100, 0.7765463154209097, 0.6300601717345804],
			[1e+200, -0.6439687185395058, 0.7650518214752429],
			[1e+300, -0.8178819121159085, -0.5753861119575491],
			[8.98846567431158e+307, 0.563127779850884, -0.826369834614148],
			[1.7976931348623157e+308, 0.004961954789184062, -0.9999876894265599],
			// cos here is -r, from the exact remainder (pi to 1000 digits, Python's decimal): glibc's is 8 ulp off.
			[5.319372648326541e+255, 1.0, -4.687165924254628e-19]
		];
		for (row in large)
			check(close(Trig.sin(row[0]), row[1], 2) && close(Trig.cos(row[0]), row[2], 2), 'sin and cos of ${row[0]} as glibc\'s');
		// And many more against Math, where the C runtime reduces large angles exactly (not Windows').
		if (Sys.systemName() != "Windows") {
			for (scale in [2e6, 1e9, 1e15, 1e22, 1e100, 1e300, 1.7976931348623157e308]) {
				var ok = true;
				for (_ in 0...2000) {
					var x = next() * scale;
					if (Math.abs(x) < 1.7e6)
						continue;
					ok = ok && close(Trig.sin(x), Math.sin(x), 8) && close(Trig.cos(x), Math.cos(x), 8) && close(Trig.tan(x), Math.tan(x), 16);
				}
				check(ok, 'sin, cos and tan agree with Math up to ±$scale');
			}
		}
		check(1 / Trig.sin(-0.) < 0 && 1 / Trig.tan(-0.) < 0 && 1 / Trig.asin(-0.) < 0, "A zero keeps its sign");
		check(Trig.sin(0) == 0 && Trig.cos(0) == 1 && Trig.sin(Math.PI / 2) == 1 && close(Trig.cos(Math.PI), -1), "The quadrants' exact values");
		check(Math.isNaN(Trig.sin(Math.POSITIVE_INFINITY))
			&& Math.isNaN(Trig.cos(Math.NaN))
			&& Math.isNaN(Trig.tan(Math.NEGATIVE_INFINITY)),
			"NaN for infinite or NaN angles");
		check(Math.isNaN(Trig.asin(1.5)) && Math.isNaN(Trig.acos(-1.0000001)) && Trig.asin(1) == Math.PI / 2 && close(Trig.acos(-1), Math.PI),
			"asin and acos at and past the ends");
		check(Trig.atan2(0, -1) == Math.PI && Trig.atan2(-0., -1) == -Math.PI && Trig.atan2(1, 0) == Math.PI / 2 && Trig.atan2(-1, 0) == -Math.PI / 2,
			"atan2 on the axes, -0 included");
		check(Trig.atan2(0, -0.) == Math.PI && 1 / Trig.atan2(-0., 1) < 0 && Math.isNaN(Trig.atan2(Math.NaN, 1)), "atan2 of zeros and NaN");
		check(Trig.atan2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY) == Math.atan2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY),
			"atan2 of infinities as Math's");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
