import helix.math.Interpolate;

/** Checks Interpolate's easing curves with the library alone: each of the thirty at 0 and 1, each family's ease-in the mirror of its
	ease-out, each ease-in-out halfway at the middle and (but for back's and elastic's) made of the two halves, the curves that don't overshoot rising steadily, and
	cubic's ease-in-out as raylib's reasings computes it. */
class InterpolateTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function main():Void {
		var families:Array<{name:String, overshoots:Bool, ease:Array<Float->Float>}> = [
			{name: "sine", overshoots: false, ease: [Interpolate.easeInSine, Interpolate.easeOutSine, Interpolate.easeInOutSine]},
			{name: "quad", overshoots: false, ease: [Interpolate.easeInQuad, Interpolate.easeOutQuad, Interpolate.easeInOutQuad]},
			{name: "cubic", overshoots: false, ease: [Interpolate.easeInCubic, Interpolate.easeOutCubic, Interpolate.easeInOutCubic]},
			{name: "quart", overshoots: false, ease: [Interpolate.easeInQuart, Interpolate.easeOutQuart, Interpolate.easeInOutQuart]},
			{name: "quint", overshoots: false, ease: [Interpolate.easeInQuint, Interpolate.easeOutQuint, Interpolate.easeInOutQuint]},
			{name: "expo", overshoots: false, ease: [Interpolate.easeInExpo, Interpolate.easeOutExpo, Interpolate.easeInOutExpo]},
			{name: "circ", overshoots: false, ease: [Interpolate.easeInCirc, Interpolate.easeOutCirc, Interpolate.easeInOutCirc]},
			{name: "back", overshoots: true, ease: [Interpolate.easeInBack, Interpolate.easeOutBack, Interpolate.easeInOutBack]},
			{name: "elastic", overshoots: true, ease: [Interpolate.easeInElastic, Interpolate.easeOutElastic, Interpolate.easeInOutElastic]},
			{name: "bounce", overshoots: false, ease: [Interpolate.easeInBounce, Interpolate.easeOutBounce, Interpolate.easeInOutBounce]}
		];
		for (f in families) {
			var easeIn = f.ease[0], easeOut = f.ease[1], easeInOut = f.ease[2];
			for (ease in f.ease)
				check(Math.abs(ease(0)) < 1e-3 && Math.abs(ease(1) - 1) < 1e-3, '${f.name}: 0 at 0 and 1 at 1');
			var mirrored = true, halves = true, rising = true;
			for (i in 1...20) {
				var t = i / 20;
				mirrored = mirrored && near(easeIn(t), 1 - easeOut(1 - t));
				// Back's and elastic's ease-in-out have constants of their own (Penner's), so aren't made of their halves.
				if (!f.overshoots)
					halves = halves && near(easeInOut(t), t < .5 ? easeIn(2 * t) / 2 : (1 + easeOut(2 * t - 1)) / 2);
				if (!f.overshoots && f.name != "bounce")
					rising = rising && easeIn(t) >= easeIn(t - .05) && easeOut(t) >= easeOut(t - .05) && easeInOut(t) >= easeInOut(t - .05);
			}
			check(mirrored, '${f.name}: ease-in is ease-out turned about');
			check(halves && near(easeInOut(.5), .5), '${f.name}: ease-in-out is ease-in then ease-out, halfway at the middle');
			check(rising, '${f.name}: rising steadily');
		}
		check(Interpolate.easeOutBack(.5) > 1 - 1e-9 || Interpolate.easeInBack(.2) < 0, "back pulls back past 0");
		// raylib's EaseCubicInOut(t, b, c, d), at 0 to 1 over 10 steps.
		var same = true;
		for (i in 0...11) {
			var t = i / 5.;
			var raylib = t < 1 ? t * t * t / 2 : ((t - 2) * (t - 2) * (t - 2) + 2) / 2;
			same = same && near(Interpolate.easeInOutCubic(i / 10), raylib);
		}
		check(same, "cubic's ease-in-out is raylib's");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
