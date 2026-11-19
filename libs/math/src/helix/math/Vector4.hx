package helix.math;

/** Represents a vector of 4 numbers: a point before its perspective divide, a tangent with its handedness, a plane, or any four a
	shader reads, as its user means it.

	Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and
	leaves this one unchanged; provided this vector, it works in place (`v.normalize(v)`). The out may be this vector or any other
	argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`).
	`set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `distance`) is a method, a number of one
	(`length`) a property. See `Quaternion` for a rotation, which has four numbers too and its own operations.

	It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, so a vector comes out
	the same everywhere.

	```haxe
	var clip = new Vector4(x, y, z, 1);
	var plane = new Vector4(0, 1, 0, -height).normalize();
	``` */
@:structInit
class Vector4 {
	/** Gets or sets the x coordinate. */
	public var x:Float;

	/** Gets or sets the y coordinate. */
	public var y:Float;

	/** Gets or sets the z coordinate. */
	public var z:Float;

	/** Gets or sets the w coordinate. */
	public var w:Float;

	/** Creates a vector.

		@param x  Optional. The x coordinate; defaults to 0.
		@param y  Optional. The y coordinate; defaults to 0.
		@param z  Optional. The z coordinate; defaults to 0.
		@param w  Optional. The w coordinate; defaults to 0. */
	public function new(x = 0., y = 0., z = 0., w = 0.) {
		this.x = real(x);
		this.y = real(y);
		this.z = real(z);
		this.w = real(w);
	}

	/** Returns the vector a fraction of the way from one vector to another.

		A fraction outside 0 to 1 goes past the ends.
		@param from  The vector at 0.
		@param to  The vector at 1.
		@param amount  The fraction.
		@param out  Optional. The vector to fill; a new one when omitted. It may be from or to.
		@return  The vector. */
	public static function lerp(from:Vector4, to:Vector4, amount:Float, ?out:Vector4):Vector4 {
		var fromX = real(from.x),
			fromY = real(from.y),
			fromZ = real(from.z),
			fromW = real(from.w);
		var x = fromX + (to.x - fromX) * amount,
			y = fromY + (to.y - fromY) * amount;
		var z = fromZ + (to.z - fromZ) * amount,
			w = fromW + (to.w - fromW) * amount;
		return result(out, x, y, z, w);
	}

	/** Returns the point on a curve from one point to another, the curve leaving and arriving along two tangents (a cubic Hermite curve).

		@param from  The point at 0.
		@param fromTangent  The curve's direction and speed leaving `from`.
		@param to  The point at 1.
		@param toTangent  The curve's direction and speed arriving at `to`.
		@param amount  How far along, 0 to 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be any of the four.
		@return  The point. */
	public static function hermite(from:Vector4, fromTangent:Vector4, to:Vector4, toTangent:Vector4, amount:Float, ?out:Vector4):Vector4 {
		return result(out, Interpolate.hermite(from.x, fromTangent.x, to.x, toTangent.x, amount),
			Interpolate.hermite(from.y, fromTangent.y, to.y, toTangent.y, amount), Interpolate.hermite(from.z, fromTangent.z, to.z, toTangent.z, amount),
			Interpolate.hermite(from.w, fromTangent.w, to.w, toTangent.w, amount));
	}

	/** Sets the coordinates.

		@param x  The x coordinate.
		@param y  The y coordinate.
		@param z  The z coordinate.
		@param w  The w coordinate.
		@return  This vector. */
	public function set(x:Float, y:Float, z:Float, w:Float):Vector4 {
		this.x = real(x);
		this.y = real(y);
		this.z = real(z);
		this.w = real(w);
		return this;
	}

	/** Sets the coordinates to another vector's.

		@param other  The vector to copy.
		@return  This vector. */
	public function copyFrom(other:Vector4):Vector4 {
		return set(other.x, other.y, other.z, other.w);
	}

