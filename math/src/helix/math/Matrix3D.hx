package helix.math;

/** Represents a 4 x 4 matrix transforming points in 3 dimensions: moving, turning, scaling and projecting them.

	It acts on column vectors and is stored by columns, as GPUs take it, so `values` can be sent to a shader as they are. A method that
	makes or changes a matrix changes this one and returns it, so a caller can reuse one every frame; one that computes a point writes it
	into the point given. Rotations use `Trig`, so a matrix comes out the same on every target. The formulas are raymath's (raylib 5.5,
	zlib, `vendor/raylib/LICENSE`).

	```haxe
	var model = new Matrix3D().makeScale(2, 2, 2).appendRotation(0, 1, 0, angle).appendTranslation(x, 0, z);
	var mvp = new Matrix3D().copyFrom(model).append(view).append(projection);
	``` */
class Matrix3D {
	/** Gets the 16 numbers, by columns: row r of column c at `values[c * 4 + r]`; the translation at 12, 13 and 14. */
	public final values:Array<Float> = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

	/** Creates the identity matrix. */
	public function new() {}

	/** Makes this the identity.

		@return  This matrix. */
	public function makeIdentity():Matrix3D {
		return set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
	}

	/** Sets this to another matrix's values.

		@param other  The matrix to copy.
		@return  This matrix. */
	public function copyFrom(other:Matrix3D):Matrix3D {
		for (i in 0...16)
			values[i] = other.values[i];
		return this;
	}

	/** Makes this a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  This matrix. */
	public function makeTranslation(x:Float, y:Float, z:Float):Matrix3D {
		return set(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1);
	}

	/** Makes this a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  This matrix. */
	public function makeScale(x:Float, y:Float, z:Float):Matrix3D {
		return set(x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1);
	}

