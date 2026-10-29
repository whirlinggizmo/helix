package helix.math;

/** Provides interpolation: between numbers and angles, clamping, smoothing, stepping and easing toward a target.

	`damp` and `dampAngle` use `Math.exp`, whose last bit can differ between targets, so a simulation that must replay alike on every
	target uses `moveToward` or its own integer math instead. Angles are in radians. */
class Interpolate {
	/** Returns the value a fraction of the way from one number to another.

		A fraction outside 0 to 1 goes past the ends.
		@param a  The value at 0.
		@param b  The value at 1.
		@param t  The fraction.
		@return  a + (b - a) * t. */
	public static inline function lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * t;

	/** Returns how far a value lies from one number to another, as a fraction.

		@param a  The value at 0.
		@param b  The value at 1.
		@param value  The value.
		@return  The fraction: 0 at a, 1 at b, past them beyond; 0 when a and b are equal. */
	public static function inverseLerp(a:Float, b:Float, value:Float):Float
		return b == a ? 0 : (value - a) / (b - a);

	/** Returns a value moved from one range to another, at the same fraction of the way along.

		@param value  The value.
		@param fromA  The first range's start.
		@param fromB  The first range's end.
		@param toA  The second range's start.
		@param toB  The second range's end.
		@return  The value in the second range. */
	public static function remap(value:Float, fromA:Float, fromB:Float, toA:Float, toB:Float):Float
		return lerp(toA, toB, inverseLerp(fromA, fromB, value));

	/** Returns a value clamped to a range.

		Bounds given in the wrong order are swapped.
		@param value  The value.
		@param min  The lower bound.
		@param max  The upper bound.
		@return  The value, or the bound it's past. */
	public static function clamp(value:Float, min:Float, max:Float):Float {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		return value < min ? min : value > max ? max : value;
	}

	/** Returns a fraction clamped to 0 to 1 and smoothed, slow at both ends.

		@param t  The fraction.
		@return  3t² - 2t³ of the clamped fraction. */
	public static function smoothStep(t:Float):Float {
		t = t < 0 ? 0 : t > 1 ? 1 : t;
		return t * t * (3 - 2 * t);
	}

	/** Returns an angle wrapped to -π up to π.

		@param angle  The angle, in radians.
		@return  The same direction, from -π, included, to π, excluded. */
	public static function wrapAngle(angle:Float):Float {
		var a = angle % (2 * Math.PI);
		if (a >= Math.PI)
			a -= 2 * Math.PI;
		else if (a < -Math.PI)
			a += 2 * Math.PI;
		return a;
	}

	/** Returns the angle a fraction of the way from one angle to another, the short way round.

		@param a  The angle at 0, in radians.
		@param b  The angle at 1, in radians.
		@param t  The fraction.
		@return  The angle, in radians, not wrapped. */
	public static function lerpAngle(a:Float, b:Float, t:Float):Float
		return a + wrapAngle(b - a) * t;

	/** Returns a value moved toward a target by at most a step.

		It reaches the target exactly. A step of 0 or less leaves the value unchanged.
		@param value  The value.
		@param target  The target.
		@param step  The most it moves.
		@return  The moved value. */
	public static function moveToward(value:Float, target:Float, step:Float):Float {
		if (!(step > 0))
			return value;
		var d = target - value;
		return d > step ? value + step : d < -step ? value - step : target;
	}

	/** Returns a value eased toward a target over a time step, the same at any frame rate.

		Each step closes 1 - e^(-rate * dt) of the gap, so the value approaches the target without reaching it exactly. A rate or time
		step of 0 or less leaves the value unchanged.
		@param value  The value.
		@param target  The target.
		@param rate  How fast it closes the gap, per second.
		@param dt  The time step, in seconds.
		@return  The eased value. */
	public static function damp(value:Float, target:Float, rate:Float, dt:Float):Float
		return !(rate > 0) || !(dt > 0) ? value : value + (target - value) * (1 - Math.exp(-rate * dt));

	/** Returns an angle eased toward a target angle over a time step, the short way round, as `damp` does.

		@param value  The angle, in radians.
		@param target  The target angle, in radians.
		@param rate  How fast it closes the gap, per second.
		@param dt  The time step, in seconds.
		@return  The eased angle, in radians, not wrapped. */
	public static function dampAngle(value:Float, target:Float, rate:Float, dt:Float):Float
		return !(rate > 0) || !(dt > 0) ? value : value + wrapAngle(target - value) * (1 - Math.exp(-rate * dt));
}
