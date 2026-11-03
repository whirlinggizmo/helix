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
	var velocity = Vector2D.fromAngle(heading, speed);
	position.addScaled(velocity, dt, position);
	var toward = target.subtract(position).normalize();
	``` */
class Vector2D {
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
	public static function fromAngle(radians:Float, length = 1., ?out:Vector2D):Vector2D {
		return result(out, Trig.cos(radians) * length, Trig.sin(radians) * length);
	}

	/** Returns the vector a fraction of the way from one vector to another.

		A fraction outside 0 to 1 goes past the ends.
		@param from  The vector at 0.
		@param to  The vector at 1.
		@param amount  The fraction.
		@param out  Optional. The vector to fill; a new one when omitted. It may be from or to.
		@return  The vector. */
	public static function lerp(from:Vector2D, to:Vector2D, amount:Float, ?out:Vector2D):Vector2D {
		var fromX = real(from.x), fromY = real(from.y);
		return result(out, fromX + (to.x - fromX) * amount, fromY + (to.y - fromY) * amount);
	}

	/** Sets the coordinates.

		@param x  The x coordinate.
		@param y  The y coordinate.
		@return  This vector. */
	public function set(x:Float, y:Float):Vector2D {
		this.x = real(x);
		this.y = real(y);
		return this;
	}

	/** Sets the coordinates to another vector's.

		@param other  The vector to copy.
		@return  This vector. */
	public function copyFrom(other:Vector2D):Vector2D {
		return set(other.x, other.y);
	}

	/** Returns this vector plus another.

		@param other  The vector to add.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function add(other:Vector2D, ?out:Vector2D):Vector2D {
		return result(out, x + other.x, y + other.y);
	}

	/** Returns this vector minus another.

		@param other  The vector to subtract.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The difference. */
	public function subtract(other:Vector2D, ?out:Vector2D):Vector2D {
		return result(out, x - other.x, y - other.y);
	}

	/** Returns this vector with both coordinates multiplied by a number.

		@param factor  The number.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The scaled vector. */
	public function scale(factor:Float, ?out:Vector2D):Vector2D {
		return result(out, real(x) * factor, real(y) * factor);
	}

	/** Returns this vector plus another times a number, as a position moves by a velocity over a time step.

		@param other  The vector to add.
		@param factor  The number it is multiplied by first.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function addScaled(other:Vector2D, factor:Float, ?out:Vector2D):Vector2D {
		return result(out, x + real(other.x) * factor, y + real(other.y) * factor);
	}

	/** Returns this vector turned the other way: both coordinates negated.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The negated vector. */
	public function negate(?out:Vector2D):Vector2D {
		return result(out, -x, -y);
	}

	/** Returns this vector scaled to length 1, its direction kept.

		A vector of length 0 stays 0.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The vector of length 1, or of length 0. */
	public function normalize(?out:Vector2D):Vector2D {
		var length = this.length;
		return length == 0 ? result(out, x, y) : result(out, x / length, y / length);
	}

	/** Returns this vector turned around the origin.

		@param radians  The angle; more than 0 turns from +x toward +y.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The turned vector. */
	public function rotate(radians:Float, ?out:Vector2D):Vector2D {
		var c = Trig.cos(radians),
			s = Trig.sin(radians),
			x = real(this.x),
			y = real(this.y);
		return result(out, x * c - y * s, x * s + y * c);
	}

	/** Gets the length. */
	public var length(get, never):Float;

	function get_length():Float
		return Math.sqrt(lengthSquared);

	/** Gets the length squared, which is quicker to find than the length and orders vectors alike. */
	public var lengthSquared(get, never):Float;

	function get_lengthSquared():Float {
		var x = real(this.x), y = real(this.y);
		return x * x + y * y;
	}

	/** Gets the angle from +x toward +y, in radians, -pi to pi; 0 for a vector of length 0. */
	public var angle(get, never):Float;

	function get_angle():Float
		return Trig.atan2(y, x);

	/** Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.

		@param other  The other vector.
		@return  The dot product; 0 when they are at right angles. */
	public function dot(other:Vector2D):Float
		return real(x) * other.x + real(y) * other.y;

	/** Returns the cross product with another vector, as a number: the product of their lengths and the sine of the angle from this one
		to the other.

		@param other  The other vector.
		@return  The cross product: more than 0 when the other is turned from this one toward +y, 0 when they are parallel. */
	public function cross(other:Vector2D):Float
		return real(x) * other.y - real(y) * other.x;

	/** Returns the distance to another vector, each taken as a position.

		@param other  The other vector.
		@return  The distance. */
	public function distance(other:Vector2D):Float
		return Math.sqrt(distanceSquared(other));

	/** Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.

		@param other  The other vector.
		@return  The distance squared. */
	public function distanceSquared(other:Vector2D):Float {
		var dx = real(other.x) - x, dy = real(other.y) - y;
		return dx * dx + dy * dy;
	}

	/** Returns whether another vector is the same, within a tolerance on each coordinate.

		@param other  The other vector.
		@param tolerance  Optional. The most each coordinate may differ by; defaults to 0, exactly equal.
		@return  True when every coordinate is within the tolerance. */
	public function equals(other:Vector2D, tolerance = 0.):Bool
		return Math.abs(x - other.x) <= tolerance && Math.abs(y - other.y) <= tolerance;

	// The out filled with a result its inputs were read for first: a new vector when there is none.
	static inline function result(out:Null<Vector2D>, x:Float, y:Float):Vector2D
		return out == null ? new Vector2D(x, y) : out.set(x, y);

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
