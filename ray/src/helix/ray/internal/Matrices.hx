package helix.ray.internal;

/** Provides raymath's matrix arithmetic on arrays of 16 floats, `m0` to `m15` as raylib numbers them (by columns), with raymath's
	conventions: `multiply(a, b)` applies a, then b. The formulas are raymath's (raylib 5.5, zlib). */
@:noCompletion
class Matrices {
	/** Returns the identity. */
	public static function identity():Array<Float> {
		return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];
	}

	/** Returns left, then right, as raymath's `MatrixMultiply`. */
	public static function multiply(l:Array<Float>, r:Array<Float>):Array<Float> {
		var out = [];
		for (row in 0...4)
			for (col in 0...4)
				out.push(l[row * 4] * r[col] + l[row * 4 + 1] * r[4 + col] + l[row * 4 + 2] * r[8 + col] + l[row * 4 + 3] * r[12 + col]);
		return out;
	}

	/** Returns raymath's `MatrixTranspose`. */
	public static function transpose(m:Array<Float>):Array<Float> {
		return [for (i in 0...16) m[(i % 4) * 4 + Std.int(i / 4)]];
	}

	/** Returns raymath's `MatrixTranslate`. */
	public static function translate(x:Float, y:Float, z:Float):Array<Float> {
		return [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, x, y, z, 1];
	}

	/** Returns raymath's `MatrixScale`. */
	public static function scale(x:Float, y:Float, z:Float):Array<Float> {
		return [x, 0, 0, 0, 0, y, 0, 0, 0, 0, z, 0, 0, 0, 0, 1];
	}

	/** Returns raymath's `MatrixRotate`: about an axis, by radians. */
	public static function rotate(ax:Float, ay:Float, az:Float, angle:Float):Array<Float> {
		var x = ax, y = ay, z = az, l = x * x + y * y + z * z;
		if (l != 1 && l != 0) {
			var il = 1 / Math.sqrt(l);
			x *= il;
			y *= il;
			z *= il;
		}
		var s = Math.sin(angle), c = Math.cos(angle), t = 1 - c;
		return [
			    x * x * t + c, y * x * t + z * s, z * x * t - y * s, 0,
			x * y * t - z * s,     y * y * t + c, z * y * t + x * s, 0,
			x * z * t + y * s, y * z * t - x * s,     z * z * t + c, 0,
			                0,                 0,                 0, 1
		];
	}

	/** Returns raymath's `QuaternionToMatrix`. */
	public static function quaternion(x:Float, y:Float, z:Float, w:Float):Array<Float> {
		var a2 = x * x, b2 = y * y, c2 = z * z, ac = x * z, ab = x * y, bc = y * z, ad = w * x, bd = w * y, cd = w * z;
		return [
			1 - 2 * (b2 + c2),     2 * (ab + cd),     2 * (ac - bd), 0,
			    2 * (ab - cd), 1 - 2 * (a2 + c2),     2 * (bc + ad), 0,
			    2 * (ac + bd),     2 * (bc - ad), 1 - 2 * (a2 + b2), 0,
			                0,                 0,                 0, 1
		];
	}

	/** Returns raymath's `MatrixOrtho`. */
	public static function ortho(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float):Array<Float> {
		var rl = right - left, tb = top - bottom, fn = far - near;
		return [
			2 / rl,
			0,
			0,
			0,
			0,
			2 / tb,
			0,
			0,
			0,
			0,
			-2 / fn,
			0,
			-(left + right) / rl,
			-(top + bottom) / tb,
			-(far + near) / fn,
			1
		];
	}

	/** Returns raymath's `MatrixPerspective`, fovY in radians. */
	public static function perspective(fovY:Float, aspect:Float, near:Float, far:Float):Array<Float> {
		var top = near * Math.tan(fovY * .5), right = top * aspect;
		var rl = right * 2, tb = top * 2, fn = far - near;
		return [
			near * 2 / rl,             0,                      0,  0,
			            0, near * 2 / tb,                      0,  0,
			            0,             0,     -(far + near) / fn, -1,
			            0,             0, -(far * near * 2) / fn,  0
		];
	}

	/** Returns raymath's `MatrixLookAt`. */
	public static function lookAt(ex:Float, ey:Float, ez:Float, tx:Float, ty:Float, tz:Float, ux:Float, uy:Float, uz:Float):Array<Float> {
		var zx = ex - tx, zy = ey - ty, zz = ez - tz;
		var l = Math.sqrt(zx * zx + zy * zy + zz * zz);
		if (l == 0)
			l = 1;
		zx /= l;
		zy /= l;
		zz /= l;
		var xx = uy * zz - uz * zy,
			xy = uz * zx - ux * zz,
			xz = ux * zy - uy * zx;
		l = Math.sqrt(xx * xx + xy * xy + xz * xz);
		if (l == 0)
			l = 1;
		xx /= l;
		xy /= l;
		xz /= l;
		var yx = zy * xz - zz * xy,
			yy = zz * xx - zx * xz,
			yz = zx * xy - zy * xx;
		return [
			xx,
			yx,
			zx,
			0,
			xy,
			yy,
			zy,
			0,
			xz,
			yz,
			zz,
			0,
			-(xx * ex + xy * ey + xz * ez),
			-(yx * ex + yy * ey + yz * ez),
			-(zx * ex + zy * ey + zz * ez),
			1
		];
	}

	/** Returns raymath's `MatrixInvert`. */
	public static function invert(m:Array<Float>):Array<Float> {
		var a00 = m[0], a01 = m[1], a02 = m[2], a03 = m[3];
		var a10 = m[4], a11 = m[5], a12 = m[6], a13 = m[7];
		var a20 = m[8], a21 = m[9], a22 = m[10], a23 = m[11];
		var a30 = m[12], a31 = m[13], a32 = m[14], a33 = m[15];
		var b00 = a00 * a11 - a01 * a10,
			b01 = a00 * a12 - a02 * a10,
			b02 = a00 * a13 - a03 * a10;
		var b03 = a01 * a12 - a02 * a11,
			b04 = a01 * a13 - a03 * a11,
			b05 = a02 * a13 - a03 * a12;
		var b06 = a20 * a31 - a21 * a30,
			b07 = a20 * a32 - a22 * a30,
			b08 = a20 * a33 - a23 * a30;
		var b09 = a21 * a32 - a22 * a31,
			b10 = a21 * a33 - a23 * a31,
			b11 = a22 * a33 - a23 * a32;
		var det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
		var inv = det == 0 ? 0 : 1 / det;
		return [
			 (a11 * b11 - a12 * b10 + a13 * b09) * inv, (-a01 * b11 + a02 * b10 - a03 * b09) * inv,
			 (a31 * b05 - a32 * b04 + a33 * b03) * inv, (-a21 * b05 + a22 * b04 - a23 * b03) * inv,
			(-a10 * b11 + a12 * b08 - a13 * b07) * inv,  (a00 * b11 - a02 * b08 + a03 * b07) * inv,
			(-a30 * b05 + a32 * b02 - a33 * b01) * inv,  (a20 * b05 - a22 * b02 + a23 * b01) * inv,
			 (a10 * b10 - a11 * b08 + a13 * b06) * inv, (-a00 * b10 + a01 * b08 - a03 * b06) * inv,
			 (a30 * b04 - a31 * b02 + a33 * b00) * inv, (-a20 * b04 + a21 * b02 - a23 * b00) * inv,
			(-a10 * b09 + a11 * b07 - a12 * b06) * inv,  (a00 * b09 - a01 * b07 + a02 * b06) * inv,
			(-a30 * b03 + a31 * b01 - a32 * b00) * inv,  (a20 * b03 - a21 * b01 + a22 * b00) * inv
		];
	}

	/** Returns a point times a matrix, raymath's `Vector3Transform`. */
	public static function point(m:Array<Float>, x:Float, y:Float, z:Float):Array<Float> {
		return [
			m[0] * x + m[4] * y + m[8] * z + m[12],
			m[1] * x + m[5] * y + m[9] * z + m[13],
			m[2] * x + m[6] * y + m[10] * z + m[14]
		];
	}

	/** Returns a raylib `Matrix` as the array. */
	public static function of(m:helix.ray.Matrix):Array<Float> {
		return [
			m.m0, m.m1, m.m2, m.m3, m.m4, m.m5, m.m6, m.m7, m.m8, m.m9, m.m10, m.m11, m.m12, m.m13, m.m14, m.m15
		];
	}

	/** Returns the array as a raylib `Matrix`. */
	public static function to(a:Array<Float>):helix.ray.Matrix {
		return new helix.ray.Matrix(a[0], a[4], a[8], a[12], a[1], a[5], a[9], a[13], a[2], a[6], a[10], a[14], a[3], a[7], a[11], a[15]);
	}
}
