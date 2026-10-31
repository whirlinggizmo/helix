package helix.math;

/** Represents a vector in 3 dimensions: a position or a direction, as its user means it.

	Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and
	leaves this one unchanged; given this vector, it changes it in place (`v.normalize(v)`). The out may be this vector or any other
	argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`).
	`set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `distance`) is a method, a number of one
	(`length`) a property. `Matrix3D` keeps positions and directions apart by its methods: `transformPoint` moves a position,
	`transformDirection` only turns and scales a direction.

	It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, so a vector comes out
	the same everywhere. Space is right-handed with +y up, as every 3D type here.

	```haxe
	position.addScaled(velocity, dt, position);
	var toward = target.subtract(position).normalize();
	var right = forward.cross(up);
	``` */
class Vector3D {
	/** Gets or sets the x coordinate. */
	public var x:Float;

	/** Gets or sets the y coordinate. */
	public var y:Float;

	/** Gets or sets the z coordinate. */
	public var z:Float;

	/** Creates a vector.

		@param x  Optional. The x coordinate; defaults to 0.
		@param y  Optional. The y coordinate; defaults to 0.
		@param z  Optional. The z coordinate; defaults to 0. */
	public function new(x = 0., y = 0., z = 0.) {
		this.x = real(x);
		this.y = real(y);
		this.z = real(z);
	}

	/** Returns the vector a fraction of the way from one vector to another.

		A fraction outside 0 to 1 goes past the ends.
		@param from  The vector at 0.
		@param to  The vector at 1.
		@param amount  The fraction.
		@param out  Optional. The vector to fill; a new one when omitted. It may be from or to.
		@return  The vector. */
	public static function lerp(from:Vector3D, to:Vector3D, amount:Float, ?out:Vector3D):Vector3D {
		var fromX = real(from.x), fromY = real(from.y), fromZ = real(from.z);
		return result(out, fromX + (to.x - fromX) * amount, fromY + (to.y - fromY) * amount, fromZ + (to.z - fromZ) * amount);
	}

	/** Sets the coordinates.

		@param x  The x coordinate.
		@param y  The y coordinate.
		@param z  The z coordinate.
		@return  This vector. */
	public function set(x:Float, y:Float, z:Float):Vector3D {
		this.x = real(x);
		this.y = real(y);
		this.z = real(z);
		return this;
	}

	/** Sets the coordinates to another vector's.

		@param other  The vector to copy.
		@return  This vector. */
	public function copyFrom(other:Vector3D):Vector3D {
		return set(other.x, other.y, other.z);
	}

	/** Returns this vector plus another.

		@param other  The vector to add.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function add(other:Vector3D, ?out:Vector3D):Vector3D {
		return result(out, x + other.x, y + other.y, z + other.z);
	}

	/** Returns this vector minus another.

		@param other  The vector to subtract.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The difference. */
	public function subtract(other:Vector3D, ?out:Vector3D):Vector3D {
		return result(out, x - other.x, y - other.y, z - other.z);
	}

	/** Returns this vector with every coordinate multiplied by a number.

		@param factor  The number.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The scaled vector. */
	public function scale(factor:Float, ?out:Vector3D):Vector3D {
		return result(out, real(x) * factor, real(y) * factor, real(z) * factor);
	}

	/** Returns this vector plus another times a number, as a position moves by a velocity over a time step.

		@param other  The vector to add.
		@param factor  The number it is multiplied by first.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function addScaled(other:Vector3D, factor:Float, ?out:Vector3D):Vector3D {
		return result(out, x + real(other.x) * factor, y + real(other.y) * factor, z + real(other.z) * factor);
	}

	/** Returns this vector turned the other way: every coordinate negated.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The negated vector. */
	public function negate(?out:Vector3D):Vector3D {
		return result(out, -x, -y, -z);
	}

	/** Returns this vector scaled to length 1, its direction kept.

		A vector of length 0 stays 0.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The vector of length 1, or of length 0. */
	public function normalize(?out:Vector3D):Vector3D {
		var length = this.length;
		return length == 0 ? result(out, x, y, z) : result(out, x / length, y / length, z / length);
	}

	/** Returns the cross product with another vector: at right angles to both, as long as the area they span, by the right-hand rule (x
		cross y is z).

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The cross product; of length 0 when they are parallel. */
	public function cross(other:Vector3D, ?out:Vector3D):Vector3D {
		var ax = real(x), ay = real(y), az = real(z), bx = other.x, by = other.y, bz = other.z;
		return result(out, ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx);
	}

	/** Gets the length. */
	public var length(get, never):Float;

	function get_length():Float
		return Math.sqrt(lengthSquared);

	/** Gets the length squared, which is quicker to find than the length and orders vectors alike. */
	public var lengthSquared(get, never):Float;

	function get_lengthSquared():Float {
		var x = real(this.x), y = real(this.y), z = real(this.z);
		return x * x + y * y + z * z;
	}

	/** Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.

		@param other  The other vector.
		@return  The dot product; 0 when they are at right angles. */
	public function dot(other:Vector3D):Float
		return real(x) * other.x + real(y) * other.y + real(z) * other.z;

	/** Returns the distance to another vector, each taken as a position.

		@param other  The other vector.
		@return  The distance. */
	public function distance(other:Vector3D):Float
		return Math.sqrt(distanceSquared(other));

	/** Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.

		@param other  The other vector.
		@return  The distance squared. */
	public function distanceSquared(other:Vector3D):Float {
		var dx = real(other.x) - x,
			dy = real(other.y) - y,
			dz = real(other.z) - z;
		return dx * dx + dy * dy + dz * dz;
	}

	/** Returns whether another vector is the same, within a tolerance on each coordinate.

		@param other  The other vector.
		@param tolerance  Optional. The most each coordinate may differ by; defaults to 0, exactly equal.
		@return  True when every coordinate is within the tolerance. */
	public function equals(other:Vector3D, tolerance = 0.):Bool
		return Math.abs(x - other.x) <= tolerance && Math.abs(y - other.y) <= tolerance && Math.abs(z - other.z) <= tolerance;

	// The out filled with a result its inputs were read for first: a new vector when there is none.
	static inline function result(out:Null<Vector3D>, x:Float, y:Float, z:Float):Vector3D
		return out == null ? new Vector3D(x, y, z) : out.set(x, y, z);

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
