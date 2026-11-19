package helix.math;

/** Represents a 4 x 4 matrix transforming points in 3 dimensions: moving, turning, scaling and projecting them.

	It acts on column vectors, and its 16 numbers are `m0` to `m15` by columns, as GPUs read them: row r of column c is number
	c * 4 + r, and the translation is `m12`, `m13` and `m14`. `toArray` returns the 16 numbers a shader reads. A static
	`fromX` makes a matrix of one kind, and `compose` one transform followed by another. Each of those, and each operation on a matrix
	(`append`, `invert`, `transpose`, `transformPoint`), writes its result into an optional out, the last argument, and returns it.
	Without one it makes a new result and leaves this matrix unchanged; provided this matrix, it works in place (`m.transpose(m)`). The
	out may be this matrix or any other argument, and none of them allocates when provided one, so a caller can reuse one matrix every
	frame and chain calls through what each returns. `makeIdentity` and `copyFrom` change this matrix and return it. Rotations use
	`Trig`, so a matrix comes out the same on every target. The formulas are raymath's (raylib 5.5, zlib, `vendor/raylib/LICENSE`).

	```haxe
	var model = Matrix4.fromScale(2, 2, 2);
	model.appendRotation(0, 1, 0, angle, model).appendTranslation(x, 0, z, model);
	var mvp = Matrix4.compose(model, view).append(projection);
	``` */
class Matrix4 extends Matrix4Storage {
	/** Gets or sets the number in row 0 of column 0. */
	public var m0(get, set):Float;

	/** Gets or sets the number in row 1 of column 0. */
	public var m1(get, set):Float;

	/** Gets or sets the number in row 2 of column 0. */
	public var m2(get, set):Float;

	/** Gets or sets the number in row 3 of column 0. */
	public var m3(get, set):Float;

	/** Gets or sets the number in row 0 of column 1. */
	public var m4(get, set):Float;

	/** Gets or sets the number in row 1 of column 1. */
	public var m5(get, set):Float;

	/** Gets or sets the number in row 2 of column 1. */
	public var m6(get, set):Float;

	/** Gets or sets the number in row 3 of column 1. */
	public var m7(get, set):Float;

	/** Gets or sets the number in row 0 of column 2. */
	public var m8(get, set):Float;

	/** Gets or sets the number in row 1 of column 2. */
	public var m9(get, set):Float;

	/** Gets or sets the number in row 2 of column 2. */
	public var m10(get, set):Float;

	/** Gets or sets the number in row 3 of column 2. */
	public var m11(get, set):Float;

	/** Gets or sets the number in row 0 of column 3: the translation's x. */
	public var m12(get, set):Float;

	/** Gets or sets the number in row 1 of column 3: the translation's y. */
	public var m13(get, set):Float;

	/** Gets or sets the number in row 2 of column 3: the translation's z. */
	public var m14(get, set):Float;

	/** Gets or sets the number in row 3 of column 3. */
	public var m15(get, set):Float;

	/** Gets this matrix's determinant: 0 when the matrix has no inverse. */
	public var determinant(get, never):Float;

	/** Gets this matrix's trace: the sum of the four numbers on its diagonal. */
	public var trace(get, never):Float;

	/** Creates the identity matrix. */
	public function new() {
		start();
	}

	/** Makes this matrix the identity.

		@return  This matrix. */
	public function makeIdentity():Matrix4 {
		return set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
	}

	/** Sets this to another matrix's values.

		@param other  The matrix to copy.
		@return  This matrix. */
	public function copyFrom(other:Matrix4):Matrix4 {
		return set(other.n0, other.n1, other.n2, other.n3, other.n4, other.n5, other.n6, other.n7, other.n8, other.n9, other.n10, other.n11, other.n12,
			other.n13, other.n14, other.n15);
	}

