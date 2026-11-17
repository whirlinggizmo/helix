package helix.math;

/** Represents a vector in 2 dimensions: a position or a direction, as its user means it.

	Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and
	leaves this one unchanged; given this vector, it changes it in place (`v.normalize(v)`). The out may be this vector or any other
	argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`).
	`set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `cross`, `distance`) is a method, a number
	of one (`length`, `angle`) a property.

	It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, and `Trig` for angles,
	so a vector comes out the same everywhere. Angles are radians, turning from +x toward +y. Its space is its user's.

	```haxe
	var velocity = Vector2.fromAngle(heading, speed);
	position.addScaled(velocity, dt, position);
	var toward = target.subtract(position).normalize();
	``` */
@:structInit
class Vector2 {
	/** Gets or sets the x coordinate. */
	public var x:Float;

	/** Gets or sets the y coordinate. */
	public var y:Float;

	/** Creates a vector.

		@param x  Optional. The x coordinate; defaults to 0.
		@param y  Optional. The y coordinate; defaults to 0. */
	public function new(x = 0., y = 0.) {
		this.x = real(x);
		this.y = real(y);
	}

	/** Returns the vector of an angle and a length.

		@param radians  The angle from +x toward +y.
		@param length  Optional. The length; defaults to 1.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	public static function fromAngle(radians:Float, length = 1., ?out:Vector2):Vector2 {
		var unit = Trig.cosSin(radians, out);
		return unit.set(unit.x * length, unit.y * length);
	}

	/** Returns the vector a fraction of the way from one vector to another.

		A fraction outside 0 to 1 goes past the ends.
		@param from  The vector at 0.
		@param to  The vector at 1.
		@param amount  The fraction.
		@param out  Optional. The vector to fill; a new one when omitted. It may be from or to.
		@return  The vector. */
	public static function lerp(from:Vector2, to:Vector2, amount:Float, ?out:Vector2):Vector2 {
		var fromX = real(from.x), fromY = real(from.y);
		return result(out, fromX + (to.x - fromX) * amount, fromY + (to.y - fromY) * amount);
	}

	/** Returns the point on a curve from one point to another, the curve leaving and arriving along two tangents (a cubic Hermite curve).

		@param from  The point at 0.
		@param fromTangent  The curve's direction and speed leaving `from`.
		@param to  The point at 1.
		@param toTangent  The curve's direction and speed arriving at `to`.
		@param amount  How far along, 0 to 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be any of the four.
		@return  The point. */
	public static function hermite(from:Vector2, fromTangent:Vector2, to:Vector2, toTangent:Vector2, amount:Float, ?out:Vector2):Vector2 {
		return result(out, Interpolate.hermite(from.x, fromTangent.x, to.x, toTangent.x, amount),
			Interpolate.hermite(from.y, fromTangent.y, to.y, toTangent.y, amount));
	}

	/** Sets the coordinates.

		@param x  The x coordinate.
		@param y  The y coordinate.
		@return  This vector. */
	public function set(x:Float, y:Float):Vector2 {
		this.x = real(x);
		this.y = real(y);
		return this;
	}

	/** Sets the coordinates to another vector's.

		@param other  The vector to copy.
		@return  This vector. */
	public function copyFrom(other:Vector2):Vector2 {
		return set(other.x, other.y);
	}

	/** Returns a separate vector with this one's coordinates.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The copy. */
	public function copy(?out:Vector2):Vector2 {
		return result(out, x, y);
	}

	/** Returns this vector plus another.

		@param other  The vector to add.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function add(other:Vector2, ?out:Vector2):Vector2 {
		return result(out, x + other.x, y + other.y);
	}

	/** Returns this vector minus another.

		@param other  The vector to subtract.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The difference. */
	public function subtract(other:Vector2, ?out:Vector2):Vector2 {
		return result(out, x - other.x, y - other.y);
	}

	/** Returns this vector with both coordinates multiplied by a number.

		@param factor  The number.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The scaled vector. */
	public function scale(factor:Float, ?out:Vector2):Vector2 {
		return result(out, real(x) * factor, real(y) * factor);
	}

