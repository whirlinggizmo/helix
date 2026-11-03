package helix.math;

/** Represents a rotation in 3 dimensions, as a unit quaternion.

	Two rotations blend along the shortest arc (`slerp`), which matrices can't do, so an animation's rotations are kept as these and
	turned into a matrix to draw. A static `fromX` makes a rotation, and `slerp`, `nlerp` and `compose` make one from others. Each of
	those, and each operation on a rotation (`append`, `invert`, `normalize`, `transformPoint`, `toMatrix`), writes its result into an
	optional out, the last argument, and returns it. Without one it makes a new result and leaves this rotation unchanged; given this
	rotation, it changes it in place (`q.normalize(q)`). The out may be this rotation or any other argument, and calls chain through what
	each returns. `set`, `copyFrom` and `makeIdentity` change this rotation and return it. It uses `Trig`, so a rotation comes out the
	same on every target. Space is right-handed with +y up, as every 3D type here.

	```haxe
	var turn = Quaternion3D.fromAxisAngle(0, 1, 0, Math.PI / 2);
	var halfway = Quaternion3D.slerp(from, turn, .5);
	var facing = turn.transformPoint(0, 0, -1);
	``` */
class Quaternion3D {
	/** Gets or sets the quaternion's x, the axis's x scaled by the sine of half the angle. */
	public var x:Float;

	/** Gets or sets the quaternion's y. */
	public var y:Float;

	/** Gets or sets the quaternion's z. */
	public var z:Float;

	/** Gets or sets the quaternion's w, the cosine of half the angle. */
	public var w:Float;

	/** Creates a rotation, the identity unless the quaternion is provided.

		@param x  Optional. The quaternion's x; defaults to 0.
		@param y  Optional. The quaternion's y; defaults to 0.
		@param z  Optional. The quaternion's z; defaults to 0.
		@param w  Optional. The quaternion's w; defaults to 1. */
	public function new(x = 0., y = 0., z = 0., w = 1.) {
		set(x, y, z, w);
	}