	/** Returns the matrix of 16 numbers of an array, by columns.

		@param values  The array.
		@param offset  Optional. Where in the array the first of the 16 numbers is; defaults to 0.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromArray(values:Array<Float>, offset = 0, ?out:Matrix4):Matrix4 {
		if (out == null)
			out = new Matrix4();
		return out.set(values[offset], values[offset + 1], values[offset + 2], values[offset + 3], values[offset + 4], values[offset + 5], values[offset + 6],
			values[offset + 7], values[offset + 8], values[offset + 9], values[offset + 10], values[offset + 11], values[offset + 12], values[offset + 13],
			values[offset + 14], values[offset + 15]);
	}

	/** Returns a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromTranslation(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4 {
		if (out == null)
			out = new Matrix4();
		return out.set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1);
	}

	/** Returns a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromScale(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4 {
		if (out == null)
			out = new Matrix4();
		return out.set(x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1);
	}

	/** Returns a rotation about an axis, which needn't be of length 1.

		@param axisX  The axis's x.
		@param axisY  Its y.
		@param axisZ  Its z.
		@param radians  The angle, counterclockwise looking down the axis toward its origin.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Matrix4):Matrix4 {
		var x = axisX, y = axisY, z = axisZ, lengthSquared = x * x + y * y + z * z;
		if (lengthSquared != 1 && lengthSquared != 0) {
			var inverse = 1 / Math.sqrt(lengthSquared);
			x *= inverse;
			y *= inverse;
			z *= inverse;
		}
		var turn = Trig.turn(radians), s = turn.sin, c = turn.cos, t = 1 - c;
		if (out == null)
			out = new Matrix4();
		return out.set(x * x * t
			+ c, y * x * t
			+ z * s, z * x * t
			- y * s, 0, x * y * t
			- z * s, y * y * t
			+ c, z * y * t
			+ x * s, 0, x * z * t
			+ y * s,
			y * z * t
			- x * s, z * z * t
			+ c, 0, 0, 0, 0, 1);
	}

	/** Returns the rotation a quaternion (x, y, z, w) describes.

		@param x  The quaternion's x.
		@param y  Its y.
		@param z  Its z.
		@param w  Its w.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromQuaternion(x:Float, y:Float, z:Float, w:Float, ?out:Matrix4):Matrix4 {
		var a2 = x * x, b2 = y * y, c2 = z * z, ac = x * z, ab = x * y, bc = y * z, ad = w * x, bd = w * y, cd = w * z;
		if (out == null)
			out = new Matrix4();
		return out.set(1
			- 2 * (b2 + c2), 2 * (ab + cd), 2 * (ac - bd), 0, 2 * (ab - cd), 1
			- 2 * (a2 + c2), 2 * (bc + ad), 0, 2 * (ac + bd), 2 * (bc - ad),
			1
			- 2 * (a2 + b2), 0, 0, 0, 0, 1);
	}

	/** Returns the rotation of three turns around x, y and z, each around the world's axes. `Quaternion.fromEuler` returns the same
		rotation as a quaternion.

		@param pitch  The turn around x, in radians.
		@param yaw  The turn around y, in radians.
		@param roll  The turn around z, in radians.
		@param order  Optional. The order the turns are made in; defaults to `ZYX`: around x, then y, then z.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromEuler(pitch:Float, yaw:Float, roll:Float, order = EulerOrder.ZYX, ?out:Matrix4):Matrix4 {
		var x = Trig.turn(pitch), y = Trig.turn(yaw), z = Trig.turn(roll);
		var cx = x.cos, sx = x.sin, cy = y.cos, sy = y.sin, cz = z.cos, sz = z.sin;
		if (out == null)
			out = new Matrix4();
		// Each the product of the three turns' matrices in the order's letters, by columns.
		return switch order {
			case ZYX:
				out.set(cz * cy, sz * cy,
					-sy, 0, cz * sy * sx
					- sz * cx, sz * sy * sx
					+ cz * cx, cy * sx, 0, cz * sy * cx
					+ sz * sx, sz * sy * cx
					- cz * sx,
					cy * cx, 0, 0, 0, 0, 1);
			case XYZ:
				out.set(cy * cz, cx * sz
					+ sx * cz * sy, sx * sz
					- cx * cz * sy, 0,
					-cy * sz, cx * cz
					- sx * sz * sy, sx * cz
					+ cx * sz * sy, 0, sy,
					-sx * cy,
					cx * cy, 0, 0, 0, 0, 1);
			case YXZ:
				out.set(cy * cz
					+ sy * sz * sx, cx * sz, cy * sz * sx
					- sy * cz, 0, sy * cz * sx
					- cy * sz, cx * cz, sy * sz
					+ cy * cz * sx, 0, cx * sy,
					-sx,
					cx * cy, 0, 0, 0, 0, 1);
			case ZXY:
				out.set(cy * cz
					- sy * sz * sx, cy * sz
					+ sy * cz * sx,
					-cx * sy, 0,
					-cx * sz, cx * cz, sx, 0, sy * cz
					+ cy * sz * sx, sy * sz
					- cy * cz * sx,
					cx * cy, 0, 0, 0, 0, 1);
			case YZX:
				out.set(cy * cz, sz,
					-sy * cz, 0, sx * sy
					- cx * cy * sz, cx * cz, cx * sy * sz
					+ sx * cy, 0, sx * cy * sz
					+ cx * sy,
					-sx * cz,
					cx * cy
					- sx * sy * sz, 0, 0, 0, 0, 1);
			case XZY:
				out.set(cy * cz, cx * cy * sz
					+ sx * sy, sx * cy * sz
					- cx * sy, 0,
					-sz, cx * cz, sx * cz, 0, sy * cz, cx * sy * sz
					- sx * cy,
					sx * sy * sz
					+ cx * cy, 0, 0, 0, 0, 1);
		}
	}

	/** Returns a view from an eye looking at a target.

		@param eyeX  Where it looks from.
		@param eyeY  Where it looks from.
		@param eyeZ  Where it looks from.
		@param targetX  What it looks at.
		@param targetY  What it looks at.
		@param targetZ  What it looks at.
		@param upX  Up.
		@param upY  Up.
		@param upZ  Up.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromLookAt(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX:Float, upY:Float, upZ:Float,
			?out:Matrix4):Matrix4 {
		var zx = eyeX - targetX, zy = eyeY - targetY, zz = eyeZ - targetZ;
		var length = Math.sqrt(zx * zx + zy * zy + zz * zz);
		if (length == 0)
			length = 1;
		zx /= length;
		zy /= length;
		zz /= length;
		var xx = upY * zz - upZ * zy,
			xy = upZ * zx - upX * zz,
			xz = upX * zy - upY * zx;
		length = Math.sqrt(xx * xx + xy * xy + xz * xz);
		if (length == 0)
			length = 1;
		xx /= length;
		xy /= length;
		xz /= length;
		var yx = zy * xz - zz * xy,
			yy = zz * xx - zx * xz,
			yz = zx * xy - zy * xx;
		if (out == null)
			out = new Matrix4();
		return out.set(xx, yx, zx, 0, xy, yy, zy, 0, xz, yz, zz, 0,
			-(xx * eyeX + xy * eyeY + xz * eyeZ),
			-(yx * eyeX + yy * eyeY + yz * eyeZ),
			-(zx * eyeX + zy * eyeY + zz * eyeZ), 1);
	}

	/** Returns a perspective projection into GL's clip space (depth -1 to 1), which every helix-platform adapter uses.

		@param fovY  The field of view, top to bottom, in radians.
		@param aspect  Width over height.
		@param near  The near plane's distance.
		@param far  The far plane's distance.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromPerspective(fovY:Float, aspect:Float, near:Float, far:Float, ?out:Matrix4):Matrix4 {
		var top = near * Trig.tan(fovY * .5),
			right = top * aspect,
			depth = far - near;
		if (out == null)
			out = new Matrix4();
		return out.set(near / right, 0, 0, 0, 0, near / top, 0, 0, 0, 0, -(far + near) / depth, -1, 0, 0, -(far * near * 2) / depth, 0);
	}

	/** Returns an orthographic projection into GL's clip space (depth -1 to 1), which every helix-platform adapter uses.

		@param left  The left edge.
		@param right  The right edge.
		@param bottom  The bottom edge.
		@param top  The top edge.
		@param near  The near plane's distance.
		@param far  The far plane's distance.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromOrthographic(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, ?out:Matrix4):Matrix4 {
		var width = right - left, height = top - bottom, depth = far - near;
		if (out == null)
			out = new Matrix4();
		return out.set(2 / width, 0, 0, 0, 0, 2 / height, 0, 0, 0, 0, -2 / depth, 0,
			-(left + right) / width,
			-(top + bottom) / height,
			-(far + near) / depth,
			1);
	}

	/** Returns a perspective projection into GL's clip space (depth -1 to 1) by its near plane's edges, which may be off center.

		@param left  The near plane's left edge.
		@param right  Its right edge.
		@param bottom  Its bottom edge.
		@param top  Its top edge.
		@param near  The near plane's distance.
		@param far  The far plane's distance.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	public static function fromFrustum(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, ?out:Matrix4):Matrix4 {
		var width = right - left, height = top - bottom, depth = far - near;
		if (out == null)
			out = new Matrix4();
		return out.set(near * 2 / width, 0, 0, 0, 0, near * 2 / height, 0, 0, (right + left) / width, (top + bottom) / height, -(far + near) / depth, -1, 0,
			0, -(far * near * 2) / depth, 0);
	}

	/** Returns one transform followed by another.

		@param first  The transform applied first.
		@param second  The transform applied after it.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be first or second.
		@return  The matrix. */
	public static function compose(first:Matrix4, second:Matrix4, ?out:Matrix4):Matrix4 {
		if (out == null)
			out = new Matrix4();
		// Each number of the product is read from the two before any is written, so either matrix may be the out.
		var a = first, b = second;
		var m0 = a.n0 * b.n0 + a.n1 * b.n4 + a.n2 * b.n8 + a.n3 * b.n12;
		var m1 = a.n0 * b.n1 + a.n1 * b.n5 + a.n2 * b.n9 + a.n3 * b.n13;
		var m2 = a.n0 * b.n2 + a.n1 * b.n6 + a.n2 * b.n10 + a.n3 * b.n14;
		var m3 = a.n0 * b.n3 + a.n1 * b.n7 + a.n2 * b.n11 + a.n3 * b.n15;
		var m4 = a.n4 * b.n0 + a.n5 * b.n4 + a.n6 * b.n8 + a.n7 * b.n12;
		var m5 = a.n4 * b.n1 + a.n5 * b.n5 + a.n6 * b.n9 + a.n7 * b.n13;
		var m6 = a.n4 * b.n2 + a.n5 * b.n6 + a.n6 * b.n10 + a.n7 * b.n14;
		var m7 = a.n4 * b.n3 + a.n5 * b.n7 + a.n6 * b.n11 + a.n7 * b.n15;
		var m8 = a.n8 * b.n0 + a.n9 * b.n4 + a.n10 * b.n8 + a.n11 * b.n12;
		var m9 = a.n8 * b.n1 + a.n9 * b.n5 + a.n10 * b.n9 + a.n11 * b.n13;
		var m10 = a.n8 * b.n2 + a.n9 * b.n6 + a.n10 * b.n10 + a.n11 * b.n14;
		var m11 = a.n8 * b.n3 + a.n9 * b.n7 + a.n10 * b.n11 + a.n11 * b.n15;
		var m12 = a.n12 * b.n0 + a.n13 * b.n4 + a.n14 * b.n8 + a.n15 * b.n12;
		var m13 = a.n12 * b.n1 + a.n13 * b.n5 + a.n14 * b.n9 + a.n15 * b.n13;
		var m14 = a.n12 * b.n2 + a.n13 * b.n6 + a.n14 * b.n10 + a.n15 * b.n14;
		var m15 = a.n12 * b.n3 + a.n13 * b.n7 + a.n14 * b.n11 + a.n15 * b.n15;
		return out.set(m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15);
	}

