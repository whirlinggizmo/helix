package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;

/** A 4x4 matrix of floats, column-major (element column * 4 + row), as shaders take it. Setters overwrite the whole matrix. */
class Mat4 {
	var m = new Vector<Float>(16);

	/** The identity. */
	public function new()
		setIdentity();

	/** Element column * 4 + row. */
	public inline function get(index:Int):Float
		return m[index];

	/** Sets element column * 4 + row to value. */
	public inline function set(index:Int, value:Float):Void
		m[index] = value;

	/** The identity. */
	public function setIdentity():Void
		for (i in 0...16)
			m[i] = i % 5 == 0 ? 1 : 0;

	/** A perspective projection: fovY radians of vertical view, aspect width / height, near and far the clip planes' distances, GL clip depth
		(-1 near to 1 far). False, changing nothing, unless 0 < fovY < pi, aspect > 0 and 0 < near < far. */
	public function setPerspective(fovY:Float, aspect:Float, near:Float, far:Float):Bool {
		if (!(fovY > 0 && fovY < Math.PI && aspect > 0 && near > 0 && far > near))
			return false;
		var f = 1 / Math.tan(fovY / 2);
		for (i in 0...16)
			m[i] = 0;
		m[0] = f / aspect;
		m[5] = f;
		m[10] = (far + near) / (near - far);
		m[11] = -1;
		m[14] = 2 * far * near / (near - far);
		return true;
	}

	/** An orthographic projection: height world units of vertical view (width by aspect, width / height) centered on the view's axis, near and
		far the clip planes' distances, GL clip depth (-1 near to 1 far). False, changing nothing, unless height > 0, aspect > 0 and near < far. */
	public function setOrthographic(height:Float, aspect:Float, near:Float, far:Float):Bool {
		if (!(height > 0 && aspect > 0 && far > near))
			return false;
		for (i in 0...16)
			m[i] = 0;
		m[0] = 2 / (height * aspect);
		m[5] = 2 / height;
		m[10] = 2 / (near - far);
		m[14] = (far + near) / (near - far);
		m[15] = 1;
		return true;
	}

	/** A view from eye looking at target, up giving the roll: right-handed, the eye looking down its -z. False, changing nothing, when the eye is at
		the target or up is parallel to the view. */
	public function setLookAt(eyeX:Float, eyeY:Float, eyeZ:Float, targetX:Float, targetY:Float, targetZ:Float, upX:Float, upY:Float, upZ:Float):Bool {
		var fx = targetX - eyeX, fy = targetY - eyeY, fz = targetZ - eyeZ;
		var fl = Math.sqrt(fx * fx + fy * fy + fz * fz);
		if (fl == 0)
			return false;
		fx /= fl;
		fy /= fl;
		fz /= fl;
		var sx = fy * upZ - fz * upY,
			sy = fz * upX - fx * upZ,
			sz = fx * upY - fy * upX;
		var sl = Math.sqrt(sx * sx + sy * sy + sz * sz);
		if (sl < 1e-12)
			return false;
		sx /= sl;
		sy /= sl;
		sz /= sl;
		var ux = sy * fz - sz * fy,
			uy = sz * fx - sx * fz,
			uz = sx * fy - sy * fx;
		m[0] = sx;
		m[1] = ux;
		m[2] = -fx;
		m[3] = 0;
		m[4] = sy;
		m[5] = uy;
		m[6] = -fy;
		m[7] = 0;
		m[8] = sz;
		m[9] = uz;
		m[10] = -fz;
		m[11] = 0;
		m[12] = -(sx * eyeX + sy * eyeY + sz * eyeZ);
		m[13] = -(ux * eyeX + uy * eyeY + uz * eyeZ);
		m[14] = fx * eyeX + fy * eyeY + fz * eyeZ;
		m[15] = 1;
		return true;
	}

	/** Scale, then rotation (the unit quaternion qx, qy, qz, qw), then translation: a placement's matrix. */
	public function setTransform(px:Float, py:Float, pz:Float, qx:Float, qy:Float, qz:Float, qw:Float, sx:Float, sy:Float, sz:Float):Void {
		m[0] = (1 - 2 * (qy * qy + qz * qz)) * sx;
		m[1] = 2 * (qx * qy + qz * qw) * sx;
		m[2] = 2 * (qx * qz - qy * qw) * sx;
		m[3] = 0;
		m[4] = 2 * (qx * qy - qz * qw) * sy;
		m[5] = (1 - 2 * (qx * qx + qz * qz)) * sy;
		m[6] = 2 * (qy * qz + qx * qw) * sy;
		m[7] = 0;
		m[8] = 2 * (qx * qz + qy * qw) * sz;
		m[9] = 2 * (qy * qz - qx * qw) * sz;
		m[10] = (1 - 2 * (qx * qx + qy * qy)) * sz;
		m[11] = 0;
		m[12] = px;
		m[13] = py;
		m[14] = pz;
		m[15] = 1;
	}

	/** Copies other into this matrix. */
	public function setFrom(other:Mat4):Void
		for (i in 0...16)
			m[i] = other.m[i];

	/** a * b: b applied first, then a. Either may be this matrix. */
	public function setProduct(a:Mat4, b:Mat4):Void {
		var r = scratch;
		for (c in 0...4)
			for (row in 0...4)
				r[c * 4 + row] = a.m[row] * b.m[c * 4] + a.m[4 + row] * b.m[c * 4 + 1] + a.m[8 + row] * b.m[c * 4 + 2] + a.m[12 + row] * b.m[c * 4 + 3];
		for (i in 0...16)
			m[i] = r[i];
	}

	static var scratch = new Vector<Float>(16);

	/** Writes the 16 floats, column-major, little-endian float32, into bytes at offset: the 64 bytes a shader's matrix uniform takes. */
	public function writeTo(bytes:Bytes, offset:Int = 0):Void
		for (i in 0...16)
			bytes.setFloat(offset + i * 4, m[i]);
}
