package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.Matrix3D;
import helix.raylib.internal.DefaultFont;
import helix.raylib.internal.Models;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.raylib.modules.RCore.*;
import helix.raylib.modules.RShapes.*;
import helix.raylib.modules.RTextures.*;
import helix.raylib.modules.RText.*;
import helix.raylib.modules.RModels.*;
import helix.raylib.modules.RAudio.*;
import helix.raylib.modules.RMath.*;
#end

/** Provides raylib's raymath functions for vectors, matrices and quaternions, written in Haxe.

	`Raymath` forwards to each, through `tools/gen_raylib.py`. */
@:noCompletion
@:allow(helix.raylib)
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

	/** Returns where a value falls from one to another: 0 at the start, 1 at the end.

		@param value  The value.
		@param start  The start.
		@param end  The end.
		@return  The fraction. */
	static function Normalize(value:Float, start:Float, end:Float):Float {
		return (value - start) / (end - start);
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

	/** Returns a value wrapped around into a range, as an angle wraps around a turn.

		@param value  The value.
		@param min  The range's start.
		@param max  Its end.
		@return  The value in the range. */
	static function Wrap(value:Float, min:Float, max:Float):Float {
		return value - (max - min) * Math.ffloor((value - min) / (max - min));
	}

	/** Returns whether two values are equal but for rounding.

		Counts them equal when they are no further apart than `EPSILON`, times the larger magnitude when that is over 1.

		@param x  One.
		@param y  The other.
		@return  1 if they are, 0 if not. */
	static function FloatEquals(x:Float, y:Float):Int {
		return Math.abs(x - y) <= Raymath.EPSILON * fmaxf(1, fmaxf(Math.abs(x), Math.abs(y))) ? 1 : 0;
	}

	// ---- raymath: Vector2 ----

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

	/** Returns a vector with a value added to each component.

		@param v  The vector.
		@param add  The value.
		@return  The sum. */
	static function Vector2AddValue(v:Vector2, add:Float):Vector2 {
		return new Vector2(v.x + add, v.y + add);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	static function Vector2Subtract(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x - v2.x, v1.y - v2.y);
	}

	/** Returns a vector with a value taken from each component.

		@param v  The vector.
		@param sub  The value.
		@return  The difference. */
	static function Vector2SubtractValue(v:Vector2, sub:Float):Vector2 {
		return new Vector2(v.x - sub, v.y - sub);
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

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector2DotProduct(v1:Vector2, v2:Vector2):Float {
		return v1.x * v2.x + v1.y * v2.y;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static function Vector2Distance(v1:Vector2, v2:Vector2):Float {
		var dx = v2.x - v1.x, dy = v2.y - v1.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	/** Returns the distance between two points, squared.

		@param v1  One.
		@param v2  The other.
		@return  The distance squared. */
	static function Vector2DistanceSqr(v1:Vector2, v2:Vector2):Float {
		return (v1.x - v2.x) * (v1.x - v2.x) + (v1.y - v2.y) * (v1.y - v2.y);
	}

	/** Returns the angle from one vector to another, from -pi to pi.

		Positive turning from x toward y.

		@param v1  The first.
		@param v2  The second.
		@return  The angle, in radians. */
	static function Vector2Angle(v1:Vector2, v2:Vector2):Float {
		var dot = v1.x * v2.x + v1.y * v2.y;
		var det = v1.x * v2.y - v1.y * v2.x;
		return Math.atan2(det, dot);
	}

	/** Returns the angle of the line from one point to another, measured from the x axis.

		Positive turning from x toward -y.

		@param start  The line's start.
		@param end  Its end.
		@return  The angle, in radians. */
	static function Vector2LineAngle(start:Vector2, end:Vector2):Float {
		return -Math.atan2(end.y - start.y, end.x - start.x);
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

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@return  The negated vector. */
	static function Vector2Negate(v:Vector2):Vector2 {
		return new Vector2(-v.x, -v.y);
	}

	/** Returns one vector divided by another, component by component.

		@param v1  The one divided.
		@param v2  The one dividing it.
		@return  The quotient. */
	static function Vector2Divide(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(v1.x / v2.x, v1.y / v2.y);
	}

	/** Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).

		@param v  The vector.
		@return  The direction. */
	static function Vector2Normalize(v:Vector2):Vector2 {
		var length = Vector2Length(v);
		return length > 0 ? new Vector2(v.x / length, v.y / length) : new Vector2(0, 0);
	}

	/** Returns a point transformed by a matrix, the point at z 0.

		@param v  The point.
		@param mat  The matrix.
		@return  The transformed point's x and y. */
	static function Vector2Transform(v:Vector2, mat:Matrix):Vector2 {
		var x = v.x, y = v.y, z = 0.0;
		return new Vector2(mat.m0 * x + mat.m4 * y + mat.m8 * z + mat.m12, mat.m1 * x + mat.m5 * y + mat.m9 * z + mat.m13);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	static function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float):Vector2 {
		return new Vector2(v1.x + amount * (v2.x - v1.x), v1.y + amount * (v2.y - v1.y));
	}

	/** Returns a direction reflected off a surface.

		@param v  The direction.
		@param normal  The surface's normal, of length 1.
		@return  The reflected direction. */
	static function Vector2Reflect(v:Vector2, normal:Vector2):Vector2 {
		var dotProduct = v.x * normal.x + v.y * normal.y;
		return new Vector2(v.x - (2 * normal.x) * dotProduct, v.y - (2 * normal.y) * dotProduct);
	}

	/** Returns the least of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@return  The vector of the least. */
	static function Vector2Min(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(fminf(v1.x, v2.x), fminf(v1.y, v2.y));
	}

	/** Returns the most of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@return  The vector of the most. */
	static function Vector2Max(v1:Vector2, v2:Vector2):Vector2 {
		return new Vector2(fmaxf(v1.x, v2.x), fmaxf(v1.y, v2.y));
	}

	/** Returns a vector turned by an angle, from x toward y.

		@param v  The vector.
		@param angle  The angle, in radians.
		@return  The turned vector. */
	static function Vector2Rotate(v:Vector2, angle:Float):Vector2 {
		var cosres = Math.cos(angle), sinres = Math.sin(angle);
		return new Vector2(v.x * cosres - v.y * sinres, v.x * sinres + v.y * cosres);
	}

	/** Returns a point moved toward a target by at most a distance.

		Gives the target itself when the target is within that distance.

		@param v  The point.
		@param target  The target.
		@param maxDistance  The most it moves.
		@return  The moved point. */
	static function Vector2MoveTowards(v:Vector2, target:Vector2, maxDistance:Float):Vector2 {
		var dx = target.x - v.x, dy = target.y - v.y;
		var value = dx * dx + dy * dy;
		if (value == 0 || (maxDistance >= 0 && value <= maxDistance * maxDistance))
			return new Vector2(target.x, target.y);
		var dist = Math.sqrt(value);
		return new Vector2(v.x + dx / dist * maxDistance, v.y + dy / dist * maxDistance);
	}

	/** Returns 1 divided by each of a vector's components.

		@param v  The vector.
		@return  The inverted vector. */
	static function Vector2Invert(v:Vector2):Vector2 {
		return new Vector2(1 / v.x, 1 / v.y);
	}

	/** Returns a vector with each component kept between two others'.

		@param v  The vector.
		@param min  The least components.
		@param max  The most.
		@return  The vector. */
	static function Vector2Clamp(v:Vector2, min:Vector2, max:Vector2):Vector2 {
		return new Vector2(fminf(max.x, fmaxf(min.x, v.x)), fminf(max.y, fmaxf(min.y, v.y)));
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

	/** Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.

		@param p  One.
		@param q  The other.
		@return  1 if they are, 0 if not. */
	static function Vector2Equals(p:Vector2, q:Vector2):Int {
		return FloatEquals(p.x, q.x) == 1 && FloatEquals(p.y, q.y) == 1 ? 1 : 0;
	}

	/** Returns a direction bent passing into a surface, or (0, 0) when it is wholly reflected instead.

		@param v  The direction, of length 1.
		@param n  The surface's normal, of length 1.
		@param r  The ratio of the refractive indices, the one it leaves over the one it enters.
		@return  The bent direction. */
	static function Vector2Refract(v:Vector2, n:Vector2, r:Float):Vector2 {
		var dot = v.x * n.x + v.y * n.y;
		var d = 1 - r * r * (1 - dot * dot);
		if (!(d >= 0))
			return new Vector2(0, 0);
		d = Math.sqrt(d);
		return new Vector2(r * v.x - (r * dot + d) * n.x, r * v.y - (r * dot + d) * n.y);
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

	/** Returns a vector with a value added to each component.

		@param v  The vector.
		@param add  The value.
		@return  The sum. */
	static function Vector3AddValue(v:Vector3, add:Float):Vector3 {
		return new Vector3(v.x + add, v.y + add, v.z + add);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	static function Vector3Subtract(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
	}

	/** Returns a vector with a value taken from each component.

		@param v  The vector.
		@param sub  The value.
		@return  The difference. */
	static function Vector3SubtractValue(v:Vector3, sub:Float):Vector3 {
		return new Vector3(v.x - sub, v.y - sub, v.z - sub);
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

	/** Returns a vector perpendicular to another: its cross product with the axis the vector is least along.

		@param v  The vector.
		@return  The perpendicular vector. */
	static function Vector3Perpendicular(v:Vector3):Vector3 {
		var min = Math.abs(v.x);
		var ax = 1.0, ay = 0.0, az = 0.0;
		if (Math.abs(v.y) < min) {
			min = Math.abs(v.y);
			ax = 0;
			ay = 1;
			az = 0;
		}
		if (Math.abs(v.z) < min) {
			ax = 0;
			ay = 0;
			az = 1;
		}
		return new Vector3(v.y * az - v.z * ay, v.z * ax - v.x * az, v.x * ay - v.y * ax);
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

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector3DotProduct(v1:Vector3, v2:Vector3):Float {
		return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static function Vector3Distance(v1:Vector3, v2:Vector3):Float {
		return Vector3Length(Vector3Subtract(v1, v2));
	}

	/** Returns the distance between two points, squared.

		@param v1  One.
		@param v2  The other.
		@return  The distance squared. */
	static function Vector3DistanceSqr(v1:Vector3, v2:Vector3):Float {
		var dx = v2.x - v1.x, dy = v2.y - v1.y, dz = v2.z - v1.z;
		return dx * dx + dy * dy + dz * dz;
	}

	/** Returns the angle between two vectors, from 0 to pi.

		@param v1  One.
		@param v2  The other.
		@return  The angle, in radians. */
	static function Vector3Angle(v1:Vector3, v2:Vector3):Float {
		var cx = v1.y * v2.z - v1.z * v2.y,
			cy = v1.z * v2.x - v1.x * v2.z,
			cz = v1.x * v2.y - v1.y * v2.x;
		var len = Math.sqrt(cx * cx + cy * cy + cz * cz);
		var dot = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
		return Math.atan2(len, dot);
	}

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@return  The negated vector. */
	static function Vector3Negate(v:Vector3):Vector3 {
		return new Vector3(-v.x, -v.y, -v.z);
	}

	/** Returns one vector divided by another, component by component.

		@param v1  The one divided.
		@param v2  The one dividing it.
		@return  The quotient. */
	static function Vector3Divide(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(v1.x / v2.x, v1.y / v2.y, v1.z / v2.z);
	}

	/** Returns a vector of length 1 in the same direction, or the vector itself when its length is 0.

		@param v  The vector.
		@return  The direction. */
	static function Vector3Normalize(v:Vector3):Vector3 {
		var l = Vector3Length(v);
		return l == 0 ? new Vector3(v.x, v.y, v.z) : new Vector3(v.x / l, v.y / l, v.z / l);
	}

	/** Returns the part of one vector along another.

		@param v1  The vector.
		@param v2  The direction it is projected onto.
		@return  The projection. */
	static function Vector3Project(v1:Vector3, v2:Vector3):Vector3 {
		var v1dv2 = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
		var v2dv2 = v2.x * v2.x + v2.y * v2.y + v2.z * v2.z;
		var mag = v1dv2 / v2dv2;
		return new Vector3(v2.x * mag, v2.y * mag, v2.z * mag);
	}

	/** Returns the part of one vector across another: the vector less its projection.

		@param v1  The vector.
		@param v2  The direction taken out of it.
		@return  The rejection. */
	static function Vector3Reject(v1:Vector3, v2:Vector3):Vector3 {
		var v1dv2 = v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
		var v2dv2 = v2.x * v2.x + v2.y * v2.y + v2.z * v2.z;
		var mag = v1dv2 / v2dv2;
		return new Vector3(v1.x - v2.x * mag, v1.y - v2.y * mag, v1.z - v2.z * mag);
	}

	/** Makes two vectors of length 1 and at right angles to each other, the first keeping its direction (Gram-Schmidt).

		@param v1  The first, set to its direction.
		@param v2  The second, set at right angles to the first, in the plane the two were in and on its own side. */
	static function Vector3OrthoNormalize(v1:Vector3, v2:Vector3):Void {
		var length = Math.sqrt(v1.x * v1.x + v1.y * v1.y + v1.z * v1.z);
		if (length == 0)
			length = 1;
		var ilength = 1 / length;
		v1.x *= ilength;
		v1.y *= ilength;
		v1.z *= ilength;
		var nx = v1.y * v2.z - v1.z * v2.y,
			ny = v1.z * v2.x - v1.x * v2.z,
			nz = v1.x * v2.y - v1.y * v2.x;
		length = Math.sqrt(nx * nx + ny * ny + nz * nz);
		if (length == 0)
			length = 1;
		ilength = 1 / length;
		nx *= ilength;
		ny *= ilength;
		nz *= ilength;
		v2.x = ny * v1.z - nz * v1.y;
		v2.y = nz * v1.x - nx * v1.z;
		v2.z = nx * v1.y - ny * v1.x;
	}

	/** Returns a point transformed by a matrix.

		@param v  The point.
		@param mat  The matrix.
		@return  The transformed point. */
	static function Vector3Transform(v:Vector3, mat:Matrix):Vector3 {
		var p = toMatrix3D(mat).transformPoint(v.x, v.y, v.z);
		return new Vector3(p.x, p.y, p.z);
	}

	/** Returns a vector turned by a quaternion.

		@param v  The vector.
		@param q  The quaternion.
		@return  The turned vector. */
	static function Vector3RotateByQuaternion(v:Vector3, q:Quaternion):Vector3 {
		return new Vector3(v.x * (q.x * q.x + q.w * q.w - q.y * q.y - q.z * q.z)
			+ v.y * (2 * q.x * q.y - 2 * q.w * q.z)
			+ v.z * (2 * q.x * q.z + 2 * q.w * q.y),
			v.x * (2 * q.w * q.z + 2 * q.x * q.y)
			+ v.y * (q.w * q.w - q.x * q.x + q.y * q.y - q.z * q.z)
			+ v.z * (-2 * q.w * q.x + 2 * q.y * q.z),
			v.x * (-2 * q.w * q.y + 2 * q.x * q.z)
			+ v.y * (2 * q.w * q.x + 2 * q.y * q.z)
			+ v.z * (q.w * q.w - q.x * q.x - q.y * q.y + q.z * q.z));
	}

	/** Returns a vector turned about an axis.

		@param v  The vector.
		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The turned vector. */
	static function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float):Vector3 {
		var m = Matrix3D.fromRotation(axis.x, axis.y, axis.z, angle);
		var p = m.transformPoint(v.x, v.y, v.z);
		return new Vector3(p.x, p.y, p.z);
	}

	/** Returns a point moved toward a target by at most a distance.

		Gives the target itself when the target is within that distance.

		@param v  The point.
		@param target  The target.
		@param maxDistance  The most it moves.
		@return  The moved point. */
	static function Vector3MoveTowards(v:Vector3, target:Vector3, maxDistance:Float):Vector3 {
		var dx = target.x - v.x, dy = target.y - v.y, dz = target.z - v.z;
		var value = dx * dx + dy * dy + dz * dz;
		if (value == 0 || (maxDistance >= 0 && value <= maxDistance * maxDistance))
			return new Vector3(target.x, target.y, target.z);
		var dist = Math.sqrt(value);
		return new Vector3(v.x + dx / dist * maxDistance, v.y + dy / dist * maxDistance, v.z + dz / dist * maxDistance);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	static function Vector3Lerp(v1:Vector3, v2:Vector3, amount:Float):Vector3 {
		return vector3LerpInto(v1, v2, amount, new Vector3());
	}

	// Vector3Lerp written into a vector, which may be either of the two, so a caller posing every frame allocates none (Animations).
	static function vector3LerpInto(v1:Vector3, v2:Vector3, amount:Float, out:Vector3):Vector3 {
		var x = v1.x + amount * (v2.x - v1.x),
			y = v1.y + amount * (v2.y - v1.y),
			z = v1.z + amount * (v2.z - v1.z);
		out.x = x;
		out.y = y;
		out.z = z;
		return out;
	}

	/** Returns a point part of the way along a cubic Hermite curve, from one point to another, leaving and arriving along tangents.

		@param v1  The start.
		@param tangent1  The tangent leaving it.
		@param v2  The end.
		@param tangent2  The tangent arriving at it.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	static function Vector3CubicHermite(v1:Vector3, tangent1:Vector3, v2:Vector3, tangent2:Vector3, amount:Float):Vector3 {
		var amountPow2 = amount * amount;
		var amountPow3 = amount * amount * amount;
		var h00 = 2 * amountPow3 - 3 * amountPow2 + 1,
			h10 = amountPow3 - 2 * amountPow2 + amount,
			h01 = -2 * amountPow3 + 3 * amountPow2,
			h11 = amountPow3 - amountPow2;
		return new Vector3(h00 * v1.x
			+ h10 * tangent1.x
			+ h01 * v2.x
			+ h11 * tangent2.x, h00 * v1.y
			+ h10 * tangent1.y
			+ h01 * v2.y
			+ h11 * tangent2.y,
			h00 * v1.z
			+ h10 * tangent1.z
			+ h01 * v2.z
			+ h11 * tangent2.z);
	}

	/** Returns a direction reflected off a surface.

		@param v  The direction.
		@param normal  The surface's normal, of length 1.
		@return  The reflected direction. */
	static function Vector3Reflect(v:Vector3, normal:Vector3):Vector3 {
		var dotProduct = v.x * normal.x + v.y * normal.y + v.z * normal.z;
		return new Vector3(v.x - (2 * normal.x) * dotProduct, v.y - (2 * normal.y) * dotProduct, v.z - (2 * normal.z) * dotProduct);
	}

	/** Returns the least of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@return  The vector of the least. */
	static function Vector3Min(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(fminf(v1.x, v2.x), fminf(v1.y, v2.y), fminf(v1.z, v2.z));
	}

	/** Returns the most of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@return  The vector of the most. */
	static function Vector3Max(v1:Vector3, v2:Vector3):Vector3 {
		return new Vector3(fmaxf(v1.x, v2.x), fmaxf(v1.y, v2.y), fmaxf(v1.z, v2.z));
	}

	/** Returns a point's barycentric coordinates in a triangle: how much of each corner it is made of.

		@param p  The point.
		@param a  The first corner.
		@param b  The second.
		@param c  The third.
		@return  How much of a (x), b (y) and c (z). */
	static function Vector3Barycenter(p:Vector3, a:Vector3, b:Vector3, c:Vector3):Vector3 {
		var v0x = b.x - a.x, v0y = b.y - a.y, v0z = b.z - a.z;
		var v1x = c.x - a.x, v1y = c.y - a.y, v1z = c.z - a.z;
		var v2x = p.x - a.x, v2y = p.y - a.y, v2z = p.z - a.z;
		var d00 = v0x * v0x + v0y * v0y + v0z * v0z;
		var d01 = v0x * v1x + v0y * v1y + v0z * v1z;
		var d11 = v1x * v1x + v1y * v1y + v1z * v1z;
		var d20 = v2x * v0x + v2y * v0y + v2z * v0z;
		var d21 = v2x * v1x + v2y * v1y + v2z * v1z;
		var denom = d00 * d11 - d01 * d01;
		var y = (d11 * d20 - d01 * d21) / denom;
		var z = (d00 * d21 - d01 * d20) / denom;
		return new Vector3(1 - (z + y), y, z);
	}

	/** Returns a point in normalized device coordinates (each from -1 to 1) taken back into the world, through a view and a projection.

		@param source  The point.
		@param projection  The projection.
		@param view  The view.
		@return  The point in the world. */
	static function Vector3Unproject(source:Vector3, projection:Matrix, view:Matrix):Vector3 {
		// raymath's own steps, its matrices filled in the order Matrix's fields are declared, as its C initializers fill them.
		var matViewProj = new Matrix(view.m0 * projection.m0
			+ view.m1 * projection.m4
			+ view.m2 * projection.m8
			+ view.m3 * projection.m12,
			view.m0 * projection.m1
			+ view.m1 * projection.m5
			+ view.m2 * projection.m9
			+ view.m3 * projection.m13,
			view.m0 * projection.m2
			+ view.m1 * projection.m6
			+ view.m2 * projection.m10
			+ view.m3 * projection.m14,
			view.m0 * projection.m3
			+ view.m1 * projection.m7
			+ view.m2 * projection.m11
			+ view.m3 * projection.m15,
			view.m4 * projection.m0
			+ view.m5 * projection.m4
			+ view.m6 * projection.m8
			+ view.m7 * projection.m12,
			view.m4 * projection.m1
			+ view.m5 * projection.m5
			+ view.m6 * projection.m9
			+ view.m7 * projection.m13,
			view.m4 * projection.m2
			+ view.m5 * projection.m6
			+ view.m6 * projection.m10
			+ view.m7 * projection.m14,
			view.m4 * projection.m3
			+ view.m5 * projection.m7
			+ view.m6 * projection.m11
			+ view.m7 * projection.m15,
			view.m8 * projection.m0
			+ view.m9 * projection.m4
			+ view.m10 * projection.m8
			+ view.m11 * projection.m12,
			view.m8 * projection.m1
			+ view.m9 * projection.m5
			+ view.m10 * projection.m9
			+ view.m11 * projection.m13,
			view.m8 * projection.m2
			+ view.m9 * projection.m6
			+ view.m10 * projection.m10
			+ view.m11 * projection.m14,
			view.m8 * projection.m3
			+ view.m9 * projection.m7
			+ view.m10 * projection.m11
			+ view.m11 * projection.m15,
			view.m12 * projection.m0
			+ view.m13 * projection.m4
			+ view.m14 * projection.m8
			+ view.m15 * projection.m12,
			view.m12 * projection.m1
			+ view.m13 * projection.m5
			+ view.m14 * projection.m9
			+ view.m15 * projection.m13,
			view.m12 * projection.m2
			+ view.m13 * projection.m6
			+ view.m14 * projection.m10
			+ view.m15 * projection.m14,
			view.m12 * projection.m3
			+ view.m13 * projection.m7
			+ view.m14 * projection.m11
			+ view.m15 * projection.m15);
		var a00 = matViewProj.m0,
			a01 = matViewProj.m1,
			a02 = matViewProj.m2,
			a03 = matViewProj.m3;
		var a10 = matViewProj.m4,
			a11 = matViewProj.m5,
			a12 = matViewProj.m6,
			a13 = matViewProj.m7;
		var a20 = matViewProj.m8,
			a21 = matViewProj.m9,
			a22 = matViewProj.m10,
			a23 = matViewProj.m11;
		var a30 = matViewProj.m12,
			a31 = matViewProj.m13,
			a32 = matViewProj.m14,
			a33 = matViewProj.m15;
		var b00 = a00 * a11 - a01 * a10;
		var b01 = a00 * a12 - a02 * a10;
		var b02 = a00 * a13 - a03 * a10;
		var b03 = a01 * a12 - a02 * a11;
		var b04 = a01 * a13 - a03 * a11;
		var b05 = a02 * a13 - a03 * a12;
		var b06 = a20 * a31 - a21 * a30;
		var b07 = a20 * a32 - a22 * a30;
		var b08 = a20 * a33 - a23 * a30;
		var b09 = a21 * a32 - a22 * a31;
		var b10 = a21 * a33 - a23 * a31;
		var b11 = a22 * a33 - a23 * a32;
		var invDet = 1 / (b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06);
		var matViewProjInv = new Matrix((a11 * b11 - a12 * b10 + a13 * b09) * invDet, (-a01 * b11 + a02 * b10 - a03 * b09) * invDet,
			(a31 * b05 - a32 * b04 + a33 * b03) * invDet, (-a21 * b05 + a22 * b04 - a23 * b03) * invDet, (-a10 * b11 + a12 * b08 - a13 * b07) * invDet,
			(a00 * b11 - a02 * b08 + a03 * b07) * invDet, (-a30 * b05 + a32 * b02 - a33 * b01) * invDet, (a20 * b05 - a22 * b02 + a23 * b01) * invDet,
			(a10 * b10 - a11 * b08 + a13 * b06) * invDet, (-a00 * b10 + a01 * b08 - a03 * b06) * invDet, (a30 * b04 - a31 * b02 + a33 * b00) * invDet,
			(-a20 * b04 + a21 * b02 - a23 * b00) * invDet, (-a10 * b09 + a11 * b07 - a12 * b06) * invDet, (a00 * b09 - a01 * b07 + a02 * b06) * invDet,
			(-a30 * b03 + a31 * b01 - a32 * b00) * invDet, (a20 * b03 - a21 * b01 + a22 * b00) * invDet);
		var q = QuaternionTransform(new Vector4(source.x, source.y, source.z, 1), matViewProjInv);
		return new Vector3(q.x / q.w, q.y / q.w, q.z / q.w);
	}

	/** Returns a vector's components as an array: x, y, z.

		@param v  The vector.
		@return  The array. */
	static function Vector3ToFloatV(v:Vector3):Array<Float> {
		return [v.x, v.y, v.z];
	}

	/** Returns 1 divided by each of a vector's components.

		@param v  The vector.
		@return  The inverted vector. */
	static function Vector3Invert(v:Vector3):Vector3 {
		return new Vector3(1 / v.x, 1 / v.y, 1 / v.z);
	}

	/** Returns a vector with each component kept between two others'.

		@param v  The vector.
		@param min  The least components.
		@param max  The most.
		@return  The vector. */
	static function Vector3Clamp(v:Vector3, min:Vector3, max:Vector3):Vector3 {
		return new Vector3(fminf(max.x, fmaxf(min.x, v.x)), fminf(max.y, fmaxf(min.y, v.y)), fminf(max.z, fmaxf(min.z, v.z)));
	}

	/** Returns a vector with its length kept between two values.

		@param v  The vector.
		@param min  The least length.
		@param max  The most length.
		@return  The vector. */
	static function Vector3ClampValue(v:Vector3, min:Float, max:Float):Vector3 {
		var length = v.x * v.x + v.y * v.y + v.z * v.z;
		if (!(length > 0))
			return new Vector3(v.x, v.y, v.z);
		length = Math.sqrt(length);
		var scale = 1.0;
		if (length < min)
			scale = min / length;
		else if (length > max)
			scale = max / length;
		return new Vector3(v.x * scale, v.y * scale, v.z * scale);
	}

	/** Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.

		@param p  One.
		@param q  The other.
		@return  1 if they are, 0 if not. */
	static function Vector3Equals(p:Vector3, q:Vector3):Int {
		return FloatEquals(p.x, q.x) == 1 && FloatEquals(p.y, q.y) == 1 && FloatEquals(p.z, q.z) == 1 ? 1 : 0;
	}

	/** Returns a direction bent passing into a surface, or (0, 0, 0) when it is wholly reflected instead.

		@param v  The direction, of length 1.
		@param n  The surface's normal, of length 1.
		@param r  The ratio of the refractive indices, the one it leaves over the one it enters.
		@return  The bent direction. */
	static function Vector3Refract(v:Vector3, n:Vector3, r:Float):Vector3 {
		var dot = v.x * n.x + v.y * n.y + v.z * n.z;
		var d = 1 - r * r * (1 - dot * dot);
		if (!(d >= 0))
			return new Vector3(0, 0, 0);
		d = Math.sqrt(d);
		return new Vector3(r * v.x - (r * dot + d) * n.x, r * v.y - (r * dot + d) * n.y, r * v.z - (r * dot + d) * n.z);
	}

	// ---- raymath: Vector4 ----

	/** Returns (0, 0, 0, 0).

		@return  The vector. */
	static function Vector4Zero():Vector4 {
		return new Vector4(0, 0, 0, 0);
	}

	/** Returns (1, 1, 1, 1).

		@return  The vector. */
	static function Vector4One():Vector4 {
		return new Vector4(1, 1, 1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@return  The sum. */
	static function Vector4Add(v1:Vector4, v2:Vector4):Vector4 {
		return new Vector4(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z, v1.w + v2.w);
	}

	/** Returns a vector with a value added to each component.

		@param v  The vector.
		@param add  The value.
		@return  The sum. */
	static function Vector4AddValue(v:Vector4, add:Float):Vector4 {
		return new Vector4(v.x + add, v.y + add, v.z + add, v.w + add);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one taken from it.
		@return  The difference. */
	static function Vector4Subtract(v1:Vector4, v2:Vector4):Vector4 {
		return new Vector4(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z, v1.w - v2.w);
	}

	/** Returns a vector with a value taken from each component.

		@param v  The vector.
		@param add  The value.
		@return  The difference. */
	static function Vector4SubtractValue(v:Vector4, add:Float):Vector4 {
		return new Vector4(v.x - add, v.y - add, v.z - add, v.w - add);
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	static function Vector4Length(v:Vector4):Float {
		return Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w);
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	static function Vector4LengthSqr(v:Vector4):Float {
		return v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w;
	}

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector4DotProduct(v1:Vector4, v2:Vector4):Float {
		return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z + v1.w * v2.w;
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static function Vector4Distance(v1:Vector4, v2:Vector4):Float {
		return Math.sqrt((v1.x - v2.x) * (v1.x - v2.x)
			+ (v1.y - v2.y) * (v1.y - v2.y)
			+ (v1.z - v2.z) * (v1.z - v2.z)
			+ (v1.w - v2.w) * (v1.w - v2.w));
	}

	/** Returns the distance between two points, squared.

		@param v1  One.
		@param v2  The other.
		@return  The distance squared. */
	static function Vector4DistanceSqr(v1:Vector4, v2:Vector4):Float {
		return (v1.x
			- v2.x) * (v1.x - v2.x)
			+ (v1.y - v2.y) * (v1.y - v2.y)
			+ (v1.z - v2.z) * (v1.z - v2.z)
			+ (v1.w - v2.w) * (v1.w - v2.w);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scale  The scale.
		@return  The scaled vector. */
	static function Vector4Scale(v:Vector4, scale:Float):Vector4 {
		return new Vector4(v.x * scale, v.y * scale, v.z * scale, v.w * scale);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static function Vector4Multiply(v1:Vector4, v2:Vector4):Vector4 {
		return new Vector4(v1.x * v2.x, v1.y * v2.y, v1.z * v2.z, v1.w * v2.w);
	}

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@return  The negated vector. */
	static function Vector4Negate(v:Vector4):Vector4 {
		return new Vector4(-v.x, -v.y, -v.z, -v.w);
	}

	/** Returns one vector divided by another, component by component.

		@param v1  The one divided.
		@param v2  The one dividing it.
		@return  The quotient. */
	static function Vector4Divide(v1:Vector4, v2:Vector4):Vector4 {
		return new Vector4(v1.x / v2.x, v1.y / v2.y, v1.z / v2.z, v1.w / v2.w);
	}

	/** Returns a vector of length 1 in the same direction, or (0, 0, 0, 0) for (0, 0, 0, 0).

		@param v  The vector.
		@return  The direction. */
	static function Vector4Normalize(v:Vector4):Vector4 {
		var length = Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w);
		if (!(length > 0))
			return new Vector4(0, 0, 0, 0);
		var ilength = 1 / length;
		return new Vector4(v.x * ilength, v.y * ilength, v.z * ilength, v.w * ilength);
	}

	/** Returns the least of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@return  The vector of the least. */
	static function Vector4Min(v1:Vector4, v2:Vector4):Vector4 {
		return new Vector4(fminf(v1.x, v2.x), fminf(v1.y, v2.y), fminf(v1.z, v2.z), fminf(v1.w, v2.w));
	}

	/** Returns the most of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@return  The vector of the most. */
	static function Vector4Max(v1:Vector4, v2:Vector4):Vector4 {
		return new Vector4(fmaxf(v1.x, v2.x), fmaxf(v1.y, v2.y), fmaxf(v1.z, v2.z), fmaxf(v1.w, v2.w));
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The point. */
	static function Vector4Lerp(v1:Vector4, v2:Vector4, amount:Float):Vector4 {
		return new Vector4(v1.x
			+ amount * (v2.x - v1.x), v1.y
			+ amount * (v2.y - v1.y), v1.z
			+ amount * (v2.z - v1.z), v1.w
			+ amount * (v2.w - v1.w));
	}

	/** Returns a point moved toward a target by at most a distance.

		Gives the target itself when the target is within that distance.

		@param v  The point.
		@param target  The target.
		@param maxDistance  The most it moves.
		@return  The moved point. */
	static function Vector4MoveTowards(v:Vector4, target:Vector4, maxDistance:Float):Vector4 {
		var dx = target.x - v.x,
			dy = target.y - v.y,
			dz = target.z - v.z,
			dw = target.w - v.w;
		var value = dx * dx + dy * dy + dz * dz + dw * dw;
		if (value == 0 || (maxDistance >= 0 && value <= maxDistance * maxDistance))
			return new Vector4(target.x, target.y, target.z, target.w);
		var dist = Math.sqrt(value);
		return new Vector4(v.x
			+ dx / dist * maxDistance, v.y
			+ dy / dist * maxDistance, v.z
			+ dz / dist * maxDistance, v.w
			+ dw / dist * maxDistance);
	}

	/** Returns 1 divided by each of a vector's components.

		@param v  The vector.
		@return  The inverted vector. */
	static function Vector4Invert(v:Vector4):Vector4 {
		return new Vector4(1 / v.x, 1 / v.y, 1 / v.z, 1 / v.w);
	}

	/** Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.

		@param p  One.
		@param q  The other.
		@return  1 if they are, 0 if not. */
	static function Vector4Equals(p:Vector4, q:Vector4):Int {
		return FloatEquals(p.x, q.x) == 1 && FloatEquals(p.y, q.y) == 1 && FloatEquals(p.z, q.z) == 1 && FloatEquals(p.w, q.w) == 1 ? 1 : 0;
	}

	// ---- raymath: Matrix ----

	/** Returns a matrix's determinant.

		@param mat  The matrix.
		@return  The determinant. */
	static function MatrixDeterminant(mat:Matrix):Float {
		var a00 = mat.m0, a01 = mat.m1, a02 = mat.m2, a03 = mat.m3;
		var a10 = mat.m4, a11 = mat.m5, a12 = mat.m6, a13 = mat.m7;
		var a20 = mat.m8, a21 = mat.m9, a22 = mat.m10, a23 = mat.m11;
		var a30 = mat.m12, a31 = mat.m13, a32 = mat.m14, a33 = mat.m15;
		return a30 * a21 * a12 * a03 - a20 * a31 * a12 * a03 - a30 * a11 * a22 * a03 + a10 * a31 * a22 * a03 + a20 * a11 * a32 * a03 - a10 * a21 * a32 * a03
			- a30 * a21 * a02 * a13 + a20 * a31 * a02 * a13 + a30 * a01 * a22 * a13 - a00 * a31 * a22 * a13 - a20 * a01 * a32 * a13 + a00 * a21 * a32 * a13
			+ a30 * a11 * a02 * a23 - a10 * a31 * a02 * a23 - a30 * a01 * a12 * a23 + a00 * a31 * a12 * a23 + a10 * a01 * a32 * a23 - a00 * a11 * a32 * a23
			- a20 * a11 * a02 * a33 + a10 * a21 * a02 * a33 + a20 * a01 * a12 * a33 - a00 * a21 * a12 * a33 - a10 * a01 * a22 * a33 + a00 * a11 * a22 * a33;
	}

	/** Returns a matrix's trace: the sum of its diagonal.

		@param mat  The matrix.
		@return  The trace. */
	static function MatrixTrace(mat:Matrix):Float {
		return mat.m0 + mat.m5 + mat.m10 + mat.m15;
	}

	/** Returns a matrix transposed.

		@param mat  The matrix.
		@return  Its transpose. */
	static function MatrixTranspose(mat:Matrix):Matrix {
		return toMatrix(toMatrix3D(mat).transpose());
	}

	/** Returns a matrix's inverse.

		Inverting a singular matrix divides by a determinant of 0 and gives infinite or NaN values.

		@param mat  The matrix.
		@return  Its inverse. */
	static function MatrixInvert(mat:Matrix):Matrix {
		var a00 = mat.m0, a01 = mat.m1, a02 = mat.m2, a03 = mat.m3;
		var a10 = mat.m4, a11 = mat.m5, a12 = mat.m6, a13 = mat.m7;
		var a20 = mat.m8, a21 = mat.m9, a22 = mat.m10, a23 = mat.m11;
		var a30 = mat.m12, a31 = mat.m13, a32 = mat.m14, a33 = mat.m15;
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
		var invDet = 1.0 / (b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06);
		var result = new Matrix();
		result.m0 = (a11 * b11 - a12 * b10 + a13 * b09) * invDet;
		result.m1 = (-a01 * b11 + a02 * b10 - a03 * b09) * invDet;
		result.m2 = (a31 * b05 - a32 * b04 + a33 * b03) * invDet;
		result.m3 = (-a21 * b05 + a22 * b04 - a23 * b03) * invDet;
		result.m4 = (-a10 * b11 + a12 * b08 - a13 * b07) * invDet;
		result.m5 = (a00 * b11 - a02 * b08 + a03 * b07) * invDet;
		result.m6 = (-a30 * b05 + a32 * b02 - a33 * b01) * invDet;
		result.m7 = (a20 * b05 - a22 * b02 + a23 * b01) * invDet;
		result.m8 = (a10 * b10 - a11 * b08 + a13 * b06) * invDet;
		result.m9 = (-a00 * b10 + a01 * b08 - a03 * b06) * invDet;
		result.m10 = (a30 * b04 - a31 * b02 + a33 * b00) * invDet;
		result.m11 = (-a20 * b04 + a21 * b02 - a23 * b00) * invDet;
		result.m12 = (-a10 * b09 + a11 * b07 - a12 * b06) * invDet;
		result.m13 = (a00 * b09 - a01 * b07 + a02 * b06) * invDet;
		result.m14 = (-a30 * b03 + a31 * b01 - a32 * b00) * invDet;
		result.m15 = (a20 * b03 - a21 * b01 + a22 * b00) * invDet;
		return result;
	}

	/** Returns the identity matrix.

		@return  The matrix. */
	static function MatrixIdentity():Matrix {
		return toMatrix(new Matrix3D());
	}

	/** Returns the sum of two matrices.

		@param left  One.
		@param right  The other.
		@return  The sum. */
	static function MatrixAdd(left:Matrix, right:Matrix):Matrix {
		return new Matrix(left.m0
			+ right.m0, left.m4
			+ right.m4, left.m8
			+ right.m8, left.m12
			+ right.m12, left.m1
			+ right.m1, left.m5
			+ right.m5,
			left.m9
			+ right.m9, left.m13
			+ right.m13, left.m2
			+ right.m2, left.m6
			+ right.m6, left.m10
			+ right.m10, left.m14
			+ right.m14, left.m3
			+ right.m3,
			left.m7
			+ right.m7, left.m11
			+ right.m11, left.m15
			+ right.m15);
	}

	/** Returns one matrix less another.

		@param left  The first.
		@param right  The one taken from it.
		@return  The difference. */
	static function MatrixSubtract(left:Matrix, right:Matrix):Matrix {
		return new Matrix(left.m0
			- right.m0, left.m4
			- right.m4, left.m8
			- right.m8, left.m12
			- right.m12, left.m1
			- right.m1, left.m5
			- right.m5,
			left.m9
			- right.m9, left.m13
			- right.m13, left.m2
			- right.m2, left.m6
			- right.m6, left.m10
			- right.m10, left.m14
			- right.m14, left.m3
			- right.m3,
			left.m7
			- right.m7, left.m11
			- right.m11, left.m15
			- right.m15);
	}

	/** Returns two matrices multiplied: left, then right.

		@param left  The first.
		@param right  The second.
		@return  The product. */
	static function MatrixMultiply(left:Matrix, right:Matrix):Matrix {
		return toMatrix(Matrix3D.compose(toMatrix3D(left), toMatrix3D(right)));
	}

	/** Returns a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	static function MatrixTranslate(x:Float, y:Float, z:Float):Matrix {
		return toMatrix(Matrix3D.fromTranslation(x, y, z));
	}

	/** Returns a rotation about an axis.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotate(axis:Vector3, angle:Float):Matrix {
		return toMatrix(Matrix3D.fromRotation(axis.x, axis.y, axis.z, angle));
	}

	/** Returns a rotation about x.

		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotateX(angle:Float):Matrix {
		return toMatrix(Matrix3D.fromRotation(1, 0, 0, angle));
	}

	/** Returns a rotation about y.

		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotateY(angle:Float):Matrix {
		return toMatrix(Matrix3D.fromRotation(0, 1, 0, angle));
	}

	/** Returns a rotation about z.

		@param angle  The angle, in radians.
		@return  The matrix. */
	static function MatrixRotateZ(angle:Float):Matrix {
		return toMatrix(Matrix3D.fromRotation(0, 0, 1, angle));
	}

	/** Returns a rotation by three angles that turns a point about z, then y, then x. See `MatrixRotateZYX` for turning in the reverse
		order.

		@param angle  The angles, in radians.
		@return  The matrix. */
	static function MatrixRotateXYZ(angle:Vector3):Matrix {
		var cosz = Math.cos(-angle.z), sinz = Math.sin(-angle.z);
		var cosy = Math.cos(-angle.y), siny = Math.sin(-angle.y);
		var cosx = Math.cos(-angle.x), sinx = Math.sin(-angle.x);
		var result = toMatrix(new Matrix3D());
		result.m0 = cosz * cosy;
		result.m1 = (cosz * siny * sinx) - (sinz * cosx);
		result.m2 = (cosz * siny * cosx) + (sinz * sinx);
		result.m4 = sinz * cosy;
		result.m5 = (sinz * siny * sinx) + (cosz * cosx);
		result.m6 = (sinz * siny * cosx) - (cosz * sinx);
		result.m8 = -siny;
		result.m9 = cosy * sinx;
		result.m10 = cosy * cosx;
		return result;
	}

	/** Returns rotations about z, then y, then x.

		@param angle  The angles, in radians.
		@return  The matrix. */
	static function MatrixRotateZYX(angle:Vector3):Matrix {
		var cz = Math.cos(angle.z), sz = Math.sin(angle.z);
		var cy = Math.cos(angle.y), sy = Math.sin(angle.y);
		var cx = Math.cos(angle.x), sx = Math.sin(angle.x);
		return new Matrix(cz * cy, cz * sy * sx
			- cx * sz, sz * sx
			+ cz * cx * sy, 0, cy * sz, cz * cx
			+ sz * sy * sx, cx * sz * sy
			- cz * sx, 0,
			-sy,
			cy * sx, cy * cx, 0, 0, 0, 0, 1);
	}

	/** Returns a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@return  The matrix. */
	static function MatrixScale(x:Float, y:Float, z:Float):Matrix {
		return toMatrix(Matrix3D.fromScale(x, y, z));
	}

	/** Returns a perspective projection by its near plane's edges.

		@param left  The near plane's left.
		@param right  Its right.
		@param bottom  Its bottom.
		@param top  Its top.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@return  The matrix. */
	static function MatrixFrustum(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float):Matrix {
		var rl = right - left, tb = top - bottom, fn = farPlane - nearPlane;
		return new Matrix((nearPlane * 2) / rl, 0, (right + left) / rl, 0, 0, (nearPlane * 2) / tb, (top + bottom) / tb, 0, 0, 0,
			-(farPlane + nearPlane) / fn, -(farPlane * nearPlane * 2) / fn, 0, 0, -1, 0);
	}

	/** Returns a perspective projection.

		@param fovY  The field of view, top to bottom, in radians.
		@param aspect  Width over height.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@return  The matrix. */
	static function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float):Matrix {
		return toMatrix(Matrix3D.fromPerspective(fovY, aspect, nearPlane, farPlane));
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
		return toMatrix(Matrix3D.fromOrthographic(left, right, bottom, top, nearPlane, farPlane));
	}

	/** Returns a view looking from eye at target.

		@param eye  Where from.
		@param target  What at.
		@param up  Up.
		@return  The matrix. */
	static function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3):Matrix {
		return toMatrix(Matrix3D.fromLookAt(eye.x, eye.y, eye.z, target.x, target.y, target.z, up.x, up.y, up.z));
	}

	/** Returns a matrix's values as an array, by columns: m0 to m15, as a shader takes them.

		@param mat  The matrix.
		@return  The array. */
	static function MatrixToFloatV(mat:Matrix):Array<Float> {
		return [
			mat.m0, mat.m1, mat.m2, mat.m3, mat.m4, mat.m5, mat.m6, mat.m7, mat.m8, mat.m9, mat.m10, mat.m11, mat.m12, mat.m13, mat.m14, mat.m15
		];
	}

	// ---- raymath: Quaternion ----

	/** Returns the sum of two quaternions.

		@param q1  One.
		@param q2  The other.
		@return  The sum. */
	static function QuaternionAdd(q1:Quaternion, q2:Quaternion):Quaternion {
		return new Vector4(q1.x + q2.x, q1.y + q2.y, q1.z + q2.z, q1.w + q2.w);
	}

	/** Returns a quaternion with a value added to each component.

		@param q  The quaternion.
		@param add  The value.
		@return  The sum. */
	static function QuaternionAddValue(q:Quaternion, add:Float):Quaternion {
		return new Vector4(q.x + add, q.y + add, q.z + add, q.w + add);
	}

	/** Returns one quaternion less another.

		@param q1  The first.
		@param q2  The one taken from it.
		@return  The difference. */
	static function QuaternionSubtract(q1:Quaternion, q2:Quaternion):Quaternion {
		return new Vector4(q1.x - q2.x, q1.y - q2.y, q1.z - q2.z, q1.w - q2.w);
	}

	/** Returns a quaternion with a value taken from each component.

		@param q  The quaternion.
		@param sub  The value.
		@return  The difference. */
	static function QuaternionSubtractValue(q:Quaternion, sub:Float):Quaternion {
		return new Vector4(q.x - sub, q.y - sub, q.z - sub, q.w - sub);
	}

	/** Returns the identity quaternion.

		@return  The quaternion. */
	static function QuaternionIdentity():Quaternion {
		return new Vector4(0, 0, 0, 1);
	}

	/** Returns a quaternion's length.

		@param q  The quaternion.
		@return  The length. */
	static function QuaternionLength(q:Quaternion):Float {
		return Math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
	}

	/** Returns a quaternion of length 1 in the same direction, or the quaternion itself when its length is 0.

		@param q  The quaternion.
		@return  The normalized quaternion. */
	static function QuaternionNormalize(q:Quaternion):Quaternion {
		var length = Math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w);
		if (length == 0)
			length = 1;
		var ilength = 1 / length;
		return new Vector4(q.x * ilength, q.y * ilength, q.z * ilength, q.w * ilength);
	}

	/** Returns a quaternion's inverse, which for a quaternion of length 1 is the rotation back.

		Gives the quaternion unchanged when its length is 0.

		@param q  The quaternion.
		@return  Its inverse. */
	static function QuaternionInvert(q:Quaternion):Quaternion {
		var lengthSq = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;
		if (lengthSq == 0)
			return new Vector4(q.x, q.y, q.z, q.w);
		var invLength = 1 / lengthSq;
		return new Vector4(q.x * -invLength, q.y * -invLength, q.z * -invLength, q.w * invLength);
	}

	/** Returns two quaternions multiplied: the rotation q2, then q1.

		@param q1  The first.
		@param q2  The second.
		@return  The product. */
	static function QuaternionMultiply(q1:Quaternion, q2:Quaternion):Quaternion {
		var qax = q1.x, qay = q1.y, qaz = q1.z, qaw = q1.w;
		var qbx = q2.x, qby = q2.y, qbz = q2.z, qbw = q2.w;
		return new Vector4(qax * qbw
			+ qaw * qbx
			+ qay * qbz
			- qaz * qby, qay * qbw
			+ qaw * qby
			+ qaz * qbx
			- qax * qbz,
			qaz * qbw
			+ qaw * qbz
			+ qax * qby
			- qay * qbx, qaw * qbw
			- qax * qbx
			- qay * qby
			- qaz * qbz);
	}

	/** Returns a quaternion scaled.

		@param q  The quaternion.
		@param mul  The scale.
		@return  The scaled quaternion. */
	static function QuaternionScale(q:Quaternion, mul:Float):Quaternion {
		return new Vector4(q.x * mul, q.y * mul, q.z * mul, q.w * mul);
	}

	/** Returns one quaternion divided by another, component by component.

		@param q1  The one divided.
		@param q2  The one dividing it.
		@return  The quotient. */
	static function QuaternionDivide(q1:Quaternion, q2:Quaternion):Quaternion {
		return new Vector4(q1.x / q2.x, q1.y / q2.y, q1.z / q2.z, q1.w / q2.w);
	}

	/** Returns a quaternion part of the way from one to another, component by component.

		@param q1  The start.
		@param q2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The quaternion. */
	static function QuaternionLerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion {
		return new Vector4(q1.x
			+ amount * (q2.x - q1.x), q1.y
			+ amount * (q2.y - q1.y), q1.z
			+ amount * (q2.z - q1.z), q1.w
			+ amount * (q2.w - q1.w));
	}

	/** Returns a quaternion part of the way from one to another, component by component, then normalized.

		@param q1  The start.
		@param q2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The quaternion. */
	static function QuaternionNlerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion {
		return QuaternionNormalize(QuaternionLerp(q1, q2, amount));
	}

	/** Returns a rotation part of the way from one to another at a steady turn, the short way round (spherical linear interpolation).

		@param q1  The start.
		@param q2  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The quaternion. */
	static function QuaternionSlerp(q1:Quaternion, q2:Quaternion, amount:Float):Quaternion {
		return quaternionSlerpInto(q1, q2, amount, new Vector4());
	}

	// QuaternionSlerp written into a quaternion, which may be either of the two, so a caller posing every frame allocates none
	// (Animations).
	static function quaternionSlerpInto(q1:Quaternion, q2:Quaternion, amount:Float, out:Quaternion):Quaternion {
		var x2 = q2.x, y2 = q2.y, z2 = q2.z, w2 = q2.w;
		var cosHalfTheta = q1.x * x2 + q1.y * y2 + q1.z * z2 + q1.w * w2;
		if (cosHalfTheta < 0) {
			x2 = -x2;
			y2 = -y2;
			z2 = -z2;
			w2 = -w2;
			cosHalfTheta = -cosHalfTheta;
		}
		// Whether they are one rotation is decided as C's floats find it, each product and sum rounded to a float: rotations that close
		// are the same one to raylib, which keeps the first.
		if (Math.abs(f32(f32(f32(f32(f32(q1.x) * f32(q2.x)) + f32(f32(q1.y) * f32(q2.y))) + f32(f32(q1.z) * f32(q2.z))) + f32(f32(q1.w) * f32(q2.w)))) >= 1)
			return set4(out, q1.x, q1.y, q1.z, q1.w);
		if (cosHalfTheta > .95) {
			// QuaternionNlerp's: lerped, then normalized as QuaternionNormalize does.
			var x = q1.x + amount * (x2 - q1.x),
				y = q1.y + amount * (y2 - q1.y),
				z = q1.z + amount * (z2 - q1.z),
				w = q1.w + amount * (w2 - q1.w);
			var length = Math.sqrt(x * x + y * y + z * z + w * w);
			if (length == 0)
				length = 1;
			var ilength = 1 / length;
			return set4(out, x * ilength, y * ilength, z * ilength, w * ilength);
		}
		var halfTheta = Math.acos(cosHalfTheta);
		var sinHalfTheta = Math.sqrt(1 - cosHalfTheta * cosHalfTheta);
		if (Math.abs(sinHalfTheta) < Raymath.EPSILON)
			return set4(out, q1.x * .5 + x2 * .5, q1.y * .5 + y2 * .5, q1.z * .5 + z2 * .5, q1.w * .5 + w2 * .5);
		var ratioA = Math.sin((1 - amount) * halfTheta) / sinHalfTheta;
		var ratioB = Math.sin(amount * halfTheta) / sinHalfTheta;
		return set4(out, q1.x * ratioA + x2 * ratioB, q1.y * ratioA + y2 * ratioB, q1.z * ratioA + z2 * ratioB, q1.w * ratioA + w2 * ratioB);
	}

	// Sets a quaternion's four numbers and returns it.
	static inline function set4(out:Quaternion, x:Float, y:Float, z:Float, w:Float):Quaternion {
		out.x = x;
		out.y = y;
		out.z = z;
		out.w = w;
		return out;
	}

	/** Returns a rotation part of the way along a cubic Hermite curve, from one quaternion to another, leaving and arriving along tangents,
		normalized.

		@param q1  The start.
		@param outTangent1  The tangent leaving it.
		@param q2  The end.
		@param inTangent2  The tangent arriving at it.
		@param t  0 for the start, 1 for the end.
		@return  The quaternion. */
	static function QuaternionCubicHermiteSpline(q1:Quaternion, outTangent1:Quaternion, q2:Quaternion, inTangent2:Quaternion, t:Float):Quaternion {
		var t2 = t * t;
		var t3 = t2 * t;
		var h00 = 2 * t3 - 3 * t2 + 1;
		var h10 = t3 - 2 * t2 + t;
		var h01 = -2 * t3 + 3 * t2;
		var h11 = t3 - t2;
		var p0 = QuaternionScale(q1, h00);
		var m0 = QuaternionScale(outTangent1, h10);
		var p1 = QuaternionScale(q2, h01);
		var m1 = QuaternionScale(inTangent2, h11);
		return QuaternionNormalize(QuaternionAdd(QuaternionAdd(QuaternionAdd(p0, m0), p1), m1));
	}

	/** Returns the rotation turning one direction to another.

		Takes directions of any length.

		Opposite directions give half a turn about a direction square to the first.

		@param from  The direction turned from.
		@param to  The direction turned to.
		@return  The quaternion, of length 1; all 0 when either direction is. */
	static function QuaternionFromVector3ToVector3(from:Vector3, to:Vector3):Quaternion {
		var cos2Theta = from.x * to.x + from.y * to.y + from.z * to.z;
		var cross = new Vector3(from.y * to.z - from.z * to.y, from.z * to.x - from.x * to.z, from.x * to.y - from.y * to.x);
		// The two lengths multiplied.
		var lengths = Math.sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z + cos2Theta * cos2Theta);
		var result = new Vector4(cross.x, cross.y, cross.z, lengths + cos2Theta);
		// Opposite directions: their cross product is 0, so half a turn about a direction square to the first.
		if (lengths > 0 && result.w <= lengths * Raymath.EPSILON) {
			if (Math.abs(from.x) > Math.abs(from.z)) {
				result.x = -from.y;
				result.y = from.x;
				result.z = 0;
			} else {
				result.x = 0;
				result.y = -from.z;
				result.z = from.y;
			}
			result.w = 0;
		}
		return QuaternionNormalize(result);
	}

	/** Returns a rotation matrix's rotation as a quaternion.

		@param mat  The matrix.
		@return  The quaternion. */
	static function QuaternionFromMatrix(mat:Matrix):Quaternion {
		var fourWSquaredMinus1 = mat.m0 + mat.m5 + mat.m10;
		var fourXSquaredMinus1 = mat.m0 - mat.m5 - mat.m10;
		var fourYSquaredMinus1 = mat.m5 - mat.m0 - mat.m10;
		var fourZSquaredMinus1 = mat.m10 - mat.m0 - mat.m5;
		var biggestIndex = 0;
		var fourBiggestSquaredMinus1 = fourWSquaredMinus1;
		if (fourXSquaredMinus1 > fourBiggestSquaredMinus1) {
			fourBiggestSquaredMinus1 = fourXSquaredMinus1;
			biggestIndex = 1;
		}
		if (fourYSquaredMinus1 > fourBiggestSquaredMinus1) {
			fourBiggestSquaredMinus1 = fourYSquaredMinus1;
			biggestIndex = 2;
		}
		if (fourZSquaredMinus1 > fourBiggestSquaredMinus1) {
			fourBiggestSquaredMinus1 = fourZSquaredMinus1;
			biggestIndex = 3;
		}
		var biggestVal = Math.sqrt(fourBiggestSquaredMinus1 + 1) * .5;
		var mult = .25 / biggestVal;
		return switch biggestIndex {
			case 0: new Vector4((mat.m6 - mat.m9) * mult, (mat.m8 - mat.m2) * mult, (mat.m1 - mat.m4) * mult, biggestVal);
			case 1: new Vector4(biggestVal, (mat.m1 + mat.m4) * mult, (mat.m8 + mat.m2) * mult, (mat.m6 - mat.m9) * mult);
			case 2: new Vector4((mat.m1 + mat.m4) * mult, biggestVal, (mat.m6 + mat.m9) * mult, (mat.m8 - mat.m2) * mult);
			case _: new Vector4((mat.m8 + mat.m2) * mult, (mat.m6 + mat.m9) * mult, biggestVal, (mat.m1 - mat.m4) * mult);
		}
	}

	/** Returns a quaternion's rotation as a matrix.

		@param q  The quaternion.
		@return  The matrix. */
	static function QuaternionToMatrix(q:Quaternion):Matrix {
		return toMatrix(Matrix3D.fromQuaternion(q.x, q.y, q.z, q.w));
	}

	/** Returns the rotation about an axis as a quaternion, normalized.

		Gives the identity for an axis of length 0.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@return  The quaternion. */
	static function QuaternionFromAxisAngle(axis:Vector3, angle:Float):Quaternion {
		var axisLength = Math.sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z);
		if (axisLength == 0)
			return new Vector4(0, 0, 0, 1);
		var x = axis.x / axisLength,
			y = axis.y / axisLength,
			z = axis.z / axisLength;
		var s = Math.sin(angle / 2), c = Math.cos(angle / 2);
		var qx = x * s, qy = y * s, qz = z * s, qw = c;
		var length = Math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw);
		if (length == 0)
			length = 1;
		return new Vector4(qx / length, qy / length, qz / length, qw / length);
	}

	/** Finds a quaternion's rotation as an axis and an angle about it.

		Gives x as the axis when the angle is 0.

		@param q  The quaternion, normalized first when its w is over 1 either way.
		@param outAxis  Its first element is set to the axis, of length 1.
		@param outAngle  Its first element is set to the angle, in radians. */
	static function QuaternionToAxisAngle(q:Quaternion, outAxis:Array<Vector3>, outAngle:Array<Float>):Void {
		var x = q.x, y = q.y, z = q.z, w = q.w;
		if (Math.abs(w) > 1) {
			var length = Math.sqrt(x * x + y * y + z * z + w * w);
			if (length == 0)
				length = 1;
			var ilength = 1 / length;
			x = x * ilength;
			y = y * ilength;
			z = z * ilength;
			w = w * ilength;
		}
		var resAxis = new Vector3(0, 0, 0);
		var resAngle = 2 * Math.acos(w);
		var den = Math.sqrt(1 - w * w);
		if (den > Raymath.EPSILON) {
			resAxis.x = x / den;
			resAxis.y = y / den;
			resAxis.z = z / den;
		} else
			resAxis.x = 1;
		outAxis[0] = resAxis;
		outAngle[0] = resAngle;
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

	/** Returns a quaternion's rotation as Euler angles: about x (pitch), y (yaw) and z (roll), as `QuaternionFromEuler` takes them.

		@param q  The quaternion.
		@return  The angles, in radians. */
	static function QuaternionToEuler(q:Quaternion):Vector3 {
		var x0 = 2 * (q.w * q.x + q.y * q.z);
		var x1 = 1 - 2 * (q.x * q.x + q.y * q.y);
		var y0 = 2 * (q.w * q.y - q.z * q.x);
		y0 = y0 > 1 ? 1 : y0;
		y0 = y0 < -1 ? -1 : y0;
		var z0 = 2 * (q.w * q.z + q.x * q.y);
		var z1 = 1 - 2 * (q.y * q.y + q.z * q.z);
		return new Vector3(Math.atan2(x0, x1), Math.asin(y0), Math.atan2(z0, z1));
	}

	/** Returns a quaternion's four components transformed by a matrix, as a point with w.

		@param q  The quaternion.
		@param mat  The matrix.
		@return  The transformed quaternion. */
	static function QuaternionTransform(q:Quaternion, mat:Matrix):Quaternion {
		return new Vector4(mat.m0 * q.x
			+ mat.m4 * q.y
			+ mat.m8 * q.z
			+ mat.m12 * q.w, mat.m1 * q.x
			+ mat.m5 * q.y
			+ mat.m9 * q.z
			+ mat.m13 * q.w,
			mat.m2 * q.x
			+ mat.m6 * q.y
			+ mat.m10 * q.z
			+ mat.m14 * q.w, mat.m3 * q.x
			+ mat.m7 * q.y
			+ mat.m11 * q.z
			+ mat.m15 * q.w);
	}

	/** Returns whether two quaternions are the same rotation but for rounding: equal as `FloatEquals` compares each component, or one
		the other negated.

		@param p  One.
		@param q  The other.
		@return  1 if they are, 0 if not. */
	static function QuaternionEquals(p:Quaternion, q:Quaternion):Int {
		var same = FloatEquals(p.x, q.x) == 1 && FloatEquals(p.y, q.y) == 1 && FloatEquals(p.z, q.z) == 1 && FloatEquals(p.w, q.w) == 1;
		var negated = FloatEquals(p.x, -q.x) == 1 && FloatEquals(p.y, -q.y) == 1 && FloatEquals(p.z, -q.z) == 1 && FloatEquals(p.w, -q.w) == 1;
		return same || negated ? 1 : 0;
	}

	/** Splits a transform matrix into its translation, rotation and scale.

		Makes the columns orthonormal one after another. The orthonormal columns are the rotation, and their lengths are the scale.

		Drops any shear between the columns.

		Decomposing a matrix that mirrors negates all three components of the scale.

		@param mat  The matrix.
		@param translation  Set to its translation.
		@param rotation  Set to its rotation.
		@param scale  Set to its scale. */
	static function MatrixDecompose(mat:Matrix, translation:Vector3, rotation:Quaternion, scale:Vector3):Void {
		var eps = 1e-9;
		translation.x = mat.m12;
		translation.y = mat.m13;
		translation.z = mat.m14;
		var columns = [
			new Vector3(mat.m0, mat.m1, mat.m2),
			new Vector3(mat.m4, mat.m5, mat.m6),
			new Vector3(mat.m8, mat.m9, mat.m10)
		];
		var shear = [0., 0., 0.];
		var scl = new Vector3();
		// Dividing by the largest element first keeps it stable.
		var stabilizer = eps;
		for (c in columns) {
			stabilizer = fmaxf(stabilizer, Math.abs(c.x));
			stabilizer = fmaxf(stabilizer, Math.abs(c.y));
			stabilizer = fmaxf(stabilizer, Math.abs(c.z));
		}
		for (i in 0...3)
			columns[i] = Vector3Scale(columns[i], 1 / stabilizer);
		scl.x = Vector3Length(columns[0]);
		if (scl.x > eps)
			columns[0] = Vector3Scale(columns[0], 1 / scl.x);
		// The second column made orthogonal to the first.
		shear[0] = Vector3DotProduct(columns[0], columns[1]);
		columns[1] = Vector3Subtract(columns[1], Vector3Scale(columns[0], shear[0]));
		scl.y = Vector3Length(columns[1]);
		if (scl.y > eps) {
			columns[1] = Vector3Scale(columns[1], 1 / scl.y);
			shear[0] /= scl.y;
		}
		// The third to both.
		shear[1] = Vector3DotProduct(columns[0], columns[2]);
		columns[2] = Vector3Subtract(columns[2], Vector3Scale(columns[0], shear[1]));
		shear[2] = Vector3DotProduct(columns[1], columns[2]);
		columns[2] = Vector3Subtract(columns[2], Vector3Scale(columns[1], shear[2]));
		scl.z = Vector3Length(columns[2]);
		if (scl.z > eps)
			columns[2] = Vector3Scale(columns[2], 1 / scl.z);
		// A rotation, not a mirror: det 1.
		if (Vector3DotProduct(columns[0], Vector3CrossProduct(columns[1], columns[2])) < 0) {
			scl = Vector3Negate(scl);
			for (i in 0...3)
				columns[i] = Vector3Negate(columns[i]);
		}
		var s = Vector3Scale(scl, stabilizer);
		scale.x = s.x;
		scale.y = s.y;
		scale.z = s.z;
		var r = QuaternionFromMatrix(new Matrix(columns[0].x, columns[1].x, columns[2].x, 0, columns[0].y, columns[1].y, columns[2].y, 0, columns[0].z,
			columns[1].z, columns[2].z, 0, 0, 0, 0, 1));
		rotation.x = r.x;
		rotation.y = r.y;
		rotation.z = r.z;
		rotation.w = r.w;
	}

	// A number as C's float holds it.
	static inline function f32(x:Float):Float {
		return haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(x));
	}

	// C's fminf and fmaxf, which give the number when the other is NaN, where Math.min and Math.max give NaN.

	static function fminf(a:Float, b:Float):Float {
		return Math.isNaN(a) ? b : Math.isNaN(b) ? a : a < b ? a : b;
	}

	static function fmaxf(a:Float, b:Float):Float {
		return Math.isNaN(a) ? b : Math.isNaN(b) ? a : a > b ? a : b;
	}
	#end
}