	/** Returns this transform followed by another.

		@param other  The transform applied after this one.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
		@return  The matrix. */
	public function append(other:Matrix4, ?out:Matrix4):Matrix4 {
		return compose(this, other, out);
	}

	/** Returns another transform followed by this one.

		@param other  The transform applied before this one.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
		@return  The matrix. */
	public function prepend(other:Matrix4, ?out:Matrix4):Matrix4 {
		return compose(other, this, out);
	}

	/** Returns this transform followed by a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix.
		@return  The matrix. */
	public function appendTranslation(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4 {
		out = copied(out);
		out.n12 += out.n15 * x;
		out.n13 += out.n15 * y;
		out.n14 += out.n15 * z;
		out.n0 += out.n3 * x;
		out.n1 += out.n3 * y;
		out.n2 += out.n3 * z;
		out.n4 += out.n7 * x;
		out.n5 += out.n7 * y;
		out.n6 += out.n7 * z;
		out.n8 += out.n11 * x;
		out.n9 += out.n11 * y;
		out.n10 += out.n11 * z;
		return out;
	}

	/** Returns this transform followed by a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix.
		@return  The matrix. */
	public function appendScale(x:Float, y:Float, z:Float, ?out:Matrix4):Matrix4 {
		out = copied(out);
		out.n0 *= x;
		out.n1 *= y;
		out.n2 *= z;
		out.n4 *= x;
		out.n5 *= y;
		out.n6 *= z;
		out.n8 *= x;
		out.n9 *= y;
		out.n10 *= z;
		out.n12 *= x;
		out.n13 *= y;
		out.n14 *= z;
		return out;
	}

	/** Returns this transform followed by a rotation about an axis.

		@param axisX  The axis's x.
		@param axisY  Its y.
		@param axisZ  Its z.
		@param radians  The angle, counterclockwise looking down the axis toward its origin.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix.
		@return  The matrix. */
	public function appendRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float, ?out:Matrix4):Matrix4 {
		return compose(this, fromRotation(axisX, axisY, axisZ, radians, shared()), out);
	}