	/** Returns a turn around an axis.

		An axis of length 0 makes the identity.
		@param axisX  The axis's x; it needn't be of length 1.
		@param axisY  The axis's y.
		@param axisZ  The axis's z.
		@param radians  The angle, counterclockwise looking down the axis toward the origin.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromAxisAngle(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Quaternion3D):Quaternion3D {
		var ax = real(axisX), ay = real(axisY), az = real(axisZ);
		var length = Math.sqrt(ax * ax + ay * ay + az * az);
		if (length == 0)
			return result(out, 0, 0, 0, 1);
		var half = real(radians) / 2, sin = Trig.sin(half) / length;
		return result(out, ax * sin, ay * sin, az * sin, Trig.cos(half));
	}

	/** Returns the rotation of three turns, around x, then y, then z, each around the world's axes.

		@param pitch  The turn around x, in radians.
		@param yaw  The turn around y, in radians.
		@param roll  The turn around z, in radians.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromEuler(pitch:Float, yaw:Float, roll:Float, ?out:Quaternion3D):Quaternion3D {
		var cx = Trig.cos(real(pitch) / 2),
			sx = Trig.sin(real(pitch) / 2),
			cy = Trig.cos(real(yaw) / 2),
			sy = Trig.sin(real(yaw) / 2),
			cz = Trig.cos(real(roll) / 2),
			sz = Trig.sin(real(roll) / 2);
		return result(out, sx * cy * cz - cx * sy * sz, cx * sy * cz + sx * cy * sz, cx * cy * sz - sx * sy * cz, cx * cy * cz + sx * sy * sz);
	}

	/** Returns the rotation that turns -z to face a direction, +y kept as near to up as it can be.

		A direction of length 0 makes the identity; an up along the direction is replaced by another axis.
		@param forwardX  The direction to face's x; it needn't be of length 1.
		@param forwardY  The direction's y.
		@param forwardZ  The direction's z.
		@param upX  Optional. Up's x; defaults to 0.
		@param upY  Optional. Up's y; defaults to 1.
		@param upZ  Optional. Up's z; defaults to 0.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromLookRotation(forwardX:Float, forwardY:Float, forwardZ:Float, upX = 0., upY = 1., upZ = 0., ?out:Quaternion3D):Quaternion3D {
		var fx = real(forwardX), fy = real(forwardY), fz = real(forwardZ);
		var length = Math.sqrt(fx * fx + fy * fy + fz * fz);
		if (length == 0)
			return result(out, 0, 0, 0, 1);
		// Its own axes: z the way back, x right, y up.
		var zx = -fx / length, zy = -fy / length, zz = -fz / length;
		var ux = real(upX), uy = real(upY), uz = real(upZ);
		var xx = uy * zz - uz * zy,
			xy = uz * zx - ux * zz,
			xz = ux * zy - uy * zx;
		length = Math.sqrt(xx * xx + xy * xy + xz * xz);
		if (length == 0) {
			// Up along the direction, or of length 0: +y, or facing straight up or down, the up a turn from level would give, -z below, +z above.
			if (zx == 0 && zz == 0) {
				ux = 0;
				uy = 0;
				uz = -zy;
			} else {
				ux = 0;
				uy = 1;
				uz = 0;
			}
			xx = uy * zz - uz * zy;
			xy = uz * zx - ux * zz;
			xz = ux * zy - uy * zx;
			length = Math.sqrt(xx * xx + xy * xy + xz * xz);
		}
		xx /= length;
		xy /= length;
		xz /= length;
		return fromBasis(xx, xy, xz, zy * xz - zz * xy, zz * xx - zx * xz, zx * xy - zy * xx, zx, zy, zz, out);
	}

	/** Returns the shortest turn from one direction to another.

		@param from  The first direction; it needn't be of length 1.
		@param to  The second direction.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromBetween(from:Vector3D, to:Vector3D, ?out:Quaternion3D):Quaternion3D {
		var ax = real(from.x),
			ay = real(from.y),
			az = real(from.z),
			bx = real(to.x),
			by = real(to.y),
			bz = real(to.z);
		var lengths = Math.sqrt((ax * ax + ay * ay + az * az) * (bx * bx + by * by + bz * bz));
		if (lengths == 0)
			return result(out, 0, 0, 0, 1);
		// Half way between the two, as a quaternion: their cross product and the product of their lengths plus their dot product.
		var cx = ay * bz - az * by,
			cy = az * bx - ax * bz,
			cz = ax * by - ay * bx,
			w = lengths + ax * bx + ay * by + az * bz;
		var length = Math.sqrt(cx * cx + cy * cy + cz * cz + w * w);
		if (length > lengths * 1e-12)
			return result(out, cx / length, cy / length, cz / length, w / length);
		// Opposite: a half turn around +y made square to the first, or around +x when the first is along y.
		var la = Math.sqrt(ax * ax + ay * ay + az * az);
		ax /= la;
		ay /= la;
		az /= la;
		var px = -ay * ax, py = 1 - ay * ay, pz = -ay * az;
		if (ax == 0 && az == 0) {
			px = 1;
			py = 0;
			pz = 0;
		}
		length = Math.sqrt(px * px + py * py + pz * pz);
		return result(out, px / length, py / length, pz / length, 0);
	}

	/** Returns the rotation of a matrix, its scale ignored.

		@param matrix  The matrix: a rotation, scale and translation.
		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public static function fromMatrix(matrix:Matrix3D, ?out:Quaternion3D):Quaternion3D {
		var v = matrix.values;
		var x = Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]),
			y = Math.sqrt(v[4] * v[4] + v[5] * v[5] + v[6] * v[6]),
			z = Math.sqrt(v[8] * v[8] + v[9] * v[9] + v[10] * v[10]);
		if (x == 0)
			x = 1;
		if (y == 0)
			y = 1;
		if (z == 0)
			z = 1;
		// A mirroring matrix has a scale less than 0, taken as its x's, so the way it faces and its up are kept.
		var determinant = v[0] * (v[5] * v[10] - v[6] * v[9]) - v[4] * (v[1] * v[10] - v[2] * v[9]) + v[8] * (v[1] * v[6] - v[2] * v[5]);
		if (determinant < 0)
			x = -x;
		var rotation = fromBasis(v[0] / x, v[1] / x, v[2] / x, v[4] / y, v[5] / y, v[6] / y, v[8] / z, v[9] / z, v[10] / z, out);
		return rotation.normalize(rotation);
	}

	/** Returns the rotation part way from one rotation to another along the shortest arc, at an even speed (slerp).

		@param from  The rotation at 0.
		@param to  The rotation at 1.
		@param amount  How far, 0 to 1; outside it the turn goes on past either end.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be from or to.
		@return  The rotation. */
	public static function slerp(from:Quaternion3D, to:Quaternion3D, amount:Float, ?out:Quaternion3D):Quaternion3D {
		var ax = real(from.x),
			ay = real(from.y),
			az = real(from.z),
			aw = real(from.w);
		var bx = real(to.x), by = real(to.y), bz = real(to.z), bw = real(to.w);
		var cos = ax * bx + ay * by + az * bz + aw * bw;
		// q and -q are the same rotation; the one nearer from is the shorter way.
		if (cos < 0) {
			cos = -cos;
			bx = -bx;
			by = -by;
			bz = -bz;
			bw = -bw;
		}
		var amount = real(amount);
		if (cos > 1 - 1e-9) {
			// So near that a straight line between them is the arc, to the last bit; and the sine below would be all rounding.
			if (out == null)
				out = new Quaternion3D();
			return out.set(ax + (bx - ax) * amount, ay + (by - ay) * amount, az + (bz - az) * amount, aw + (bw - aw) * amount).normalize(out);
		}
		var angle = Trig.acos(cos), sin = Trig.sin(angle);
		var a = Trig.sin((1 - amount) * angle) / sin,
			b = Trig.sin(amount * angle) / sin;
		return result(out, ax * a + bx * b, ay * a + by * b, az * a + bz * b, aw * a + bw * b);
	}