	/** Returns a separate vector with this one's coordinates.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The copy. */
	public function copy(?out:Vector4):Vector4 {
		return result(out, x, y, z, w);
	}

	/** Returns this vector plus another.

		@param other  The vector to add.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function add(other:Vector4, ?out:Vector4):Vector4 {
		return result(out, x + other.x, y + other.y, z + other.z, w + other.w);
	}

	/** Returns this vector minus another.

		@param other  The vector to subtract.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The difference. */
	public function subtract(other:Vector4, ?out:Vector4):Vector4 {
		return result(out, x - other.x, y - other.y, z - other.z, w - other.w);
	}

	/** Returns this vector with every coordinate multiplied by a number.

		@param factor  The number.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The scaled vector. */
	public function scale(factor:Float, ?out:Vector4):Vector4 {
		return result(out, real(x) * factor, real(y) * factor, real(z) * factor, real(w) * factor);
	}

	/** Returns this vector plus another times a number.

		@param other  The vector to add.
		@param factor  The number it is multiplied by first.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function addScaled(other:Vector4, factor:Float, ?out:Vector4):Vector4 {
		return result(out, x + real(other.x) * factor, y + real(other.y) * factor, z + real(other.z) * factor, w + real(other.w) * factor);
	}

	/** Returns this vector with every coordinate negated.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The negated vector. */
	public function negate(?out:Vector4):Vector4 {
		return result(out, -x, -y, -z, -w);
	}

	/** Returns 1 divided by each of this vector's coordinates.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The inverted vector. A coordinate of 0 becomes an infinite one. */
	public function inverse(?out:Vector4):Vector4 {
		return result(out, 1 / x, 1 / y, 1 / z, 1 / w);
	}

	/** Returns this vector scaled to length 1, the proportions of its coordinates kept.

		A vector of length 0 stays 0.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The vector of length 1, or of length 0. */
	public function normalize(?out:Vector4):Vector4 {
		var length = this.length;
		return length == 0 ? result(out, x, y, z, w) : result(out, x / length, y / length, z / length, w / length);
	}

	/** Returns this vector times another, coordinate by coordinate.

		@param other  The vector to multiply by.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The product. */
	public function multiply(other:Vector4, ?out:Vector4):Vector4 {
		return result(out, real(x) * other.x, real(y) * other.y, real(z) * other.z, real(w) * other.w);
	}

	/** Returns this vector divided by another, coordinate by coordinate.

		@param other  The vector to divide by.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The quotient. */
	public function divide(other:Vector4, ?out:Vector4):Vector4 {
		return result(out, x / other.x, y / other.y, z / other.z, w / other.w);
	}

	/** Returns the lesser of this vector's and another's coordinates, each coordinate on its own.

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The least coordinates. */
	public function min(other:Vector4, ?out:Vector4):Vector4 {
		return result(out, x < other.x ? x : other.x, y < other.y ? y : other.y, z < other.z ? z : other.z, w < other.w ? w : other.w);
	}

	/** Returns the greater of this vector's and another's coordinates, each coordinate on its own.

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The greatest coordinates. */
	public function max(other:Vector4, ?out:Vector4):Vector4 {
		return result(out, x > other.x ? x : other.x, y > other.y ? y : other.y, z > other.z ? z : other.z, w > other.w ? w : other.w);
	}

	/** Returns this vector with each coordinate kept between two other vectors' coordinates.

		A coordinate's two bounds in the wrong order are swapped.
		@param min  The least coordinates.
		@param max  The greatest coordinates.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or either bound.
		@return  The clamped vector. */
	public function clamp(min:Vector4, max:Vector4, ?out:Vector4):Vector4 {
		return result(out, between(x, min.x, max.x), between(y, min.y, max.y), between(z, min.z, max.z), between(w, min.w, max.w));
	}