	/** Returns this vector plus another times a number, as a position moves by a velocity over a time step.

		@param other  The vector to add.
		@param factor  The number it is multiplied by first.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function addScaled(other:Vector2, factor:Float, ?out:Vector2):Vector2 {
		return result(out, x + real(other.x) * factor, y + real(other.y) * factor);
	}

	/** Returns this vector turned the other way: both coordinates negated.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The negated vector. */
	public function negate(?out:Vector2):Vector2 {
		return result(out, -x, -y);
	}

	/** Returns 1 divided by each of this vector's coordinates.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The inverted vector. A coordinate of 0 gives an infinite one. */
	public function inverse(?out:Vector2):Vector2 {
		return result(out, 1 / x, 1 / y);
	}

	/** Returns this vector scaled to length 1, its direction kept.

		A vector of length 0 stays 0.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The vector of length 1, or of length 0. */
	public function normalize(?out:Vector2):Vector2 {
		var length = this.length;
		return length == 0 ? result(out, x, y) : result(out, x / length, y / length);
	}

	/** Returns this vector turned around the origin.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The turned vector. */
	public function rotate(radians:Float, ?out:Vector2):Vector2 {
		return rotated(real(x), real(y), radians, out);
	}

	/** Returns this vector times another, coordinate by coordinate.

		@param other  The vector to multiply by.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The product. */
	public function multiply(other:Vector2, ?out:Vector2):Vector2 {
		return result(out, real(x) * other.x, real(y) * other.y);
	}

	/** Returns this vector divided by another, coordinate by coordinate.

		@param other  The vector to divide by.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The quotient. */
	public function divide(other:Vector2, ?out:Vector2):Vector2 {
		return result(out, x / other.x, y / other.y);
	}

	/** Returns the lesser of this vector's and another's coordinates, each coordinate on its own.

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The least coordinates. */
	public function min(other:Vector2, ?out:Vector2):Vector2 {
		return result(out, x < other.x ? x : other.x, y < other.y ? y : other.y);
	}

	/** Returns the greater of this vector's and another's coordinates, each coordinate on its own.

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The greatest coordinates. */
	public function max(other:Vector2, ?out:Vector2):Vector2 {
		return result(out, x > other.x ? x : other.x, y > other.y ? y : other.y);
	}

	/** Returns this vector with each coordinate kept between two other vectors' coordinates.

		A coordinate's two bounds in the wrong order are swapped.
		@param min  The least coordinates.
		@param max  The greatest coordinates.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or either bound.
		@return  The clamped vector. */
	public function clamp(min:Vector2, max:Vector2, ?out:Vector2):Vector2 {
		return result(out, between(x, min.x, max.x), between(y, min.y, max.y));
	}

	/** Returns this vector with its length kept between two lengths, its direction unchanged.

		A vector of length 0 stays 0. Bounds in the wrong order are swapped.
		@param min  The least length.
		@param max  The greatest length.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The clamped vector. */
	public function clampLength(min:Float, max:Float, ?out:Vector2):Vector2 {
		var length = this.length;
		if (length == 0)
			return result(out, 0, 0);
		var factor = between(length, min, max) / length;
		return result(out, x * factor, y * factor);
	}

	/** Returns this point moved toward a target by at most a step.

		The point reaches the target exactly. A step of 0 or less leaves the point where it is.
		@param target  The point to move toward.
		@param step  The most distance to move.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the target.
		@return  The moved point. */
	public function moveToward(target:Vector2, step:Float, ?out:Vector2):Vector2 {
		var dx = real(target.x) - x, dy = real(target.y) - y;
		var squared = dx * dx + dy * dy, step = real(step);
		if (step <= 0)
			return result(out, x, y);
		if (squared <= step * step)
			return result(out, target.x, target.y);
		var distance = sqrt(squared);
		return result(out, x + dx / distance * step, y + dy / distance * step);
	}

	/** Returns this direction bounced off a surface.

		@param normal  The surface's normal, of length 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
		@return  The reflected direction. */
	public function reflect(normal:Vector2, ?out:Vector2):Vector2 {
		var twice = 2 * dot(normal);
		return result(out, x - normal.x * twice, y - normal.y * twice);
	}

