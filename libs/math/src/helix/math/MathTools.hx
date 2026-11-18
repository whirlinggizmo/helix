package helix.math;

/** Provides what Haxe's `Math` lacks for a number: clamping, wrapping, snapping, comparing, the least, greatest and size of whole numbers,
	powers of two, and degrees and radians.

	Each function takes the number first, so a file with `using helix.math.MathTools;` calls each on the number. `clamp`, `wrap` and `snap`
	give an `Int` for `Int`s and a `Float` for any other numbers.

	```haxe
	using helix.math.MathTools;

	var volume = level.clamp(0, 1);
	var column = index.clamp(0, 7); // an Int, as index is
	var facing = velocity.x.sign(); // -1, 0 or 1
	var radians = degrees.toRadians();
	``` */
class MathTools {
	/** Returns a whole number clamped to a range.

		Bounds given in the wrong order are swapped.
		@param value  The number.
		@param min  The lower bound.
		@param max  The upper bound.
		@return  The number, or the bound the number is past. */
	public static extern inline overload function clamp(value:Int, min:Int, max:Int):Int {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		return value < min ? min : value > max ? max : value;
	}

	/** Returns a value clamped to a range.

		Bounds given in the wrong order are swapped.
		@param value  The value.
		@param min  The lower bound.
		@param max  The upper bound.
		@return  The value, or the bound the value is past. */
	public static extern inline overload function clamp(value:Float, min:Float, max:Float):Float {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		return value < min ? min : value > max ? max : value;
	}

	/** Returns a value clamped to 0 to 1.

		@param value  The value.
		@return  The value, 0 below 0, or 1 above 1. */
	public static inline function clamp01(value:Float):Float
		return value < 0 ? 0 : value > 1 ? 1 : value;

	/** Returns a whole number wrapped around into a range, as a column wraps around a row.

		Bounds given in the wrong order are swapped. A range of no size gives `min`.
		@param value  The number.
		@param min  The range's start.
		@param max  The range's end.
		@return  The number, from min up to max, max excluded. */
	public static extern inline overload function wrap(value:Int, min:Int, max:Int):Int {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		var size = max - min;
		var over = size == 0 ? 0 : (value - min) % size;
		return min + (over < 0 ? over + size : over);
	}

	/** Returns a value wrapped around into a range, as an angle wraps around a turn.

		Bounds given in the wrong order are swapped. A range of no size gives `min`.
		@param value  The value.
		@param min  The range's start.
		@param max  The range's end.
		@return  The value, from min up to max. */
	public static extern inline overload function wrap(value:Float, min:Float, max:Float):Float {
		if (max < min) {
			var t = min;
			min = max;
			max = t;
		}
		var size = max - min;
		return size == 0 ? min : value - size * Math.ffloor((value - min) / size);
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

	/** Returns a whole number moved to the nearest multiple of a step, as a place snaps to a grid of tiles.

		A number halfway between two multiples moves to the greater.
		@param value  The number.
		@param step  The step. 0 or less leaves the number as it is.
		@return  The snapped number. */
	public static extern inline overload function snap(value:Int, step:Int):Int {
		var over = step > 0 ? value % step : 0;
		if (over < 0)
			over += step;
		return over * 2 >= step ? value - over + step : value - over;
	}

	/** Returns a value moved to the nearest multiple of a step, as a slider snaps to its marks.

		A value halfway between two multiples moves to the greater.
		@param value  The value.
		@param step  The step. 0 or less leaves the value as it is.
		@return  The snapped value. */
	public static extern inline overload function snap(value:Float, step:Float):Float
		return step > 0 ? Math.ffloor(value / step + .5) * step : value;

	/** Returns a value bounced back and forth between 0 and a length, as a ball between two walls.

		@param value  The value, of any size.
		@param length  The far wall. 0 or less gives 0.
		@return  The bounced value, 0 to length. */
	public static function pingPong(value:Float, length:Float):Float {
		if (!(length > 0))
			return 0;
		var along = value - 2 * length * Math.ffloor(value / (2 * length));
		return along > length ? 2 * length - along : along;
	}

	/** Returns a value's sign.

		@param value  The value.
		@return  1 above 0, -1 below 0, and 0 at 0 and for NaN. */
	public static inline function sign(value:Float):Int
		return value > 0 ? 1 : value < 0 ? -1 : 0;

	/** Returns whether two values are equal but for rounding.

		@param a  One value.
		@param b  The other value.
		@param tolerance  The most the values may differ by, multiplied by the larger value's size when that size is over 1.
		@return  True when the values are that close. */
	public static inline function equals(a:Float, b:Float, tolerance:Float):Bool {
		var sizeA = Math.abs(a), sizeB = Math.abs(b);
		var size = sizeA > sizeB ? sizeA : sizeB;
		return Math.abs(a - b) <= (size > 1 ? tolerance * size : tolerance);
	}

	/** Returns the lesser of two whole numbers, as an `Int`. `Math.min` gives a `Float`.

		@param a  One number.
		@param b  The other number.
		@return  The lesser. */
	public static inline function min(a:Int, b:Int):Int
		return a < b ? a : b;

	/** Returns the greater of two whole numbers, as an `Int`. `Math.max` gives a `Float`.

		@param a  One number.
		@param b  The other number.
		@return  The greater. */
	public static inline function max(a:Int, b:Int):Int
		return a > b ? a : b;

	/** Returns a whole number's size, as an `Int`. `Math.abs` gives a `Float`.

		@param value  The number.
		@return  The number without its sign. */
	public static inline function abs(value:Int):Int
		return value < 0 ? -value : value;

	/** Returns whether a whole number is a power of two: 1, 2, 4, 8 and on.

		@param value  The number.
		@return  True for a power of two. False for 0 and for a number below 0. */
	public static inline function isPowerOfTwo(value:Int):Bool
		return value > 0 && (value & (value - 1)) == 0;

	/** Returns the least power of two that isn't below a whole number, as a texture's side is rounded up.

		@param value  The number.
		@return  The power of two: the number itself when the number is one, 1 for a number below 1, and 1,073,741,824 at most. */
	public static function nextPowerOfTwo(value:Int):Int {
		var power = 1;
		while (power < value && power < 0x40000000)
			power <<= 1;
		return power;
	}

	/** Returns an angle in degrees as radians.

		@param degrees  The angle, in degrees.
		@return  The angle, in radians. */
	public static inline function toRadians(degrees:Float):Float
		return degrees * (Math.PI / 180);

	/** Returns an angle in radians as degrees.

		@param radians  The angle, in radians.
		@return  The angle, in degrees. */
	public static inline function toDegrees(radians:Float):Float
		return radians * (180 / Math.PI);
}