	/** Returns this vector with its length kept between two lengths, its direction unchanged.

		A vector of length 0 stays 0. Bounds in the wrong order are swapped.
		@param min  The least length.
		@param max  The greatest length.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The clamped vector. */
	public function clampLength(min:Float, max:Float, ?out:Vector4):Vector4 {
		var length = this.length;
		if (length == 0)
			return result(out, 0, 0, 0, 0);
		var factor = between(length, min, max) / length;
		return result(out, x * factor, y * factor, z * factor, w * factor);
	}

	/** Returns this point moved toward a target by at most a step.

		The point reaches the target exactly. A step of 0 or less leaves the point where it is.
		@param target  The point to move toward.
		@param step  The most distance to move.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the target.
		@return  The moved point. */
	public function moveToward(target:Vector4, step:Float, ?out:Vector4):Vector4 {
		var dx = real(target.x) - x,
			dy = real(target.y) - y,
			dz = real(target.z) - z,
			dw = real(target.w) - w;
		var squared = dx * dx + dy * dy + dz * dz + dw * dw, step = real(step);
		if (step <= 0)
			return result(out, x, y, z, w);
		if (squared <= step * step)
			return result(out, target.x, target.y, target.z, target.w);
		var distance = sqrt(squared);
		return result(out, x + dx / distance * step, y + dy / distance * step, z + dz / distance * step, w + dw / distance * step);
	}

	/** Gets the length. */
	public var length(get, never):Float;

	function get_length():Float
		return sqrt(lengthSquared);

	/** Gets the length squared, which is quicker to find than the length and orders vectors alike. */
	public var lengthSquared(get, never):Float;

	function get_lengthSquared():Float {
		var x = real(this.x),
			y = real(this.y),
			z = real(this.z),
			w = real(this.w);
		return x * x + y * y + z * z + w * w;
	}

	/** Returns the dot product with another vector: each coordinate times the other's, summed.

		@param other  The other vector.
		@return  The dot product. */
	public function dot(other:Vector4):Float
		return real(x) * other.x + real(y) * other.y + real(z) * other.z + real(w) * other.w;

	/** Returns the distance to another vector.

		@param other  The other vector.
		@return  The distance. */
	public function distance(other:Vector4):Float
		return sqrt(distanceSquared(other));

	/** Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.

		@param other  The other vector.
		@return  The distance squared. */
	public function distanceSquared(other:Vector4):Float {
		var dx = real(other.x) - x,
			dy = real(other.y) - y,
			dz = real(other.z) - z,
			dw = real(other.w) - w;
		return dx * dx + dy * dy + dz * dz + dw * dw;
	}

	/** Returns whether another vector is the same, within a tolerance on each coordinate.

		@param other  The other vector.
		@param tolerance  Optional. The most each coordinate may differ by, multiplied by the larger coordinate's size when that size is
			over 1; defaults to 0, exactly equal.
		@return  True when every coordinate is within the tolerance. */
	public function equals(other:Vector4, tolerance = 0.):Bool
		return near(x, other.x, tolerance) && near(y, other.y, tolerance) && near(z, other.z, tolerance) && near(w, other.w, tolerance);

	// hxcpp builds a Vector4 in place only while no instance method names another class, so each reaches these through a static,
	// inlined on the other targets.
	static #if !cpp inline #end function sqrt(value:Float):Float
		return Math.sqrt(value);

	static #if !cpp inline #end function near(a:Float, b:Float, tolerance:Float):Bool
		return MathTools.equals(a, b, tolerance);

	// A value kept between two bounds, the bounds swapped when they are in the wrong order (as Interpolate.clamp).
	static inline function between(value:Float, min:Float, max:Float):Float {
		return min <= max ? (value < min ? min : value > max ? max : value) : (value < max ? max : value > min ? min : value);
	}

	// The out filled with a result its inputs were read for first: a new vector when there is none.
	static inline function result(out:Null<Vector4>, x:Float, y:Float, z:Float, w:Float):Vector4
		return out == null ? new Vector4(x, y, z, w) : out.set(x, y, z, w);

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
