package helix.math;

/** Represents a vector in 3 dimensions: a position or a direction, as its user means it.

	Each operation writes its result into an optional out, the last argument, and returns it. Without one it makes a new vector and
	leaves this one unchanged; with this vector as the out, it works in place (`v.normalize(v)`). The out may be this vector or any other
	argument, as every input is read before anything is written, and calls chain through what each returns (`a.add(b, a).scale(2, a)`).
	`set` and `copyFrom` change this vector and return it. A number made from vectors (`dot`, `distance`) is a method, a number of one
	(`length`) a property. `Matrix4` keeps positions and directions apart by its methods: `transformPoint` moves a position,
	`transformDirection` only turns and scales a direction.

	It uses only addition, subtraction, multiplication, division and square roots, which agree on every target, so a vector comes out
	the same everywhere. Space is right-handed with +y up, as every 3D type here.

	```haxe
	position.addScaled(velocity, dt, position);
	var toward = target.subtract(position).normalize();
	var right = forward.cross(up);
	``` */
@:structInit
class Vector3 {
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
	public static function lerp(from:Vector3, to:Vector3, amount:Float, ?out:Vector3):Vector3 {
		var fromX = real(from.x), fromY = real(from.y), fromZ = real(from.z);
		return result(out, fromX + (to.x - fromX) * amount, fromY + (to.y - fromY) * amount, fromZ + (to.z - fromZ) * amount);
	}

	/** Returns the point on a curve from one point to another, the curve leaving and arriving along two tangents (a cubic Hermite curve).

		@param from  The point at 0.
		@param fromTangent  The curve's direction and speed leaving `from`.
		@param to  The point at 1.
		@param toTangent  The curve's direction and speed arriving at `to`.
		@param amount  How far along, 0 to 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be any of the four.
		@return  The point. */
	public static function hermite(from:Vector3, fromTangent:Vector3, to:Vector3, toTangent:Vector3, amount:Float, ?out:Vector3):Vector3 {
		return result(out, Interpolate.hermite(from.x, fromTangent.x, to.x, toTangent.x, amount),
			Interpolate.hermite(from.y, fromTangent.y, to.y, toTangent.y, amount), Interpolate.hermite(from.z, fromTangent.z, to.z, toTangent.z, amount));
	}

	/** Makes two vectors of length 1 and square to each other, in place.

		@param first  The vector whose direction is kept.
		@param second  The vector turned to be square to `first`, in the plane the two vectors span. */
	public static function orthoNormalize(first:Vector3, second:Vector3):Void {
		first.normalize(first);
		var ax = first.x, ay = first.y, az = first.z;
		// The plane's normal, then the normal crossed with the first: the second with its part along the first removed.
		var nx = ay * second.z - az * second.y,
			ny = az * second.x - ax * second.z,
			nz = ax * second.y - ay * second.x;
		var length = Math.sqrt(nx * nx + ny * ny + nz * nz);
		if (length == 0)
			length = 1;
		nx /= length;
		ny /= length;
		nz /= length;
		second.set(ny * az - nz * ay, nz * ax - nx * az, nx * ay - ny * ax);
	}

	/** Returns a point's weights among a triangle's three corners (barycentric coordinates).

		@param point  The point, in the triangle's plane.
		@param a  The first corner.
		@param b  The second corner.
		@param c  The third corner.
		@param out  Optional. The vector to fill; a new one when omitted. It may be any of the four.
		@return  The weights of `a`, `b` and `c`, which add to 1. */
	public static function barycentric(point:Vector3, a:Vector3, b:Vector3, c:Vector3, ?out:Vector3):Vector3 {
		var v0x = real(b.x) - a.x,
			v0y = real(b.y) - a.y,
			v0z = real(b.z) - a.z;
		var v1x = real(c.x) - a.x,
			v1y = real(c.y) - a.y,
			v1z = real(c.z) - a.z;
		var v2x = real(point.x) - a.x,
			v2y = real(point.y) - a.y,
			v2z = real(point.z) - a.z;
		var d00 = v0x * v0x + v0y * v0y + v0z * v0z,
			d01 = v0x * v1x + v0y * v1y + v0z * v1z,
			d11 = v1x * v1x + v1y * v1y + v1z * v1z,
			d20 = v2x * v0x + v2y * v0y + v2z * v0z,
			d21 = v2x * v1x + v2y * v1y + v2z * v1z;
		var denominator = d00 * d11 - d01 * d01;
		var v = (d11 * d20 - d01 * d21) / denominator,
			w = (d00 * d21 - d01 * d20) / denominator;
		return result(out, 1 - (w + v), v, w);
	}

