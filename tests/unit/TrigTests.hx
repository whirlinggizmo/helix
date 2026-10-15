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
