package helix.tween;

/** Easing functions: from progress t, 0 to 1, to how far along a tween is, 0 to 1 (past them for back and elastic). Robert Penner's set,
	each in its three forms: in (starting slow), out (ending slow), inOut (both). linear is as it is. */
class Ease {
	/** As it is. */
	public static function linear(t:Float):Float
		return t;

	/** Quadratic, in. */
	public static function quadIn(t:Float):Float
		return t * t;

	/** Quadratic, out. */
	public static function quadOut(t:Float):Float
		return t * (2 - t);

	/** Quadratic, in then out. */
	public static function quadInOut(t:Float):Float
		return t < .5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

	/** Cubic, in. */
	public static function cubicIn(t:Float):Float
		return t * t * t;

	/** Cubic, out. */
	public static function cubicOut(t:Float):Float {
		var u = t - 1;
		return u * u * u + 1;
	}

	/** Cubic, in then out. */
	public static function cubicInOut(t:Float):Float
		return t < .5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1;

	/** Quartic, in. */
	public static function quartIn(t:Float):Float
		return t * t * t * t;

	/** Quartic, out. */
	public static function quartOut(t:Float):Float {
		var u = t - 1;
		return 1 - u * u * u * u;
	}

	/** Quartic, in then out. */
	public static function quartInOut(t:Float):Float {
		if (t < .5)
			return 8 * t * t * t * t;
		var u = t - 1;
		return 1 - 8 * u * u * u * u;
	}

	/** Sine, in. */
	public static function sineIn(t:Float):Float
		return 1 - Math.cos(t * Math.PI / 2);

	/** Sine, out. */
	public static function sineOut(t:Float):Float
		return Math.sin(t * Math.PI / 2);

	/** Sine, in then out. */
	public static function sineInOut(t:Float):Float
		return (1 - Math.cos(Math.PI * t)) / 2;

	/** Exponential, in. */
	public static function expoIn(t:Float):Float
		return t <= 0 ? 0 : Math.pow(2, 10 * (t - 1));

	/** Exponential, out. */
	public static function expoOut(t:Float):Float
		return t >= 1 ? 1 : 1 - Math.pow(2, -10 * t);

	/** Exponential, in then out. */
	public static function expoInOut(t:Float):Float {
		if (t <= 0)
			return 0;
		if (t >= 1)
			return 1;
		return t < .5 ? Math.pow(2, 20 * t - 10) / 2 : (2 - Math.pow(2, -20 * t + 10)) / 2;
	}

	/** Circular, in. */
	public static function circIn(t:Float):Float
		return 1 - Math.sqrt(1 - t * t);

	/** Circular, out. */
	public static function circOut(t:Float):Float {
		var u = t - 1;
		return Math.sqrt(1 - u * u);
	}

	/** Circular, in then out. */
	public static function circInOut(t:Float):Float {
		if (t < .5)
			return (1 - Math.sqrt(1 - 4 * t * t)) / 2;
		var u = 2 * t - 2;
		return (Math.sqrt(1 - u * u) + 1) / 2;
	}

	/** Back, in: pulls back under 0 before going. */
	public static function backIn(t:Float):Float
		return t * t * (2.70158 * t - 1.70158);

	/** Back, out: overshoots past 1 before settling. */
	public static function backOut(t:Float):Float {
		var u = t - 1;
		return 1 + u * u * (2.70158 * u + 1.70158);
	}

	/** Back, in then out. */
	public static function backInOut(t:Float):Float {
		var s = 1.70158 * 1.525;
		if (t < .5) {
			var u = 2 * t;
			return u * u * ((s + 1) * u - s) / 2;
		}
		var u = 2 * t - 2;
		return (u * u * ((s + 1) * u + s) + 2) / 2;
	}

	/** Elastic, in: springs past 0 before going. */
	public static function elasticIn(t:Float):Float {
		if (t <= 0)
			return 0;
		if (t >= 1)
			return 1;
		return -Math.pow(2, 10 * t - 10) * Math.sin((t * 10 - 10.75) * 2 * Math.PI / 3);
	}

	/** Elastic, out: springs past 1 before settling. */
	public static function elasticOut(t:Float):Float {
		if (t <= 0)
			return 0;
		if (t >= 1)
			return 1;
		return Math.pow(2, -10 * t) * Math.sin((t * 10 - .75) * 2 * Math.PI / 3) + 1;
	}

	/** Elastic, in then out. */
	public static function elasticInOut(t:Float):Float {
		if (t <= 0)
			return 0;
		if (t >= 1)
			return 1;
		var c = 2 * Math.PI / 4.5;
		return t < .5 ? -Math.pow(2, 20 * t - 10) * Math.sin((20 * t - 11.125) * c) / 2 : Math.pow(2, -20 * t + 10) * Math.sin((20 * t - 11.125) * c) / 2 + 1;
	}

	/** Bounce, out: lands and bounces to rest. */
	public static function bounceOut(t:Float):Float {
		var n = 7.5625, d = 2.75;
		if (t < 1 / d)
			return n * t * t;
		if (t < 2 / d) {
			t -= 1.5 / d;
			return n * t * t + .75;
		}
		if (t < 2.5 / d) {
			t -= 2.25 / d;
			return n * t * t + .9375;
		}
		t -= 2.625 / d;
		return n * t * t + .984375;
	}

	/** Bounce, in. */
	public static function bounceIn(t:Float):Float
		return 1 - bounceOut(1 - t);

	/** Bounce, in then out. */
	public static function bounceInOut(t:Float):Float
		return t < .5 ? (1 - bounceOut(1 - 2 * t)) / 2 : (1 + bounceOut(2 * t - 1)) / 2;
}