	/** Returns the rotation part way from one rotation to another along the shortest arc, faster than `slerp` but at an uneven speed
		(nlerp).

		@param from  The rotation at 0.
		@param to  The rotation at 1.
		@param amount  How far, 0 to 1.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be from or to.
		@return  The rotation. */
	public static function nlerp(from:Quaternion3D, to:Quaternion3D, amount:Float, ?out:Quaternion3D):Quaternion3D {
		var ax = real(from.x),
			ay = real(from.y),
			az = real(from.z),
			aw = real(from.w);
		var bx = real(to.x), by = real(to.y), bz = real(to.z), bw = real(to.w);
		if (ax * bx + ay * by + az * bz + aw * bw < 0) {
			bx = -bx;
			by = -by;
			bz = -bz;
			bw = -bw;
		}
		var amount = real(amount);
		if (out == null)
			out = new Quaternion3D();
		return out.set(ax + (bx - ax) * amount, ay + (by - ay) * amount, az + (bz - az) * amount, aw + (bw - aw) * amount).normalize(out);
	}

	/** Returns one rotation followed by another.

		@param first  The rotation applied first.
		@param second  The rotation applied after it.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be first or second.
		@return  The rotation. */
	public static function compose(first:Quaternion3D, second:Quaternion3D, ?out:Quaternion3D):Quaternion3D {
		// The Hamilton product second first: turning by it turns by first, then by second.
		var ax = real(second.x),
			ay = real(second.y),
			az = real(second.z),
			aw = real(second.w);
		var bx = real(first.x),
			by = real(first.y),
			bz = real(first.z),
			bw = real(first.w);
		return result(out, ax * bw
			+ aw * bx
			+ ay * bz
			- az * by, ay * bw
			+ aw * by
			+ az * bx
			- ax * bz, az * bw
			+ aw * bz
			+ ax * by
			- ay * bx,
			aw * bw
			- ax * bx
			- ay * by
			- az * bz);
	}

	/** Sets the quaternion's four numbers, as they are; `normalize` makes them a rotation if they aren't one.

		@param x  The x.
		@param y  The y.
		@param z  The z.
		@param w  The w.
		@return  This rotation. */
	public function set(x:Float, y:Float, z:Float, w:Float):Quaternion3D {
		this.x = real(x);
		this.y = real(y);
		this.z = real(z);
		this.w = real(w);
		return this;
	}

	/** Sets this rotation to another's.

		@param other  The rotation to copy.
		@return  This rotation. */
	public function copyFrom(other:Quaternion3D):Quaternion3D {
		return set(other.x, other.y, other.z, other.w);
	}

	/** Makes this the rotation that turns nothing.

		@return  This rotation. */
	public function makeIdentity():Quaternion3D {
		return set(0, 0, 0, 1);
	}

	/** Returns this rotation followed by another.

		@param other  The rotation applied after this one.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation or the other.
		@return  The rotation. */
	public function append(other:Quaternion3D, ?out:Quaternion3D):Quaternion3D {
		return compose(this, other, out);
	}

	/** Returns another rotation followed by this one.

		@param other  The rotation applied before this one.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation or the other.
		@return  The rotation. */
	public function prepend(other:Quaternion3D, ?out:Quaternion3D):Quaternion3D {
		return compose(other, this, out);
	}

	/** Returns the rotation that undoes this one.

		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation.
		@return  The inverse. */
	public function invert(?out:Quaternion3D):Quaternion3D {
		return result(out, -x, -y, -z, w);
	}

	/** Returns the quaternion scaled to length 1, so it is a rotation again after numbers set by hand or many compositions.

		A quaternion of length 0 gives the identity.
		@param out  Optional. The rotation to fill; a new one when omitted. It may be this rotation.
		@return  The rotation. */
	public function normalize(?out:Quaternion3D):Quaternion3D {
		var x = real(this.x),
			y = real(this.y),
			z = real(this.z),
			w = real(this.w);
		var length = Math.sqrt(x * x + y * y + z * z + w * w);
		return length == 0 ? result(out, 0, 0, 0, 1) : result(out, x / length, y / length, z / length, w / length);
	}