	/** Sets the coordinates.

		@param x  The x coordinate.
		@param y  The y coordinate.
		@param z  The z coordinate.
		@return  This vector. */
	public function set(x:Float, y:Float, z:Float):Vector3 {
		this.x = real(x);
		this.y = real(y);
		this.z = real(z);
		return this;
	}

	/** Sets the coordinates to another vector's.

		@param other  The vector to copy.
		@return  This vector. */
	public function copyFrom(other:Vector3):Vector3 {
		return set(other.x, other.y, other.z);
	}

	/** Returns a separate vector with this one's coordinates.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The copy. */
	public function copy(?out:Vector3):Vector3 {
		return result(out, x, y, z);
	}

	/** Returns this vector plus another.

		@param other  The vector to add.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function add(other:Vector3, ?out:Vector3):Vector3 {
		return result(out, x + other.x, y + other.y, z + other.z);
	}

	/** Returns this vector minus another.

		@param other  The vector to subtract.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The difference. */
	public function subtract(other:Vector3, ?out:Vector3):Vector3 {
		return result(out, x - other.x, y - other.y, z - other.z);
	}

	/** Returns this vector with every coordinate multiplied by a number.

		@param factor  The number.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The scaled vector. */
	public function scale(factor:Float, ?out:Vector3):Vector3 {
		return result(out, real(x) * factor, real(y) * factor, real(z) * factor);
	}

	/** Returns this vector plus another times a number, as a position moves by a velocity over a time step.

		@param other  The vector to add.
		@param factor  The number it is multiplied by first.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The sum. */
	public function addScaled(other:Vector3, factor:Float, ?out:Vector3):Vector3 {
		return result(out, x + real(other.x) * factor, y + real(other.y) * factor, z + real(other.z) * factor);
	}

	/** Returns this vector turned the other way: every coordinate negated.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The negated vector. */
	public function negate(?out:Vector3):Vector3 {
		return result(out, -x, -y, -z);
	}

	/** Returns 1 divided by each of this vector's coordinates.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The inverted vector. A coordinate of 0 becomes an infinite one. */
	public function inverse(?out:Vector3):Vector3 {
		return result(out, 1 / x, 1 / y, 1 / z);
	}

	/** Returns this vector scaled to length 1, its direction kept.

		A vector of length 0 stays 0.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The vector of length 1, or of length 0. */
	public function normalize(?out:Vector3):Vector3 {
		var length = this.length;
		return length == 0 ? result(out, x, y, z) : result(out, x / length, y / length, z / length);
	}

	/** Returns the cross product with another vector: at right angles to both, as long as the area they span, by the right-hand rule (x
		cross y is z).

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The cross product; of length 0 when they are parallel. */
	public function cross(other:Vector3, ?out:Vector3):Vector3 {
		var ax = real(x), ay = real(y), az = real(z), bx = other.x, by = other.y, bz = other.z;
		return result(out, ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx);
	}

	/** Returns this vector times another, coordinate by coordinate.

		@param other  The vector to multiply by.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The product. */
	public function multiply(other:Vector3, ?out:Vector3):Vector3 {
		return result(out, real(x) * other.x, real(y) * other.y, real(z) * other.z);
	}

	/** Returns this vector divided by another, coordinate by coordinate.

		@param other  The vector to divide by.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The quotient. */
	public function divide(other:Vector3, ?out:Vector3):Vector3 {
		return result(out, x / other.x, y / other.y, z / other.z);
	}

	/** Returns the lesser of this vector's and another's coordinates, each coordinate on its own.

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The least coordinates. */
	public function min(other:Vector3, ?out:Vector3):Vector3 {
		return result(out, x < other.x ? x : other.x, y < other.y ? y : other.y, z < other.z ? z : other.z);
	}

	/** Returns the greater of this vector's and another's coordinates, each coordinate on its own.

		@param other  The other vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The greatest coordinates. */
	public function max(other:Vector3, ?out:Vector3):Vector3 {
		return result(out, x > other.x ? x : other.x, y > other.y ? y : other.y, z > other.z ? z : other.z);
	}