	/** Makes this a rotation about an axis, which needn't be of length 1.

		@param axisX  The axis's x.
		@param axisY  Its y.
		@param axisZ  Its z.
		@param radians  The angle, counterclockwise looking down the axis toward its origin.
		@return  This matrix. */
	public function makeRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float):Matrix3D {
		var x = axisX, y = axisY, z = axisZ, lengthSquared = x * x + y * y + z * z;
		if (lengthSquared != 1 && lengthSquared != 0) {
			var inverse = 1 / Math.sqrt(lengthSquared);
			x *= inverse;
			y *= inverse;
			z *= inverse;
		}
		var s = Trig.sin(radians), c = Trig.cos(radians), t = 1 - c;
		return set(x * x * t
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

	/** Makes this the rotation a quaternion (x, y, z, w) gives.

		@param x  The quaternion's x.
		@param y  Its y.
		@param z  Its z.
		@param w  Its w.
		@return  This matrix. */
	public function makeQuaternionRotation(x:Float, y:Float, z:Float, w:Float):Matrix3D {
		var a2 = x * x, b2 = y * y, c2 = z * z, ac = x * z, ab = x * y, bc = y * z, ad = w * x, bd = w * y, cd = w * z;
		return set(1
			- 2 * (b2 + c2), 2 * (ab + cd), 2 * (ac - bd), 0, 2 * (ab - cd), 1
			- 2 * (a2 + c2), 2 * (bc + ad), 0, 2 * (ac + bd), 2 * (bc - ad),
			1
			- 2 * (a2 + b2), 0, 0, 0, 0, 1);
	}

	/** Makes this a view from an eye looking at a target.

		@param eyeX  Where it looks from.
		@param eyeY  Where it looks from.
		@param eyeZ  Where it looks from.
		@param targetX  What it looks at.
		@param targetY  What it looks at.
		@param targetZ  What it looks at.
		@param upX  Up.
		@param upY  Up.
		@param upZ  Up.
		@return  This matrix. */
	public function makeLookAt(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX:Float, upY:Float, upZ:Float):Matrix3D {
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
		return set(xx, yx, zx, 0, xy, yy, zy, 0, xz, yz, zz, 0,
			-(xx * eyeX + xy * eyeY + xz * eyeZ),
			-(yx * eyeX + yy * eyeY + yz * eyeZ),
			-(zx * eyeX + zy * eyeY + zz * eyeZ), 1);
	}

	/** Makes this a perspective projection into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.

		@param fovY  The field of view, top to bottom, in radians.
		@param aspect  Width over height.
		@param near  The near plane's distance.
		@param far  The far plane's distance.
		@return  This matrix. */
	public function makePerspective(fovY:Float, aspect:Float, near:Float, far:Float):Matrix3D {
		var top = near * Trig.tan(fovY * .5),
			right = top * aspect,
			depth = far - near;
		return set(near / right, 0, 0, 0, 0, near / top, 0, 0, 0, 0, -(far + near) / depth, -1, 0, 0, -(far * near * 2) / depth, 0);
	}

	/** Makes this an orthographic projection into GL's clip space (depth -1 to 1), which every helix-platform adapter takes.

		@param left  The left edge.
		@param right  The right edge.
		@param bottom  The bottom edge.
		@param top  The top edge.
		@param near  The near plane's distance.
		@param far  The far plane's distance.
		@return  This matrix. */
	public function makeOrthographic(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float):Matrix3D {
		var width = right - left, height = top - bottom, depth = far - near;
		return set(2 / width, 0, 0, 0, 0, 2 / height, 0, 0, 0, 0, -2 / depth, 0,
			-(left + right) / width,
			-(top + bottom) / height,
			-(far + near) / depth, 1);
	}

	/** Makes this a perspective projection into GL's clip space (depth -1 to 1) by its near plane's edges, which may be off center.

		@param left  The near plane's left edge.
		@param right  Its right edge.
		@param bottom  Its bottom edge.
		@param top  Its top edge.
		@param near  The near plane's distance.
		@param far  The far plane's distance.
		@return  This matrix. */
	public function makeFrustum(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float):Matrix3D {
		var width = right - left, height = top - bottom, depth = far - near;
		return set(near * 2 / width, 0, 0, 0, 0, near * 2 / height, 0, 0, (right + left) / width, (top + bottom) / height, -(far + near) / depth, -1, 0, 0,
			-(far * near * 2) / depth, 0);
	}

	/** Makes this first's transform followed by second's. Either may be this matrix.

		@param first  The transform applied first.
		@param second  The transform applied after it.
		@return  This matrix. */
	public function compose(first:Matrix3D, second:Matrix3D):Matrix3D {
		var a = first.values, b = second.values;
		for (column in 0...4)
			for (row in 0...4)
				scratch[column * 4 + row] = a[column * 4] * b[row]
					+ a[column * 4 + 1] * b[4 + row] + a[column * 4 + 2] * b[8 + row] + a[column * 4 + 3] * b[12 + row];
		for (i in 0...16)
			values[i] = scratch[i];
		return this;
	}

	/** Follows this transform with another's.

		@param other  The transform applied after this one.
		@return  This matrix. */
	public function append(other:Matrix3D):Matrix3D {
		return compose(this, other);
	}

	/** Puts another transform before this one.

		@param other  The transform applied before this one.
		@return  This matrix. */
	public function prepend(other:Matrix3D):Matrix3D {
		return compose(other, this);
	}

	/** Follows this transform with a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  This matrix. */
	public function appendTranslation(x:Float, y:Float, z:Float):Matrix3D {
		values[12] += values[15] * x;
		values[13] += values[15] * y;
		values[14] += values[15] * z;
		for (column in 0...3) {
			var w = values[column * 4 + 3];
			values[column * 4] += w * x;
			values[column * 4 + 1] += w * y;
			values[column * 4 + 2] += w * z;
		}
		return this;
	}

	/** Follows this transform with a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  This matrix. */
	public function appendScale(x:Float, y:Float, z:Float):Matrix3D {
		for (column in 0...4) {
			values[column * 4] *= x;
			values[column * 4 + 1] *= y;
			values[column * 4 + 2] *= z;
		}
		return this;
	}

	/** Follows this transform with a rotation about an axis.

		@param axisX  The axis's x.
		@param axisY  Its y.
		@param axisZ  Its z.
		@param radians  The angle, counterclockwise looking down the axis toward its origin.
		@return  This matrix. */
	public function appendRotation(axisX:Float, axisY:Float, axisZ:Float, radians:Float):Matrix3D {
		var rotation = shared();
		rotation.makeRotation(axisX, axisY, axisZ, radians);
		return compose(this, rotation);
	}

	/** Inverts this matrix.

		@return  False, leaving it as it was, when it has no inverse. */
	public function invert():Bool {
		var m = values;
		var a00 = m[0], a01 = m[1], a02 = m[2], a03 = m[3], a10 = m[4], a11 = m[5], a12 = m[6], a13 = m[7];
		var a20 = m[8], a21 = m[9], a22 = m[10], a23 = m[11], a30 = m[12], a31 = m[13], a32 = m[14], a33 = m[15];
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
			return false;
		var d = 1 / determinant;
		set((a11 * b11 - a12 * b10 + a13 * b09) * d, (-a01 * b11 + a02 * b10 - a03 * b09) * d, (a31 * b05 - a32 * b04 + a33 * b03) * d,
			(-a21 * b05 + a22 * b04 - a23 * b03) * d, (-a10 * b11 + a12 * b08 - a13 * b07) * d, (a00 * b11 - a02 * b08 + a03 * b07) * d,
			(-a30 * b05 + a32 * b02 - a33 * b01) * d, (a20 * b05 - a22 * b02 + a23 * b01) * d, (a10 * b10 - a11 * b08 + a13 * b06) * d,
			(-a00 * b10 + a01 * b08 - a03 * b06) * d, (a30 * b04 - a31 * b02 + a33 * b00) * d, (-a20 * b04 + a21 * b02 - a23 * b00) * d,
			(-a10 * b09 + a11 * b07 - a12 * b06) * d, (a00 * b09 - a01 * b07 + a02 * b06) * d, (-a30 * b03 + a31 * b01 - a32 * b00) * d,
			(a20 * b03 - a21 * b01 + a22 * b00) * d);
		return true;
	}

	/** Transposes this matrix: rows become columns.

		@return  This matrix. */
	public function transpose():Matrix3D {
		for (column in 0...4)
			for (row in column + 1...4) {
				var t = values[column * 4 + row];
				values[column * 4 + row] = values[row * 4 + column];
				values[row * 4 + column] = t;
			}
		return this;
	}

	/** Computes where a point goes, translation included.

		@param x  The point's x.
		@param y  Its y.
		@param z  Its z.
		@param out  Optional. The point to fill; a new one when omitted.
		@return  The point. */
	public function transformPoint(x:Float, y:Float, z:Float, ?out:Point3D):Point3D {
		var m = values;
		if (out == null)
			out = new Point3D();
		return out.set(m[0] * x + m[4] * y + m[8] * z + m[12], m[1] * x + m[5] * y + m[9] * z + m[13], m[2] * x + m[6] * y + m[10] * z + m[14]);
	}

	/** Computes where a direction goes, translation left out.

		@param x  The direction's x.
		@param y  Its y.
		@param z  Its z.
		@param out  Optional. The point to fill; a new one when omitted.
		@return  The direction. */
	public function transformDirection(x:Float, y:Float, z:Float, ?out:Point3D):Point3D {
		var m = values;
		if (out == null)
			out = new Point3D();
		return out.set(m[0] * x + m[4] * y + m[8] * z, m[1] * x + m[5] * y + m[9] * z, m[2] * x + m[6] * y + m[10] * z);
	}

	// The product, written here first, so either matrix of compose may be this one.
	final scratch:Array<Float> = [for (_ in 0...16) 0.];

	function set(m0:Float, m1:Float, m2:Float, m3:Float, m4:Float, m5:Float, m6:Float, m7:Float, m8:Float, m9:Float, m10:Float, m11:Float, m12:Float,
			m13:Float, m14:Float, m15:Float):Matrix3D {
		var v = values;
		v[0] = m0;
		v[1] = m1;
		v[2] = m2;
		v[3] = m3;
		v[4] = m4;
		v[5] = m5;
		v[6] = m6;
		v[7] = m7;
		v[8] = m8;
		v[9] = m9;
		v[10] = m10;
		v[11] = m11;
		v[12] = m12;
		v[13] = m13;
		v[14] = m14;
		v[15] = m15;
		return this;
	}

	// A matrix appendRotation turns into, reused.
	static var rotation:Null<Matrix3D> = null;

	static function shared():Matrix3D {
		if (rotation == null)
			rotation = new Matrix3D();
		return rotation;
	}
}