	/** Returns the inverse of this matrix: the transform that undoes it.

		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix.
		@return  The inverse, or null, leaving out unchanged and making nothing, when this matrix has no inverse. */
	public function invert(?out:Matrix4):Null<Matrix4> {
		var m = this;
		var a00 = m.n0, a01 = m.n1, a02 = m.n2, a03 = m.n3, a10 = m.n4, a11 = m.n5, a12 = m.n6, a13 = m.n7;
		var a20 = m.n8, a21 = m.n9, a22 = m.n10, a23 = m.n11, a30 = m.n12, a31 = m.n13, a32 = m.n14, a33 = m.n15;
		var b00 = a00 * a11 - a01 * a10,
			b01 = a00 * a12 - a02 * a10,
			b02 = a00 * a13 - a03 * a10,
			b03 = a01 * a12 - a02 * a11;
		var b04 = a01 * a13 - a03 * a11,
			b05 = a02 * a13 - a03 * a12,
			b06 = a20 * a31 - a21 * a30,
			b07 = a20 * a32 - a22 * a30;
		var b08 = a20 * a33 - a23 * a30,
			b09 = a21 * a32 - a22 * a31,
			b10 = a21 * a33 - a23 * a31,
			b11 = a22 * a33 - a23 * a32;
		var determinant = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
		if (determinant == 0)
			return null;
		var d = 1 / determinant;
		if (out == null)
			out = new Matrix4();
		return out.set((a11 * b11 - a12 * b10 + a13 * b09) * d, (-a01 * b11 + a02 * b10 - a03 * b09) * d, (a31 * b05 - a32 * b04 + a33 * b03) * d,
			(-a21 * b05 + a22 * b04 - a23 * b03) * d, (-a10 * b11 + a12 * b08 - a13 * b07) * d, (a00 * b11 - a02 * b08 + a03 * b07) * d,
			(-a30 * b05 + a32 * b02 - a33 * b01) * d, (a20 * b05 - a22 * b02 + a23 * b01) * d, (a10 * b10 - a11 * b08 + a13 * b06) * d,
			(-a00 * b10 + a01 * b08 - a03 * b06) * d, (a30 * b04 - a31 * b02 + a33 * b00) * d, (-a20 * b04 + a21 * b02 - a23 * b00) * d,
			(-a10 * b09 + a11 * b07 - a12 * b06) * d, (a00 * b09 - a01 * b07 + a02 * b06) * d, (-a30 * b03 + a31 * b01 - a32 * b00) * d,
			(a20 * b03 - a21 * b01 + a22 * b00) * d);
	}