	/** Returns this vector with each coordinate kept between two other vectors' coordinates.

		A coordinate's two bounds in the wrong order are swapped.
		@param min  The least coordinates.
		@param max  The greatest coordinates.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or either bound.
		@return  The clamped vector. */
	public function clamp(min:Vector3, max:Vector3, ?out:Vector3):Vector3 {
		return result(out, between(x, min.x, max.x), between(y, min.y, max.y), between(z, min.z, max.z));
	}

	/** Returns this vector with its length kept between two lengths, its direction unchanged.

		A vector of length 0 stays 0. Bounds in the wrong order are swapped.
		@param min  The least length.
		@param max  The greatest length.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The clamped vector. */
	public function clampLength(min:Float, max:Float, ?out:Vector3):Vector3 {
		var length = this.length;
		if (length == 0)
			return result(out, 0, 0, 0);
		var factor = between(length, min, max) / length;
		return result(out, x * factor, y * factor, z * factor);
	}

	/** Returns this point moved toward a target by at most a step.

		The point reaches the target exactly. A step of 0 or less leaves the point where it is.
		@param target  The point to move toward.
		@param step  The most distance to move.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the target.
		@return  The moved point. */
	public function moveToward(target:Vector3, step:Float, ?out:Vector3):Vector3 {
		var dx = real(target.x) - x,
			dy = real(target.y) - y,
			dz = real(target.z) - z;
		var squared = dx * dx + dy * dy + dz * dz, step = real(step);
		if (step <= 0)
			return result(out, x, y, z);
		if (squared <= step * step)
			return result(out, target.x, target.y, target.z);
		var distance = sqrt(squared);
		return result(out, x + dx / distance * step, y + dy / distance * step, z + dz / distance * step);
	}

	/** Returns this direction bounced off a surface.

		@param normal  The surface's normal, of length 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
		@return  The reflected direction. */
	public function reflect(normal:Vector3, ?out:Vector3):Vector3 {
		var twice = 2 * dot(normal);
		return result(out, x - normal.x * twice, y - normal.y * twice, z - normal.z * twice);
	}

	/** Returns this direction bent as light bends entering a surface.

		@param normal  The surface's normal, of length 1.
		@param ratio  The refractive index of what the direction leaves, over the index of what the direction enters.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the normal.
		@return  The bent direction, or all 0 when the surface reflects the direction wholly. */
	public function refract(normal:Vector3, ratio:Float, ?out:Vector3):Vector3 {
		var along = dot(normal), ratio = real(ratio);
		var root = 1 - ratio * ratio * (1 - along * along);
		if (!(root >= 0))
			return result(out, 0, 0, 0);
		var back = ratio * along + sqrt(root);
		return result(out, ratio * x - back * normal.x, ratio * y - back * normal.y, ratio * z - back * normal.z);
	}

	/** Returns the angle between this vector and another, in radians.

		@param other  The other vector.
		@return  The angle, 0 to pi. */
	public function angleTo(other:Vector3):Float {
		var ax = real(x), ay = real(y), az = real(z), bx = other.x, by = other.y, bz = other.z;
		var cx = ay * bz - az * by,
			cy = az * bx - ax * bz,
			cz = ax * by - ay * bx;
		return atan2(sqrt(cx * cx + cy * cy + cz * cz), ax * bx + ay * by + az * bz);
	}

	/** Returns the part of this vector that lies along another.

		@param onto  The vector to project onto, of any length but 0.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The projection. */
	public function project(onto:Vector3, ?out:Vector3):Vector3 {
		var factor = dot(onto) / onto.lengthSquared;
		return result(out, onto.x * factor, onto.y * factor, onto.z * factor);
	}

	/** Returns the part of this vector that is square to another: this vector less its projection.

		@param from  The vector to be square to, of any length but 0.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the other.
		@return  The rejection. */
	public function reject(from:Vector3, ?out:Vector3):Vector3 {
		var factor = dot(from) / from.lengthSquared;
		return result(out, x - from.x * factor, y - from.y * factor, z - from.z * factor);
	}

