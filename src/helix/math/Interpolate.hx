package helix.math;

/** Interpolation and the small math every game writes again: between two numbers, back to a fraction, clamped, smoothed, the short way round
	between angles, moved by at most a step, or eased toward a target at a rate that's the same at any frame rate. For drawing and feel: a
	replayed simulation keeps to integer math or Trig, as Math.exp differs by a bit between targets. */
class Interpolate {
	/** From a to b by t: a at 0, b at 1, past them past 0 and 1. */
	public static inline function lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * t;

	/** Where value lies from a to b, as t: 0 at a, 1 at b; 0 when a and b are the same. */
	public static function inverseLerp(a:Float, b:Float, value:Float):Float
		return b == a ? 0 : (value - a) / (b - a);

	/** value's place from fromA to fromB, taken to the same place from toA to toB. */
	public static function remap(value:Float, fromA:Float, fromB:Float, toA:Float, toB:Float):Float
		return lerp(toA, toB, inverseLerp(fromA, fromB, value));

	/** value held between min and max (swapped when max is less). */
	public static function clamp(value:Float, min:Float, max:Float):Float {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		return value < min ? min : value > max ? max : value;
	}

	/** t held between 0 and 1, then smoothed: slow at both ends (3t² - 2t³). */
	public static function smoothStep(t:Float):Float {
		t = t < 0 ? 0 : t > 1 ? 1 : t;
		return t * t * (3 - 2 * t);
	}

	/** angle in radians brought to -π up to π. */
	public static function wrapAngle(angle:Float):Float {
		var a = angle % (2 * Math.PI);
		if (a >= Math.PI)
			a -= 2 * Math.PI;
		else if (a < -Math.PI)
			a += 2 * Math.PI;
		return a;
	}

	/** From angle a to b in radians by t, the short way round. */
	public static function lerpAngle(a:Float, b:Float, t:Float):Float
		return a + wrapAngle(b - a) * t;

	/** value moved toward target by at most step (a step of 0 or less moves nothing), reaching it exactly. */
	public static function moveToward(value:Float, target:Float, step:Float):Float {
		if (!(step > 0))
			return value;
		var d = target - value;
		return d > step ? value + step : d < -step ? value - step : target;
	}

	/** value eased toward target over dt seconds at rate (the share closed each second, as 1 - e^(-rate dt)): the same approach at any frame
		rate, never arriving exactly, which moveToward does. A rate of 0 or less leaves value. */
	public static function damp(value:Float, target:Float, rate:Float, dt:Float):Float
		return !(rate > 0) || !(dt > 0) ? value : value + (target - value) * (1 - Math.exp(-rate * dt));

	/** As damp, between angles in radians the short way round. */
	public static function dampAngle(value:Float, target:Float, rate:Float, dt:Float):Float
		return !(rate > 0) || !(dt > 0) ? value : value + wrapAngle(target - value) * (1 - Math.exp(-rate * dt));
}