	/** Returns this matrix transposed: its rows made columns.

		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix.
		@return  The transpose. */
	public function transpose(?out:Matrix4):Matrix4 {
		if (out == null)
			out = new Matrix4();
		return out.set(n0, n4, n8, n12, n1, n5, n9, n13, n2, n6, n10, n14, n3, n7, n11, n15);
	}

	/** Returns this matrix plus another, number by number.

		@param other  The matrix to add.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
		@return  The sum. */
	public function add(other:Matrix4, ?out:Matrix4):Matrix4 {
		if (out == null)
			out = new Matrix4();
		return out.set(n0
			+ other.n0, n1
			+ other.n1, n2
			+ other.n2, n3
			+ other.n3, n4
			+ other.n4, n5
			+ other.n5, n6
			+ other.n6, n7
			+ other.n7, n8
			+ other.n8,
			n9
			+ other.n9, n10
			+ other.n10, n11
			+ other.n11, n12
			+ other.n12, n13
			+ other.n13, n14
			+ other.n14, n15
			+ other.n15);
	}

	/** Returns this matrix less another, number by number.

		@param other  The matrix to subtract.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be this matrix or the other.
		@return  The difference. */
	public function subtract(other:Matrix4, ?out:Matrix4):Matrix4 {
		if (out == null)
			out = new Matrix4();
		return out.set(n0
			- other.n0, n1
			- other.n1, n2
			- other.n2, n3
			- other.n3, n4
			- other.n4, n5
			- other.n5, n6
			- other.n6, n7
			- other.n7, n8
			- other.n8,
			n9
			- other.n9, n10
			- other.n10, n11
			- other.n11, n12
			- other.n12, n13
			- other.n13, n14
			- other.n14, n15
			- other.n15);
	}

	/** Computes where a point goes, translation included.

		@param x  The point's x.
		@param y  Its y.
		@param z  Its z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point. */
	public function transformPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3 {
		var m = this;
		if (out == null)
			out = new Vector3();
		return out.set(m.n0 * x + m.n4 * y + m.n8 * z + m.n12, m.n1 * x + m.n5 * y + m.n9 * z + m.n13, m.n2 * x + m.n6 * y + m.n10 * z + m.n14);
	}

	/** Computes where a direction goes, translation left out.

		@param x  The direction's x.
		@param y  Its y.
		@param z  Its z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The direction. */
	public function transformDirection(x:Float, y:Float, z:Float, ?out:Vector3):Vector3 {
		var m = this;
		if (out == null)
			out = new Vector3();
		return out.set(m.n0 * x + m.n4 * y + m.n8 * z, m.n1 * x + m.n5 * y + m.n9 * z, m.n2 * x + m.n6 * y + m.n10 * z);
	}

	/** Computes where a point goes through a projection: transformed, then divided by the w the matrix produces for the point.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The point. */
	public function projectPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3 {
		var m = this, w = m.n3 * x + m.n7 * y + m.n11 * z + m.n15;
		if (out == null)
			out = new Vector3();
		return out.set((m.n0 * x + m.n4 * y + m.n8 * z + m.n12) / w, (m.n1 * x + m.n5 * y + m.n9 * z + m.n13) / w,
			(m.n2 * x + m.n6 * y + m.n10 * z + m.n14) / w);
	}