	/** Returns a vector square to this one: this vector crossed with the axis this vector lies least along.

		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector.
		@return  The perpendicular vector, of length 0 when this vector is. */
	public function perpendicular(?out:Vector3):Vector3 {
		var ax = (x < 0 ? -x : x),
			ay = (y < 0 ? -y : y),
			az = (z < 0 ? -z : z);
		if (az < ax && az < ay)
			return result(out, y, -x, 0);
		return ay < ax ? result(out, -z, 0, x) : result(out, 0, z, -y);
	}

	/** Returns this point turned around an axis through the origin.

		@param axis  The axis, of any length. An axis of length 0 leaves the point where it is.
		@param radians  The angle, by the right-hand rule around the axis.
		@param out  Optional. The vector to fill; a new one when omitted. It may be this vector or the axis.
		@return  The turned point. */
	public function rotate(axis:Vector3, radians:Float, ?out:Vector3):Vector3 {
		return rotated(x, y, z, real(axis.x), real(axis.y), real(axis.z), radians, out);
	}

	/** Gets the length. */
	public var length(get, never):Float;

	function get_length():Float
		return sqrt(lengthSquared);

	/** Gets the length squared, which is quicker to find than the length and orders vectors alike. */
	public var lengthSquared(get, never):Float;

	function get_lengthSquared():Float {
		var x = real(this.x), y = real(this.y), z = real(this.z);
		return x * x + y * y + z * z;
	}

	/** Returns the dot product with another vector: the product of their lengths and the cosine of the angle between them.

		@param other  The other vector.
		@return  The dot product; 0 when they are at right angles. */
	public function dot(other:Vector3):Float
		return real(x) * other.x + real(y) * other.y + real(z) * other.z;

	/** Returns the distance to another vector, each treated as a position.

		@param other  The other vector.
		@return  The distance. */
	public function distance(other:Vector3):Float
		return sqrt(distanceSquared(other));

	/** Returns the distance to another vector squared, which is quicker to find than the distance and orders distances alike.

		@param other  The other vector.
		@return  The distance squared. */
	public function distanceSquared(other:Vector3):Float {
		var dx = real(other.x) - x,
			dy = real(other.y) - y,
			dz = real(other.z) - z;
		return dx * dx + dy * dy + dz * dz;
	}

	/** Returns whether another vector is the same, within a tolerance on each coordinate.

		@param other  The other vector.
		@param tolerance  Optional. The most each coordinate may differ by, multiplied by the larger coordinate's size when that size is
			over 1; defaults to 0, exactly equal.
		@return  True when every coordinate is within the tolerance. */
	public function equals(other:Vector3, tolerance = 0.):Bool
		return near(x, other.x, tolerance) && near(y, other.y, tolerance) && near(z, other.z, tolerance);

	// hxcpp builds a Vector3 in place only while no instance method names another class, so each reaches these through a static,
	// inlined on the other targets.
	static #if !cpp inline #end function sqrt(value:Float):Float
		return Math.sqrt(value);

	static #if !cpp inline #end function rotated(x:Float, y:Float, z:Float, kx:Float, ky:Float, kz:Float, radians:Float, out:Null<Vector3>):Vector3 {
		var length = Math.sqrt(kx * kx + ky * ky + kz * kz);
		if (length == 0)
			return result(out, x, y, z);
		kx /= length;
		ky /= length;
		kz /= length;
		// Rodrigues' formula: the point's part along the axis kept, the rest turned in the plane square to the axis.
		var turn = Trig.turn(radians), c = turn.cos, s = turn.sin;
		var along = (kx * x + ky * y + kz * z) * (1 - c);
		return result(out, x * c
			+ (ky * z - kz * y) * s
			+ kx * along, y * c
			+ (kz * x - kx * z) * s
			+ ky * along, z * c
			+ (kx * y - ky * x) * s
			+ kz * along);
	}

	static #if !cpp inline #end function atan2(y:Float, x:Float):Float
		return Trig.atan2(y, x);

	static #if !cpp inline #end function near(a:Float, b:Float, tolerance:Float):Bool
		return MathTools.equals(a, b, tolerance);

	// A value kept between two bounds, the bounds swapped when they are in the wrong order (as Interpolate.clamp).
	static inline function between(value:Float, min:Float, max:Float):Float {
		return min <= max ? (value < min ? min : value > max ? max : value) : (value < max ? max : value > min ? min : value);
	}

	// The out filled with a result its inputs were read for first: a new vector when there is none.
	static inline function result(out:Null<Vector3>, x:Float, y:Float, z:Float):Vector3
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