	/** Returns a point turned by this rotation.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The turned point. */
	public function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3D):Vector3D {
		var px = real(x), py = real(y), pz = real(z);
		var qx = this.x, qy = this.y, qz = this.z, qw = this.w;
		// p + 2w (q x p) + 2 q x (q x p), the quaternion's x, y and z as the vector q.
		var tx = 2 * (qy * pz - qz * py),
			ty = 2 * (qz * px - qx * pz),
			tz = 2 * (qx * py - qy * px);
		var rx = px + qw * tx + qy * tz - qz * ty,
			ry = py + qw * ty + qz * tx - qx * tz,
			rz = pz + qw * tz + qx * ty - qy * tx;
		return out == null ? new Vector3D(rx, ry, rz) : out.set(rx, ry, rz);
	}

	/** Returns the turns around x, y and z that `fromEuler` would make this from.

		The pitch and the roll are from -pi to pi, the yaw from -pi / 2 to pi / 2. At a yaw of a quarter turn either way, where the pitch
		and the roll turn around the same axis, the roll is 0 and the pitch carries the whole turn.
		@param out  Optional. The vector to write into: pitch in x, yaw in y, roll in z, in radians; a new one when omitted.
		@return  The angles. */
	public function toEuler(?out:Vector3D):Vector3D {
		var x = this.x, y = this.y, z = this.z, w = this.w;
		// The rotation's matrix, row then column, the parts the angles are read from.
		var m00 = 1 - 2 * (y * y + z * z),
			m10 = 2 * (x * y + w * z),
			m20 = 2 * (x * z - w * y),
			m21 = 2 * (y * z + w * x),
			m22 = 1 - 2 * (x * x + y * y);
		var cosYaw = Math.sqrt(m00 * m00 + m10 * m10);
		var yaw = Trig.atan2(-m20, cosYaw), pitch, roll;
		if (cosYaw < 1e-9) {
			// Yawed a quarter turn either way: pitch and roll turn around one axis, so the pitch takes the whole turn.
			var m01 = 2 * (x * y - w * z), m11 = 1 - 2 * (x * x + z * z);
			pitch = Trig.atan2(m20 < 0 ? m01 : -m01, m11);
			roll = 0.;
		} else {
			pitch = Trig.atan2(m21, m22);
			roll = Trig.atan2(m10, m00);
		}
		return out == null ? new Vector3D(pitch, yaw, roll) : out.set(pitch, yaw, roll);
	}

	/** Gets the angle this rotation turns by, around whatever axis, in radians, 0 to pi. */
	public var angle(get, never):Float;

	function get_angle():Float {
		return 2 * Trig.atan2(Math.sqrt(x * x + y * y + z * z), Math.abs(w));
	}

	/** Returns the rotation as a matrix.

		@param out  Optional. The matrix to write into; a new one when omitted.
		@return  The matrix. */
	public function toMatrix(?out:Matrix3D):Matrix3D {
		return Matrix3D.fromQuaternion(x, y, z, w, out);
	}

	// The rotation whose own x, y and z axes are these, each of length 1 and square to the others: raymath's QuaternionFromMatrix,
	// from the largest of the four parts, so none is found by dividing by a small one.
	static function fromBasis(xx:Float, xy:Float, xz:Float, yx:Float, yy:Float, yz:Float, zx:Float, zy:Float, zz:Float, ?out:Quaternion3D):Quaternion3D {
		var w4 = xx + yy + zz,
			x4 = xx - yy - zz,
			y4 = yy - xx - zz,
			z4 = zz - xx - yy;
		var largest = w4, index = 0;
		if (x4 > largest) {
			largest = x4;
			index = 1;
		}
		if (y4 > largest) {
			largest = y4;
			index = 2;
		}
		if (z4 > largest) {
			largest = z4;
			index = 3;
		}
		var value = Math.sqrt(largest + 1) / 2, mult = .25 / value;
		return switch index {
			case 0: result(out, (yz - zy) * mult, (zx - xz) * mult, (xy - yx) * mult, value);
			case 1: result(out, value, (xy + yx) * mult, (zx + xz) * mult, (yz - zy) * mult);
			case 2: result(out, (xy + yx) * mult, value, (yz + zy) * mult, (zx - xz) * mult);
			case _: result(out, (zx + xz) * mult, (yz + zy) * mult, value, (xy - yx) * mult);
		}
	}

	// The out filled with a result its inputs were read for first: a new rotation when there is none.
	static inline function result(out:Null<Quaternion3D>, x:Float, y:Float, z:Float, w:Float):Quaternion3D
		return out == null ? new Quaternion3D(x, y, z, w) : out.set(x, y, z, w);

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