	/** Returns the matrix's 16 numbers as an array, by columns, as a shader reads them.

		@param out  Optional. The array to fill; a new one when omitted.
		@param offset  Optional. Where in the array the first of the 16 numbers goes; defaults to 0.
		@return  The array. */
	public function toArray(?out:Array<Float>, offset = 0):Array<Float> {
		if (out == null) {
			if (offset == 0)
				return [n0, n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12, n13, n14, n15];
			out = [for (_ in 0...offset) 0.];
		}
		out[offset] = n0;
		out[offset + 1] = n1;
		out[offset + 2] = n2;
		out[offset + 3] = n3;
		out[offset + 4] = n4;
		out[offset + 5] = n5;
		out[offset + 6] = n6;
		out[offset + 7] = n7;
		out[offset + 8] = n8;
		out[offset + 9] = n9;
		out[offset + 10] = n10;
		out[offset + 11] = n11;
		out[offset + 12] = n12;
		out[offset + 13] = n13;
		out[offset + 14] = n14;
		out[offset + 15] = n15;
		return out;
	}

	/** Returns the matrix's translation.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The translation. */
	public function getTranslation(?out:Vector3):Vector3 {
		if (out == null)
			out = new Vector3();
		return out.set(n12, n13, n14);
	}

	/** Returns the matrix's rotation, its scale and translation left out.

		A matrix that mirrors is treated as mirrored along x, so the way it faces and its up are kept. See `decompose` for a matrix that
		shears.

		@param out  Optional. The rotation to fill; a new one when omitted.
		@return  The rotation. */
	public function getRotation(?out:Quaternion):Quaternion {
		var xx = n0, xy = n1, xz = n2, yx = n4, yy = n5, yz = n6, zx = n8, zy = n9, zz = n10;
		var x = Math.sqrt(xx * xx + xy * xy + xz * xz),
			y = Math.sqrt(yx * yx + yy * yy + yz * yz),
			z = Math.sqrt(zx * zx + zy * zy + zz * zz);
		if (x == 0)
			x = 1;
		if (y == 0)
			y = 1;
		if (z == 0)
			z = 1;
		if (xx * (yy * zz - yz * zy) - yx * (xy * zz - xz * zy) + zx * (xy * yz - xz * yy) < 0)
			x = -x;
		var rotation = Quaternion.fromBasis(xx / x, xy / x, xz / x, yx / y, yy / y, yz / y, zx / z, zy / z, zz / z, out);
		return rotation.normalize(rotation);
	}

	/** Returns the matrix's scale: the lengths of its x, y and z axes.

		A matrix that mirrors produces an x scale less than 0. See `decompose` for a matrix that shears.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The scale along x, y and z. */
	public function getScale(?out:Vector3):Vector3 {
		var xx = real(n0), xy = real(n1), xz = real(n2), yx = real(n4), yy = real(n5), yz = real(n6);
		var zx = real(n8), zy = real(n9), zz = real(n10);
		var x = Math.sqrt(xx * xx + xy * xy + xz * xz);
		if (xx * (yy * zz - yz * zy) - yx * (xy * zz - xz * zy) + zx * (xy * yz - xz * yy) < 0)
			x = -x;
		if (out == null)
			out = new Vector3();
		return out.set(x, Math.sqrt(yx * yx + yy * yy + yz * yz), Math.sqrt(zx * zx + zy * zy + zz * zz));
	}

	/** Decomposes this transform into a translation, a rotation and a scale.

		A matrix that shears produces the nearest rotation (its polar decomposition's) and the scale along that rotation's axes, the
		shear lost. One that mirrors produces an x scale less than 0, so the way it faces and its up are kept.

		@param translation  Filled with the translation.
		@param rotation  Filled with the rotation.
		@param scale  Filled with the scale along x, y and z. */
	public function decompose(translation:Vector3, rotation:Quaternion, scale:Vector3):Void {
		var v = this;
		var xx = real(v.n0),
			xy = real(v.n1),
			xz = real(v.n2),
			yx = real(v.n4),
			yy = real(v.n5),
			yz = real(v.n6);
		var zx = real(v.n8), zy = real(v.n9), zz = real(v.n10);
		var x = Math.sqrt(xx * xx + xy * xy + xz * xz),
			y = Math.sqrt(yx * yx + yy * yy + yz * yz),
			z = Math.sqrt(zx * zx + zy * zy + zz * zz);
		// Columns square to one another (no shear, but for rounding) are the rotation's axes as they are, their lengths the scale.
		if (x > 0
			&& y > 0
			&& z > 0
			&& x < Math.POSITIVE_INFINITY
			&& y < Math.POSITIVE_INFINITY
			&& z < Math.POSITIVE_INFINITY
			&& Math.abs(xx * yx + xy * yy + xz * yz) <= 1e-12 * x * y
			&& Math.abs(yx * zx + yy * zy + yz * zz) <= 1e-12 * y * z
			&& Math.abs(zx * xx + zy * xy + zz * xz) <= 1e-12 * z * x) {
			var mirrored = xx * (yy * zz - yz * zy) - yx * (xy * zz - xz * zy) + zx * (xy * yz - xz * yy) < 0;
			translation.set(v.n12, v.n13, v.n14);
			getRotation(rotation);
			scale.set(mirrored ? -x : x, y, z);
			return;
		}
		var m = [xx, xy, xz, yx, yy, yz, zx, zy, zz];
		var u = nearestRotation(m);
		var rotationMatrix = shared().set(u[0], u[1], u[2], 0, u[3], u[4], u[5], 0, u[6], u[7], u[8], 0, 0, 0, 0, 1);
		translation.set(v.n12, v.n13, v.n14);
		rotationMatrix.getRotation(rotation);
		scale.set(u[0] * m[0] + u[1] * m[1] + u[2] * m[2], u[3] * m[3] + u[4] * m[4] + u[5] * m[5], u[6] * m[6] + u[7] * m[7] + u[8] * m[8]);
	}

