import helix.math.Matrix4;
import helix.math.Trig;
import helix.math.Vector2;

/** Checks `-D helix-math-standard-trig` with the library alone: each of Trig's functions returns `Math`'s answer, bit for bit, and
	helix-math's rotations use `Math`'s cosines and sines too. */
class StandardTrigTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// Whether two results are the same number, a NaN the same as a NaN.
	static function same(a:Float, b:Float):Bool
		return a == b || Math.isNaN(a) && Math.isNaN(b);

	static function main():Void {
		#if !helix_math_standard_trig
		#error "StandardTrigTests is built with -D helix-math-standard-trig"
		#end
		var angles = [0, .1, -.7, 1, 2.5, -4, 100.25, 1e6, 1e22, Math.POSITIVE_INFINITY, Math.NaN];
		for (a in angles) {
			check(same(Trig.sin(a), Math.sin(a)), 'sin($a) is Math\'s');
			check(same(Trig.cos(a), Math.cos(a)), 'cos($a) is Math\'s');
			check(same(Trig.tan(a), Math.tan(a)), 'tan($a) is Math\'s');
			var both = Trig.cosSin(a);
			check(same(both.x, Math.cos(a)) && same(both.y, Math.sin(a)), 'cosSin($a) is Math\'s cosine and sine');
		}
		for (v in [0, .25, -.5, .75, -.99, 1, -1, 1.5, Math.NaN]) {
			check(same(Trig.asin(v), Math.asin(v)), 'asin($v) is Math\'s');
			check(same(Trig.acos(v), Math.acos(v)), 'acos($v) is Math\'s');
		}
		for (p in [
			[1., 1.],
			[-2., .5],
			[0., -1.],
			[3., -4.],
			[0., 0.],
			[Math.POSITIVE_INFINITY, 1.]
		])
			check(same(Trig.atan2(p[0], p[1]), Math.atan2(p[0], p[1])), 'atan2(${p[0]}, ${p[1]}) is Math\'s');
		// The rotations, whose cosines and sines are Math's as well.
		var turned = new Vector2(1, 0).rotate(.6);
		check(turned.x == Math.cos(.6) && turned.y == Math.sin(.6), "Vector2.rotate takes Math's cosine and sine");
		var m = Matrix4.fromEuler(0, 0, .6);
		check(m.m0 == Math.cos(.6) && m.m1 == Math.sin(.6), "Matrix4.fromEuler takes Math's cosine and sine");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
