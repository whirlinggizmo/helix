package helix.ray.raylib;

#if !macro
import helix.ray.*;
import helix.ray.Raylib.*;
import helix.math.Matrix3D;
import helix.ray.internal.DefaultFont;
import helix.ray.internal.Models;
import helix.ray.internal.Runtime;
import helix.ray.internal.Textures;
import helix.ray.raylib.RCore.*;
import helix.ray.raylib.RShapes.*;
import helix.ray.raylib.RTextures.*;
import helix.ray.raylib.RText.*;
import helix.ray.raylib.RModels.*;
import helix.ray.raylib.RAudio.*;
import helix.ray.raylib.RMath.*;
import helix.ray.raylib.HelixRay.*;
#end

/** Holds raylib's raymath (vectors, matrices and quaternions), written here; `Raymath` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.ray)
class RMath {
	#if !macro
	// ---- raymath ----

	/** Returns a value kept between two others.

		@param value  The value.
		@param min  The least.
		@param max  The most.
		@return  The value, at least min and at most max. */
	static function Clamp(value:Float, min:Float, max:Float):Float {
		var r = value < min ? min : value;
		return r > max ? max : r;
	}

	/** Returns a value part of the way from one to another.

		@param start  The start.
		@param end  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The value. */
	static function Lerp(start:Float, end:Float, amount:Float):Float {
		return start + amount * (end - start);
	}

	/** Returns a value moved from one range to another.

		@param value  The value.
		@param inputStart  The first range's start.
		@param inputEnd  Its end.
		@param outputStart  The second range's start.
		@param outputEnd  Its end.
		@return  The value in the second range. */
	static function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float {
		return (value - inputStart) / (inputEnd - inputStart) * (outputEnd - outputStart) + outputStart;
	}

	/** Returns (0, 0).

		@return  The vector. */
	static function Vector2Zero():Vector2 {
		return new Vector2(0, 0);
	}

	/** Returns (1, 1).

		@return  The vector. */
	static function Vector2One():Vector2 {
		return new Vector2(1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@return  The sum. */
	static function Vector2Add(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x + v2.x, v1.y + v2.y);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x - v2.x, v1.y - v2.y);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scale  The scale.
		@return  The scaled vector. */
	static function Vector2Scale(v:Vector2, scale:Float):Vector2 {
		return new Vector2(v.x * scale, v.y * scale);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector2Multiply(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x * v2.x, v1.y * v2.y);
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	static function Vector2Length(v:Vector2):Float {
		return Math.sqrt(v.x * v.x + v.y * v.y);
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	static function Vector2LengthSqr(v:Vector2):Float {
		return v.x * v.x + v.y * v.y;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static function Vector2Distance(v1:Vector2, v2:Vector2):Float {
		var dx = v2.x - v1.x, dy = v2.y - v1.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	/** Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).

		@param v  The vector.
		@return  The direction. */
	static function Vector2Normalize(v:Vector2):Vector2 {
		var length = Vector2Length(v);
		return length > 0 ? new Vector2(v.x / length, v.y / length) : new Vector2(0, 0);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2 {
		return new Vector2(v1.x + amount * (v2.x - v1.x), v1.y + amount * (v2.y - v1.y));
	}

	/** Returns a vector with its length kept between two values.

		@param v  The vector.
		@param min  The least length.
		@param max  The most length.
		@return  The vector. */
	static function Vector2ClampValue(v:Vector2, min:Float, max:Float):Vector2 {
		var length = Vector2Length(v);
		if (length == 0)
			return new Vector2(0, 0);
		var clamped = Clamp(length, min, max);
		return Vector2Scale(v, clamped / length);
	}

	// ---- raymath: Vector3 ----

	/** Returns (0, 0, 0).

		@return  The vector. */
	static function Vector3Zero():Vector3 {
		return new Vector3(0, 0, 0);
	}

	/** Returns (1, 1, 1).

		@return  The vector. */
	static function Vector3One():Vector3 {
		return new Vector3(1, 1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@return  The sum. */
	static function Vector3Add(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	static function Vector3Subtract(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scalar  The scale.
		@return  The scaled vector. */
	static function Vector3Scale(v:Vector3, scalar:Float):Vector3 {
		return new Vector3(v.x * scalar, v.y * scalar, v.z * scalar);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector3Multiply(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z);
	}

	/** Returns the cross product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector3CrossProduct(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.y * v2.z - v1.z * v2.y, v1.z * v2.x - v1.x * v2.z, v1.x * v2.y - v1.y * v2.x);
	}

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector3DotProduct(v1:Vector3, v2:Vector3):Float {
		return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	static function Vector3Length(v:Vector3):Float {
		return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	static function Vector3LengthSqr(v:Vector3):Float {
		return v.x * v.x + v.y * v.y + v.z * v.z;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static function Vector3Distance(v1:Vector3, v2:Vector3):Float {
		return Vector3Length(Vector3Subtract(v1, v2));
	}

	/** Returns a vector of length 1 in the same direction, or the vector itself when its length is 0.

		@param v  The vector.
		@return  The direction. */
	static function Vector3Normalize(v:Vector3):Vector3 {
		var l = Vector3Length(v);
		return l == 0 ? new Vector3(v.x, v.y, v.z) : new Vector3(v.x / l, v.y / l, v.z / l);
	}

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@return  The negated vector. */
	static function Vector3Negate(v:Vector3):Vector3 {
		return new Vector3(-v.x, -v.y, -v.z);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	static function Vector3Lerp(v1:Vector3, v2:Vector3, amount:Float):Vector3 {
		return new Vector3(v1.x + amount * (v2.x - v1.x), v1.y + amount * (v2.y - v1.y), v1.z + amount * (v2.z - v1.z));
	}

	/** Returns a point transformed by a matrix.

		@param v  The point.
		@param mat  The matrix.
		@return  The transformed point. */
	static function Vector3Transform(v:Vector3, mat:Matrix):Vector3 {
		var p = toMatrix3D(mat).transformPoint(v.x, v.y, v.z);
		return new Vector3(p.x, p.y, p.z);
	}

	/** Returns a vector turned about an axis.

		@param v  The vector.
		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The turned vector. */
	static function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float):Vector3 {
		var m = new Matrix3D().makeRotation(axis.x, axis.y, axis.z, angle);
		var p = m.transformPoint(v.x, v.y, v.z);
		return new Vector3(p.x, p.y, p.z);
	}

	// ---- raymath: Matrix and Quaternion ----

	/** Returns the identity matrix.

		@return  The matrix. */
	static function MatrixIdentity():Matrix {
		return toMatrix(new Matrix3D());
	}

	/** Returns two matrices multiplied: left, then right.

		@param left  The first.
		@param right  The second.
		@return  The product. */
	static function MatrixMultiply(left:Matrix, right:Matrix):Matrix {
		return toMatrix(new Matrix3D().compose(toMatrix3D(left), toMatrix3D(right)));
	}

	/** Returns a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	static function MatrixTranslate(x:Float, y:Float, z:Float):Matrix {
		return toMatrix(new Matrix3D().makeTranslation(x, y, z));
	}

	/** Returns a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	static function MatrixScale(x:Float, y:Float, z:Float):Matrix {
		return toMatrix(new Matrix3D().makeScale(x, y, z));
	}

	/** Returns a rotation about an axis.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotate(axis:Vector3, angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(axis.x, axis.y, axis.z, angle));
	}

	/** Returns a rotation about x.

		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotateX(angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(1, 0, 0, angle));
	}

	/** Returns a rotation about y.

		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotateY(angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(0, 1, 0, angle));
	}

	/** Returns a rotation about z.

		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotateZ(angle:Float):Matrix {
		return toMatrix(new Matrix3D().makeRotation(0, 0, 1, angle));
	}

	/** Returns rotations about x, then y, then z.

		@param angle  The angles, in radians.
		@return  The matrix. */
	static function MatrixRotateXYZ(angle:Vector3):Matrix {
		var m = new Matrix3D().compose(new Matrix3D().makeRotation(1, 0, 0, angle.x), new Matrix3D().makeRotation(0, 1, 0, angle.y));
		return toMatrix(new Matrix3D().compose(m, new Matrix3D().makeRotation(0, 0, 1, angle.z)));
	}

	/** Returns a matrix inverted.

		@param mat  The matrix.
		@return  Its inverse. */
	static function MatrixInvert(mat:Matrix):Matrix {
		var inverse = toMatrix3D(mat);
		inverse.invert();
		return toMatrix(inverse);
	}

	/** Returns a matrix transposed.

		@param mat  The matrix.
		@return  Its transpose. */
	static function MatrixTranspose(mat:Matrix):Matrix {
		return toMatrix(new Matrix3D().copyFrom(toMatrix3D(mat)).transpose());
	}

	/** Returns a view looking from eye at target.

		@param eye  Where from.
		@param target  What at.
		@param up  Up.
		@return  The matrix. */
	static function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix {
		return toMatrix(new Matrix3D().makeLookAt(eye.x, eye.y, eye.z, target.x, target.y, target.z, up.x, up.y, up.z));
	}

	/** Returns a perspective projection.

		@param fovY  The field of view, top to bottom, in radians.
		@param aspect  Width over height.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@return  The matrix. */
	static function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float):Matrix {
		return toMatrix(new Matrix3D().makePerspective(fovY, aspect, nearPlane, farPlane));
	}

	/** Returns an orthographic projection.

		@param left  Left.
		@param right  Right.
		@param bottom  Bottom.
		@param top  Top.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@return  The matrix. */
	static function MatrixOrtho(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix {
		return toMatrix(new Matrix3D().makeOrthographic(left, right, bottom, top, nearPlane, farPlane));
	}

	/** Returns the identity quaternion.

		@return  The quaternion. */
	static function QuaternionIdentity():Quaternion {
		return new Vector4(0, 0, 0, 1);
	}

	/** Returns the rotation about an axis as a quaternion.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The quaternion. */
	static function QuaternionFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
		var a = Vector3Normalize(axis), s = Math.sin(angle / 2);
		return new Vector4(a.x * s, a.y * s, a.z * s, Math.cos(angle / 2));
	}

	/** Returns a rotation by Euler angles as a quaternion.

		@param pitch  About x, in radians.
		@param yaw  About y.
		@param roll  About z.
		@return  The quaternion. */
	static function QuaternionFromEuler(pitch:Float, yaw:Float, roll:Float):Quaternion {
		var x0 = Math.cos(pitch * .5),
			x1 = Math.sin(pitch * .5),
			y0 = Math.cos(yaw * .5),
			y1 = Math.sin(yaw * .5),
			z0 = Math.cos(roll * .5),
			z1 = Math.sin(roll * .5);
		return new Vector4(x1 * y0 * z0 - x0 * y1 * z1, x0 * y1 * z0 + x1 * y0 * z1, x0 * y0 * z1 - x1 * y1 * z0, x0 * y0 * z0 + x1 * y1 * z1);
	}

	/** Returns a quaternion's rotation as a matrix.

		@param q  The quaternion.
		@return  The matrix. */
	static function QuaternionToMatrix(q:Quaternion):Matrix {
		return toMatrix(new Matrix3D().makeQuaternionRotation(q.x, q.y, q.z, q.w));
	}
	#end
}