	function get_determinant():Float {
		var m = this;
		var a00 = m.n0, a01 = m.n1, a02 = m.n2, a03 = m.n3, a10 = m.n4, a11 = m.n5, a12 = m.n6, a13 = m.n7;
		var a20 = m.n8, a21 = m.n9, a22 = m.n10, a23 = m.n11, a30 = m.n12, a31 = m.n13, a32 = m.n14, a33 = m.n15;
		return (a00 * a11 - a01 * a10) * (a22 * a33 - a23 * a32) - (a00 * a12 - a02 * a10) * (a21 * a33 - a23 * a31)
			+ (a00 * a13 - a03 * a10) * (a21 * a32 - a22 * a31) + (a01 * a12 - a02 * a11) * (a20 * a33 - a23 * a30)
			- (a01 * a13 - a03 * a11) * (a20 * a32 - a22 * a30) + (a02 * a13 - a03 * a12) * (a20 * a31 - a21 * a30);
	}

	function get_trace():Float {
		var m = this;
		return m.n0 + m.n5 + m.n10 + m.n15;
	}

	inline function get_m0():Float
		return n0;

	inline function set_m0(value:Float):Float
		return n0 = value;

	inline function get_m1():Float
		return n1;

	inline function set_m1(value:Float):Float
		return n1 = value;

	inline function get_m2():Float
		return n2;

	inline function set_m2(value:Float):Float
		return n2 = value;

	inline function get_m3():Float
		return n3;

	inline function set_m3(value:Float):Float
		return n3 = value;

	inline function get_m4():Float
		return n4;

	inline function set_m4(value:Float):Float
		return n4 = value;

	inline function get_m5():Float
		return n5;

	inline function set_m5(value:Float):Float
		return n5 = value;

	inline function get_m6():Float
		return n6;

	inline function set_m6(value:Float):Float
		return n6 = value;

	inline function get_m7():Float
		return n7;

	inline function set_m7(value:Float):Float
		return n7 = value;

	inline function get_m8():Float
		return n8;

	inline function set_m8(value:Float):Float
		return n8 = value;

	inline function get_m9():Float
		return n9;

	inline function set_m9(value:Float):Float
		return n9 = value;

	inline function get_m10():Float
		return n10;

	inline function set_m10(value:Float):Float
		return n10 = value;

	inline function get_m11():Float
		return n11;

	inline function set_m11(value:Float):Float
		return n11 = value;

	inline function get_m12():Float
		return n12;

	inline function set_m12(value:Float):Float
		return n12 = value;

	inline function get_m13():Float
		return n13;

	inline function set_m13(value:Float):Float
		return n13 = value;

	inline function get_m14():Float
		return n14;

	inline function set_m14(value:Float):Float
		return n14 = value;

	inline function get_m15():Float
		return n15;

	inline function set_m15(value:Float):Float
		return n15 = value;

	// The out, a new matrix when there is none, holding this matrix's values, for an operation that then changes it where it is.
	function copied(out:Null<Matrix4>):Matrix4 {
		if (out == null)
			out = new Matrix4();
		return out == this ? out : out.copyFrom(this);
	}

	function set(a0:Float, a1:Float, a2:Float, a3:Float, a4:Float, a5:Float, a6:Float, a7:Float, a8:Float, a9:Float, a10:Float, a11:Float, a12:Float,
			a13:Float, a14:Float, a15:Float):Matrix4 {
		n0 = a0;
		n1 = a1;
		n2 = a2;
		n3 = a3;
		n4 = a4;
		n5 = a5;
		n6 = a6;
		n7 = a7;
		n8 = a8;
		n9 = a9;
		n10 = a10;
		n11 = a11;
		n12 = a12;
		n13 = a13;
		n14 = a14;
		n15 = a15;
		return this;
	}

	// A matrix appendRotation turns into, reused.
	static var rotation:Null<Matrix4> = null;

	static function shared():Matrix4 {
		if (rotation == null)
			rotation = new Matrix4();
		return rotation;
	}