	/** Returns this direction bent as light bends entering a surface.

		@param normal  The surface's normal, of length 1.
		@param ratio  The refractive index of what the direction leaves, over the index of what the direction enters.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
		@return  The bent direction, or all 0 when the surface reflects the direction wholly. */
	public function refract(normal:Vector2, ratio:Float, ?out:Vector2):Vector2 {
		var along = dot(normal), ratio = real(ratio);
		var root = 1 - ratio * ratio * (1 - along * along);
		if (!(root >= 0))
			return result(out, 0, 0);
		var back = ratio * along + sqrt(root);
		return result(out, ratio * x - back * normal.x, ratio * y - back * normal.y);
	}

	/** Returns the angle from this vector to another, in radians.

		@param other  The other vector.
		@return  The angle, -pi to pi: more than 0 when the other is turned from this one toward +y. */
	public function angleTo(other:Vector2):Float
		return atan2(cross(other), dot(other));

	/** Gets the length. */
	public var length(get, never):Float;

	function get_length():Float
		return sqrt(lengthSquared);

	/** Gets the length squared, which is quicker to find than the length and orders vectors alike. */
	public var lengthSquared(get, never):Float;

	function get_lengthSquared():Float {
		var x = real(this.x), y = real(this.y);
		return x * x + y * y;
	}

	/** Gets the angle from +x toward +y, in radians, -pi to pi; 0 for a vector of length 0. */
	public var angle(get, never):Float;

	function get_angle():Float
		return atan2(y, x);

	/** Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.

		@param other  The other vector.
		@return  The dot product; 0 when they are at right angles. */
	public function dot(other:Vector2):Float
		return real(x) * other.x + real(y) * other.y;

	/** Returns the cross product with another vector, as a number: the product of their lengths and the sine of the angle from this one
		to the other.

		@param other  The other vector.
		@return  The cross product: more than 0 when the other is turned from this one toward +y, 0 when they are parallel. */
	public function cross(other:Vector2):Float
		return real(x) * other.y - real(y) * other.x;

	/** Returns the distance to another vector, each taken as a position.

		@param other  The other vector.
		@return  The distance. */
	public function distance(other:Vector2):Float
		return sqrt(distanceSquared(other));

	/** Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.

		@param other  The other vector.
		@return  The distance squared. */
	public function distanceSquared(other:Vector2):Float {
		var dx = real(other.x) - x, dy = real(other.y) - y;
		return dx * dx + dy * dy;
	}

	/** Returns whether another vector is the same, within a tolerance on each coordinate.

		@param other  The other vector.
		@param tolerance  Optional. The most each coordinate may differ by, multiplied by the larger coordinate's size when that size is
			over 1; defaults to 0, exactly equal.
		@return  True when every coordinate is within the tolerance. */
	public function equals(other:Vector2, tolerance = 0.):Bool
		return near(x, other.x, tolerance) && near(y, other.y, tolerance);

	// hxcpp builds a Vector2 in place only while no instance method names another class, so each reaches these through a static,
	// inlined on the other targets.
	static #if !cpp inline #end function sqrt(value:Float):Float
		return Math.sqrt(value);

	static #if !cpp inline #end function rotated(x:Float, y:Float, radians:Float, out:Null<Vector2>):Vector2 {
		var turn = Trig.turn(radians), c = turn.cos, s = turn.sin;
		return result(out, x * c - y * s, x * s + y * c);
	}

	static #if !cpp inline #end function atan2(y:Float, x:Float):Float
		return Trig.atan2(y, x);

	static #if !cpp inline #end function near(a:Float, b:Float, tolerance:Float):Bool
		return Interpolate.equals(a, b, tolerance);

	// A value kept between two bounds, the bounds swapped when they are in the wrong order (as Interpolate.clamp).
	static inline function between(value:Float, min:Float, max:Float):Float {
		return min <= max ? (value < min ? min : value > max ? max : value) : (value < max ? max : value > min ? min : value);
	}

	// The out filled with a result its inputs were read for first: a new vector when there is none.
	static inline function result(out:Null<Vector2>, x:Float, y:Float):Vector2
		return out == null ? new Vector2(x, y) : out.set(x, y);

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
