import helix.math.Ease;
import helix.math.Interpolate;

/** Checks Interpolate's easing curves with the library alone: each of the thirty at 0 and 1, each family's ease-in the mirror of its
	ease-out, each ease-in-out halfway at the middle and (but for back's and elastic's) made of the two halves, the curves that don't overshoot rising steadily, and
	cubic's ease-in-out as raylib's reasings computes it; each spline piece at its ends and middle; a Hermite curve; and each of Ease's curves against its function, its straight line, a curve of a function
	of the test's own, and a curve held in a static. */
class InterpolateTests {
	static var checks = 0;

	// A curve held in a static, set as the program starts.
	static final held = Ease.outBounce;

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

		check(near(Interpolate.catmullRom(0, 1, 2, 3, 0), 1)
			&& near(Interpolate.catmullRom(0, 1, 2, 3, 1), 2)
			&& near(Interpolate.catmullRom(0, 1, 2, 3, .5), 1.5),
			"Catmull-Rom: through the middle two, evenly on a line");
		check(near(Interpolate.bSpline(0, 6, 12, 18, 0), 6) && near(Interpolate.bSpline(0, 0, 6, 0, 0), 1),
			"B-spline: on a line through its points; near, not through, a peak");
		check(near(Interpolate.quadraticBezier(0, 10, 0, 0), 0)
			&& near(Interpolate.quadraticBezier(0, 10, 0, .5), 5)
			&& near(Interpolate.quadraticBezier(0, 10, 4, 1), 4),
			"quadratic Bezier: its ends, halfway to the control point");
		check(near(Interpolate.cubicBezier(0, 10, 10, 0, .5), 7.5) && near(Interpolate.cubicBezier(1, 5, 7, 2, 1), 2), "cubic Bezier");
		check(Interpolate.hermite(2, 5, 7, -3, 0) == 2 && Interpolate.hermite(2, 5, 7, -3, 1) == 7, "Hermite: its ends");
		check(near(Interpolate.hermite(0, 8, 4, 0, .5), 3)
			&& near(Interpolate.hermite(0, 0, 4, 8, .5), 1)
			&& near(Interpolate.hermite(0, 0, 4, 0, .5), 2),
			"Hermite halfway: half of each end, an eighth of the first slope, less an eighth of the second");
		check(near(Interpolate.hermite(0, 1, 1, 1, .3), .3), "Hermite: a straight line when both slopes are the line's");
		var curves:Array<{ease:Ease, curve:Float->Float}> = [
			{ease: Ease.inSine, curve: Interpolate.easeInSine},
			{ease: Ease.outSine, curve: Interpolate.easeOutSine},
			{ease: Ease.inOutSine, curve: Interpolate.easeInOutSine},
			{ease: Ease.inQuad, curve: Interpolate.easeInQuad},
			{ease: Ease.outQuad, curve: Interpolate.easeOutQuad},
			{ease: Ease.inOutQuad, curve: Interpolate.easeInOutQuad},
			{ease: Ease.inCubic, curve: Interpolate.easeInCubic},
			{ease: Ease.outCubic, curve: Interpolate.easeOutCubic},
			{ease: Ease.inOutCubic, curve: Interpolate.easeInOutCubic},
			{ease: Ease.inQuart, curve: Interpolate.easeInQuart},
			{ease: Ease.outQuart, curve: Interpolate.easeOutQuart},
			{ease: Ease.inOutQuart, curve: Interpolate.easeInOutQuart},
			{ease: Ease.inQuint, curve: Interpolate.easeInQuint},
			{ease: Ease.outQuint, curve: Interpolate.easeOutQuint},
			{ease: Ease.inOutQuint, curve: Interpolate.easeInOutQuint},
			{ease: Ease.inExpo, curve: Interpolate.easeInExpo},
			{ease: Ease.outExpo, curve: Interpolate.easeOutExpo},
			{ease: Ease.inOutExpo, curve: Interpolate.easeInOutExpo},
			{ease: Ease.inCirc, curve: Interpolate.easeInCirc},
			{ease: Ease.outCirc, curve: Interpolate.easeOutCirc},
			{ease: Ease.inOutCirc, curve: Interpolate.easeInOutCirc},
			{ease: Ease.inBack, curve: Interpolate.easeInBack},
			{ease: Ease.outBack, curve: Interpolate.easeOutBack},
			{ease: Ease.inOutBack, curve: Interpolate.easeInOutBack},
			{ease: Ease.inElastic, curve: Interpolate.easeInElastic},
			{ease: Ease.outElastic, curve: Interpolate.easeOutElastic},
			{ease: Ease.inOutElastic, curve: Interpolate.easeInOutElastic},
			{ease: Ease.inBounce, curve: Interpolate.easeInBounce},
			{ease: Ease.outBounce, curve: Interpolate.easeOutBounce},
			{ease: Ease.inOutBounce, curve: Interpolate.easeInOutBounce}
		];
		var same = true;
		for (c in curves)
			for (i in 0...21)
				same = same && c.ease.at(i / 20) == c.curve(i / 20);
		check(same, "Ease: each of the thirty curves is its function");
		check(Ease.linear.at(0) == 0 && Ease.linear.at(.3) == .3 && Ease.linear.at(1) == 1, "Ease: linear is a straight line");
		check(Ease.of(t -> t * t).at(.5) == .25, "Ease: a curve of a function of the program's own");
		check(held.at(.4) == Interpolate.easeOutBounce(.4), "Ease: a curve held in a static");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