	// The rotation nearest a 3 x 3 matrix, by columns, as 9 numbers by columns: its polar decomposition, by Newton's iteration (scaled,
	// so a matrix scaled very unevenly needs few steps), a mirror removed from its x axis. A matrix that flattens has none of its own,
	// so its columns are made square to one another, longest first, and an axis it lacks is the cross product of the others.
	static function nearestRotation(m:Array<Float>):Array<Float> {
		var u = m.copy();
		var determinant = cofactors(u, cofactor);
		var flat = determinant == 0 || !Math.isFinite(determinant);
		if (!flat) {
			for (_ in 0...100) {
				var size = 0., inverseSize = 0.;
				for (i in 0...9) {
					size += u[i] * u[i];
					inverseSize += cofactor[i] * cofactor[i];
				}
				var gamma = Math.sqrt(Math.sqrt(inverseSize) / Math.abs(determinant) / Math.sqrt(size));
				var change = 0.;
				for (i in 0...9) {
					var next = (gamma * u[i] + cofactor[i] / (gamma * determinant)) / 2;
					change = Math.max(change, Math.abs(next - u[i]));
					u[i] = next;
				}
				if (change < 1e-15)
					break;
				determinant = cofactors(u, cofactor);
				if (determinant == 0 || !Math.isFinite(determinant)) {
					flat = true;
					break;
				}
			}
			if (!flat
				&& (m[0] * (m[4] * m[8] - m[5] * m[7]) - m[3] * (m[1] * m[8] - m[2] * m[7]) + m[6] * (m[1] * m[5] - m[2] * m[4])) < 0)
				for (i in 0...3)
					u[i] = -u[i];
		}
		if (flat) {
			u = m.copy();
			var lengths = [
				for (c in 0...3)
					Math.sqrt(u[c * 3] * u[c * 3] + u[c * 3 + 1] * u[c * 3 + 1] + u[c * 3 + 2] * u[c * 3 + 2])
			];
			var order = [0, 1, 2];
			order.sort((p, q) -> lengths[p] > lengths[q] ? -1 : lengths[p] < lengths[q] ? 1 : p - q);
			var first = order[0] * 3, second = order[1] * 3, third = order[2];
			if (lengths[order[0]] == 0) {
				u = [1., 0., 0., 0., 1., 0., 0., 0., 1.];
				return u;
			}
			for (i in 0...3)
				u[first + i] /= lengths[order[0]];
			var dot = u[first] * u[second] + u[first + 1] * u[second + 1] + u[first + 2] * u[second + 2];
			for (i in 0...3)
				u[second + i] -= dot * u[first + i];
			var length = Math.sqrt(u[second] * u[second] + u[second + 1] * u[second + 1] + u[second + 2] * u[second + 2]);
			if (length < 1e-12) {
				// Square to the first: the world axis it lies least along, its part along the first removed.
				var ax = Math.abs(u[first]),
					ay = Math.abs(u[first + 1]),
					az = Math.abs(u[first + 2]);
				var pick = ax <= ay && ax <= az ? 0 : ay <= az ? 1 : 2;
				for (i in 0...3)
					u[second + i] = (i == pick ? 1 : 0) - u[first + pick] * u[first + i];
				length = Math.sqrt(u[second] * u[second] + u[second + 1] * u[second + 1] + u[second + 2] * u[second + 2]);
			}
			for (i in 0...3)
				u[second + i] /= length;
			// Right-handed: each axis the cross product of the next two.
			var p = ((third + 1) % 3) * 3, q = ((third + 2) % 3) * 3, r = third * 3;
			u[r] = u[p + 1] * u[q + 2] - u[p + 2] * u[q + 1];
			u[r + 1] = u[p + 2] * u[q] - u[p] * u[q + 2];
			u[r + 2] = u[p] * u[q + 1] - u[p + 1] * u[q];
		}
		return u;
	}

	// The matrix's inverse transposed times its determinant, into out: each column the cross product of the other two. Returns the
	// determinant.
	static function cofactors(u:Array<Float>, out:Array<Float>):Float {
		for (c in 0...3) {
			var p = ((c + 1) % 3) * 3, q = ((c + 2) % 3) * 3;
			out[c * 3] = u[p + 1] * u[q + 2] - u[p + 2] * u[q + 1];
			out[c * 3 + 1] = u[p + 2] * u[q] - u[p] * u[q + 2];
			out[c * 3 + 2] = u[p] * u[q + 1] - u[p + 1] * u[q];
		}
		return u[0] * out[0] + u[1] * out[1] + u[2] * out[2];
	}

	static final cofactor:Array<Float> = [for (_ in 0...9) 0.];

	// The interpreter keeps an Int passed for a Float as an Int and multiplies two such as Ints, overflowing; dividing makes it a Float.
	static inline function real(value:Float):Float {
		#if eval
		return value / 1;
		#else
		return value;
		#end
	}
}
