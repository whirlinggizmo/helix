package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.math.EulerOrder;
import helix.math.Interpolate;
import helix.math.MathTools;
import helix.math.Matrix4;
import helix.math.Trig;
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

/** Provides raylib's raymath functions for vectors, matrices and quaternions.

	The scalar, vector and quaternion functions forward to helix-math's (`helix.math.Interpolate`, its vectors and its `Quaternion`),
	and answer as helix-math does. `Raymath` forwards to each, through `tools/gen_raylib.py`. */
@:noCompletion
@:allow(helix.raylib)
class RMath {
	#if !macro
	// ---- raymath ----

	/** Returns a value kept between two others. The two in the wrong order are swapped.

		@param value  The value.
		@param min  The least.
		@param max  The most.
		@return  The value, at least min and at most max. */
	static inline function Clamp(value:Float, min:Float, max:Float):Float {
		return MathTools.clamp(value, min, max);
	}

	/** Returns a value part of the way from one to another.

		@param start  The start.
		@param end  The end.
		@param amount  0 for the start, 1 for the end.
		@return  The value. */
	static inline function Lerp(start:Float, end:Float, amount:Float):Float {
		return Interpolate.lerp(start, end, amount);
	}

	/** Returns where a value falls from one to another: 0 at the start, 1 at the end.

		@param value  The value.
		@param start  The start.
		@param end  The end.
		@return  The fraction; 0 when the start and the end are equal. */
	static inline function Normalize(value:Float, start:Float, end:Float):Float {
		return Interpolate.inverseLerp(start, end, value);
	}

	/** Returns a value moved from one range to another.

		@param value  The value.
		@param inputStart  The first range's start.
		@param inputEnd  Its end.
		@param outputStart  The second range's start.
		@param outputEnd  Its end.
		@return  The value in the second range. */
	static inline function Remap(value:Float, inputStart:Float, inputEnd:Float, outputStart:Float, outputEnd:Float):Float {
		return Interpolate.remap(value, inputStart, inputEnd, outputStart, outputEnd);
	}

	/** Returns a value wrapped around into a range, as an angle wraps around a turn.

		@param value  The value.
		@param min  The range's start.
		@param max  Its end.
		@return  The value in the range. */
	static inline function Wrap(value:Float, min:Float, max:Float):Float {
		return MathTools.wrap(value, min, max);
	}

	/** Returns whether two values are equal but for rounding.

		Counts them equal when they are no further apart than `EPSILON`, times the larger magnitude when that is over 1.

		@param x  One.
		@param y  The other.
		@return  1 if they are, 0 if not. */
	static inline function FloatEquals(x:Float, y:Float):Int {
		return MathTools.equals(x, y, Raymath.EPSILON) ? 1 : 0;
	}

	// ---- raymath: Vector2 ----

	/** Returns (0, 0).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	static inline function Vector2Zero(?out:Vector2):Vector2 {
		return vector2(out, 0, 0);
	}

	/** Returns (1, 1).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	static inline function Vector2One(?out:Vector2):Vector2 {
		return vector2(out, 1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The sum. */
	static inline function Vector2Add(v1:Vector2, v2:Vector2, ?out:Vector2):Vector2 {
		return v1.add(v2, out);
	}

	/** Returns a vector with a value added to each component.

		@param v  The vector.
		@param add  The value.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The sum. */
	static function Vector2AddValue(v:Vector2, add:Float, ?out:Vector2):Vector2 {
		return vector2(out, v.x + add, v.y + add);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one subtracted from it.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The difference. */
	static inline function Vector2Subtract(v1:Vector2, v2:Vector2, ?out:Vector2):Vector2 {
		return v1.subtract(v2, out);
	}

	/** Returns a vector with a value subtracted from each component.

		@param v  The vector.
		@param sub  The value.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The difference. */
	static function Vector2SubtractValue(v:Vector2, sub:Float, ?out:Vector2):Vector2 {
		return vector2(out, v.x - sub, v.y - sub);
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	static inline function Vector2Length(v:Vector2):Float {
		return v.length;
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	static inline function Vector2LengthSqr(v:Vector2):Float {
		return v.lengthSquared;
	}

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static inline function Vector2DotProduct(v1:Vector2, v2:Vector2):Float {
		return v1.dot(v2);
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static inline function Vector2Distance(v1:Vector2, v2:Vector2):Float {
		return v1.distance(v2);
	}

	/** Returns the distance between two points, squared.

		@param v1  One.
		@param v2  The other.
		@return  The distance squared. */
	static inline function Vector2DistanceSqr(v1:Vector2, v2:Vector2):Float {
		return v1.distanceSquared(v2);
	}

	/** Returns the angle from one vector to another, from -pi to pi.

		Positive turning from x toward y.

		@param v1  The first.
		@param v2  The second.
		@return  The angle, in radians. */
	static inline function Vector2Angle(v1:Vector2, v2:Vector2):Float {
		return v1.angleTo(v2);
	}

	/** Returns the angle of the line from one point to another, measured from the x axis.

		Positive turning from x toward -y.

		@param start  The line's start.
		@param end  Its end.
		@return  The angle, in radians. */
	static function Vector2LineAngle(start:Vector2, end:Vector2):Float {
		return -Trig.atan2(end.y - start.y, end.x - start.x);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scale  The scale.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The scaled vector. */
	static inline function Vector2Scale(v:Vector2, scale:Float, ?out:Vector2):Vector2 {
		return v.scale(scale, out);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The product. */
	static inline function Vector2Multiply(v1:Vector2, v2:Vector2, ?out:Vector2):Vector2 {
		return v1.multiply(v2, out);
	}

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The negated vector. */
	static inline function Vector2Negate(v:Vector2, ?out:Vector2):Vector2 {
		return v.negate(out);
	}

	/** Returns one vector divided by another, component by component.

		@param v1  The one divided.
		@param v2  The one dividing it.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The quotient. */
	static inline function Vector2Divide(v1:Vector2, v2:Vector2, ?out:Vector2):Vector2 {
		return v1.divide(v2, out);
	}

	/** Returns a vector of length 1 in the same direction, or (0, 0) for (0, 0).

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The direction. */
	static inline function Vector2Normalize(v:Vector2, ?out:Vector2):Vector2 {
		return v.normalize(out);
	}

	/** Returns a point transformed by a matrix, the point at z 0.

		@param v  The point.
		@param mat  The matrix.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The transformed point's x and y. */
	static function Vector2Transform(v:Vector2, mat:Matrix, ?out:Vector2):Vector2 {
		var x = v.x, y = v.y, z = 0.0;
		return vector2(out, mat.m0 * x + mat.m4 * y + mat.m8 * z + mat.m12, mat.m1 * x + mat.m5 * y + mat.m9 * z + mat.m13);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The point. */
	static inline function Vector2Lerp(v1:Vector2, v2:Vector2, amount:Float, ?out:Vector2):Vector2 {
		return Vector2.lerp(v1, v2, amount, out);
	}

	/** Returns a direction reflected off a surface.

		@param v  The direction.
		@param normal  The surface's normal, of length 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or normal.
		@return  The reflected direction. */
	static inline function Vector2Reflect(v:Vector2, normal:Vector2, ?out:Vector2):Vector2 {
		return v.reflect(normal, out);
	}

	/** Returns the least of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The vector of the least. */
	static inline function Vector2Min(v1:Vector2, v2:Vector2, ?out:Vector2):Vector2 {
		return v1.min(v2, out);
	}

	/** Returns the most of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The vector of the most. */
	static inline function Vector2Max(v1:Vector2, v2:Vector2, ?out:Vector2):Vector2 {
		return v1.max(v2, out);
	}

	/** Returns a vector turned by an angle, from x toward y.

		@param v  The vector.
		@param angle  The angle, in radians.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The turned vector. */
	static inline function Vector2Rotate(v:Vector2, angle:Float, ?out:Vector2):Vector2 {
		return v.rotate(angle, out);
	}

	/** Returns a point moved toward a target by at most a distance.

		Returns the target itself when the target is within that distance. A distance of 0 or less leaves the point where it is.

		@param v  The point.
		@param target  The target.
		@param maxDistance  The most it moves.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or target.
		@return  The moved point. */
	static inline function Vector2MoveTowards(v:Vector2, target:Vector2, maxDistance:Float, ?out:Vector2):Vector2 {
		return v.moveToward(target, maxDistance, out);
	}

	/** Returns 1 divided by each of a vector's components.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The inverted vector. */
	static inline function Vector2Invert(v:Vector2, ?out:Vector2):Vector2 {
		return v.inverse(out);
	}

	/** Returns a vector with each component kept between two others'. A component's two bounds in the wrong order are swapped.

		@param v  The vector.
		@param min  The least components.
		@param max  The most.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v, min or max.
		@return  The vector. */
	static inline function Vector2Clamp(v:Vector2, min:Vector2, max:Vector2, ?out:Vector2):Vector2 {
		return v.clamp(min, max, out);
	}

	/** Returns a vector with its length kept between two values. A vector of length 0 stays 0. The two values in the wrong order are swapped.

		@param v  The vector.
		@param min  The least length.
		@param max  The most length.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The vector. */
	static inline function Vector2ClampValue(v:Vector2, min:Float, max:Float, ?out:Vector2):Vector2 {
		return v.clampLength(min, max, out);
	}

	/** Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.

		@param p  One.
		@param q  The other.
		@return  1 if they are, 0 if not. */
	static inline function Vector2Equals(p:Vector2, q:Vector2):Int {
		return p.equals(q, Raymath.EPSILON) ? 1 : 0;
	}

	/** Returns a direction bent passing into a surface, or (0, 0) when it is wholly reflected instead.

		@param v  The direction, of length 1.
		@param n  The surface's normal, of length 1.
		@param r  The ratio of the refractive indices, the one it leaves over the one it enters.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or n.
		@return  The bent direction. */
	static inline function Vector2Refract(v:Vector2, n:Vector2, r:Float, ?out:Vector2):Vector2 {
		return v.refract(n, r, out);
	}

	// ---- raymath: Vector3 ----

	/** Returns (0, 0, 0).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	static inline function Vector3Zero(?out:Vector3):Vector3 {
		return vector3(out, 0, 0, 0);
	}

	/** Returns (1, 1, 1).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	static inline function Vector3One(?out:Vector3):Vector3 {
		return vector3(out, 1, 1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The sum. */
	static inline function Vector3Add(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.add(v2, out);
	}

	/** Returns a vector with a value added to each component.

		@param v  The vector.
		@param add  The value.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The sum. */
	static function Vector3AddValue(v:Vector3, add:Float, ?out:Vector3):Vector3 {
		return vector3(out, v.x + add, v.y + add, v.z + add);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one subtracted from it.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The difference. */
	static inline function Vector3Subtract(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.subtract(v2, out);
	}

	/** Returns a vector with a value subtracted from each component.

		@param v  The vector.
		@param sub  The value.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The difference. */
	static function Vector3SubtractValue(v:Vector3, sub:Float, ?out:Vector3):Vector3 {
		return vector3(out, v.x - sub, v.y - sub, v.z - sub);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scalar  The scale.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The scaled vector. */
	static inline function Vector3Scale(v:Vector3, scalar:Float, ?out:Vector3):Vector3 {
		return v.scale(scalar, out);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The product. */
	static inline function Vector3Multiply(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.multiply(v2, out);
	}

	/** Returns the cross product.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The product. */
	static inline function Vector3CrossProduct(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.cross(v2, out);
	}

	/** Returns a vector perpendicular to another: its cross product with the axis the vector is least along.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The perpendicular vector. */
	static inline function Vector3Perpendicular(v:Vector3, ?out:Vector3):Vector3 {
		return v.perpendicular(out);
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	static inline function Vector3Length(v:Vector3):Float {
		return v.length;
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	static inline function Vector3LengthSqr(v:Vector3):Float {
		return v.lengthSquared;
	}

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static inline function Vector3DotProduct(v1:Vector3, v2:Vector3):Float {
		return v1.dot(v2);
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static inline function Vector3Distance(v1:Vector3, v2:Vector3):Float {
		return v1.distance(v2);
	}

	/** Returns the distance between two points, squared.

		@param v1  One.
		@param v2  The other.
		@return  The distance squared. */
	static inline function Vector3DistanceSqr(v1:Vector3, v2:Vector3):Float {
		return v1.distanceSquared(v2);
	}

	/** Returns the angle between two vectors, from 0 to pi.

		@param v1  One.
		@param v2  The other.
		@return  The angle, in radians. */
	static inline function Vector3Angle(v1:Vector3, v2:Vector3):Float {
		return v1.angleTo(v2);
	}

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The negated vector. */
	static inline function Vector3Negate(v:Vector3, ?out:Vector3):Vector3 {
		return v.negate(out);
	}

	/** Returns one vector divided by another, component by component.

		@param v1  The one divided.
		@param v2  The one dividing it.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The quotient. */
	static inline function Vector3Divide(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.divide(v2, out);
	}

	/** Returns a vector of length 1 in the same direction, or the vector itself when its length is 0.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The direction. */
	static inline function Vector3Normalize(v:Vector3, ?out:Vector3):Vector3 {
		return v.normalize(out);
	}

	/** Returns the part of one vector along another.

		@param v1  The vector.
		@param v2  The direction it is projected onto.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The projection. */
	static inline function Vector3Project(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.project(v2, out);
	}

	/** Returns the part of one vector across another: the vector less its projection.

		@param v1  The vector.
		@param v2  The direction removed from it.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The rejection. */
	static inline function Vector3Reject(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.reject(v2, out);
	}

	/** Makes two vectors of length 1 and at right angles to each other, the first keeping its direction (Gram-Schmidt).

		@param v1  The first, set to its direction.
		@param v2  The second, set at right angles to the first, in the plane the two were in and on its own side. */
	static inline function Vector3OrthoNormalize(v1:Vector3, v2:Vector3):Void {
		Vector3.orthoNormalize(v1, v2);
	}

	/** Returns a point transformed by a matrix.

		@param v  The point.
		@param mat  The matrix.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The transformed point. */
	static inline function Vector3Transform(v:Vector3, mat:Matrix, ?out:Vector3):Vector3 {
		return mat.transformPoint(v.x, v.y, v.z, out);
	}

	/** Returns a vector turned by a quaternion.

		@param v  The vector.
		@param q  The quaternion, of length 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The turned vector. */
	static inline function Vector3RotateByQuaternion(v:Vector3, q:Quaternion, ?out:Vector3):Vector3 {
		return q.transformPoint(v.x, v.y, v.z, out);
	}

	/** Returns a vector turned about an axis.

		@param v  The vector.
		@param axis  The axis.
		@param angle  The angle, in radians.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or axis.
		@return  The turned vector. */
	static inline function Vector3RotateByAxisAngle(v:Vector3, axis:Vector3, angle:Float, ?out:Vector3):Vector3 {
		return v.rotate(axis, angle, out);
	}

	/** Returns a point moved toward a target by at most a distance.

		Returns the target itself when the target is within that distance. A distance of 0 or less leaves the point where it is.

		@param v  The point.
		@param target  The target.
		@param maxDistance  The most it moves.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or target.
		@return  The moved point. */
	static inline function Vector3MoveTowards(v:Vector3, target:Vector3, maxDistance:Float, ?out:Vector3):Vector3 {
		return v.moveToward(target, maxDistance, out);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The point. */
	static inline function Vector3Lerp(v1:Vector3, v2:Vector3, amount:Float, ?out:Vector3):Vector3 {
		return Vector3.lerp(v1, v2, amount, out);
	}

	/** Returns a point part of the way along a cubic Hermite curve, from one point to another, leaving and arriving along tangents.

		@param v1  The start.
		@param tangent1  The tangent leaving it.
		@param v2  The end.
		@param tangent2  The tangent arriving at it.
		@param amount  0 for the start, 1 for the end.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1, tangent1, v2 or tangent2.
		@return  The point. */
	static inline function Vector3CubicHermite(v1:Vector3, tangent1:Vector3, v2:Vector3, tangent2:Vector3, amount:Float, ?out:Vector3):Vector3 {
		return Vector3.hermite(v1, tangent1, v2, tangent2, amount, out);
	}

	/** Returns a direction reflected off a surface.

		@param v  The direction.
		@param normal  The surface's normal, of length 1.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or normal.
		@return  The reflected direction. */
	static inline function Vector3Reflect(v:Vector3, normal:Vector3, ?out:Vector3):Vector3 {
		return v.reflect(normal, out);
	}

	/** Returns the least of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The vector of the least. */
	static inline function Vector3Min(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.min(v2, out);
	}

	/** Returns the most of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The vector of the most. */
	static inline function Vector3Max(v1:Vector3, v2:Vector3, ?out:Vector3):Vector3 {
		return v1.max(v2, out);
	}

	/** Returns a point's barycentric coordinates in a triangle: how much of each corner it is made of.

		@param p  The point.
		@param a  The first corner.
		@param b  The second.
		@param c  The third.
		@param out  Optional. The vector to fill; a new one when omitted. It may be p, a, b or c.
		@return  How much of a (x), b (y) and c (z). */
	static inline function Vector3Barycenter(p:Vector3, a:Vector3, b:Vector3, c:Vector3, ?out:Vector3):Vector3 {
		return Vector3.barycentric(p, a, b, c, out);
	}

	/** Returns a point in normalized device coordinates (each from -1 to 1) mapped back into the world, through a view and a projection.

		A view and a projection without an inverse produce a point of NaN.

		@param source  The point.
		@param projection  The projection.
		@param view  The view.
		@param out  Optional. The vector to fill; a new one when omitted. It may be source.
		@return  The point in the world. */
	static function Vector3Unproject(source:Vector3, projection:Matrix, view:Matrix, ?out:Vector3):Vector3 {
		var inverse = Matrix4.compose(view, projection, unprojection).invert(unprojection);
		return inverse == null ? vector3(out, Math.NaN, Math.NaN, Math.NaN) : inverse.projectPoint(source.x, source.y, source.z, out);
	}

	/** Returns a vector's components as an array: x, y, z.

		@param v  The vector.
		@param out  Optional. The array to fill; a new one when omitted.
		@return  The array. */
	static function Vector3ToFloatV(v:Vector3, ?out:Array<Float>):Array<Float> {
		if (out == null)
			return [v.x, v.y, v.z];
		out.resize(3);
		out[0] = v.x;
		out[1] = v.y;
		out[2] = v.z;
		return out;
	}

	/** Returns a vector's components as an array: x, y, z. raymath's macro for `Vector3ToFloatV`'s array, the same here.

		@param vec  The vector.
		@param out  Optional. The array to fill; a new one when omitted.
		@return  The array. */
	static function Vector3ToFloat(vec:Vector3, ?out:Array<Float>):Array<Float> {
		return Vector3ToFloatV(vec, out);
	}

	/** Returns 1 divided by each of a vector's components.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The inverted vector. */
	static inline function Vector3Invert(v:Vector3, ?out:Vector3):Vector3 {
		return v.inverse(out);
	}

	/** Returns a vector with each component kept between two others'. A component's two bounds in the wrong order are swapped.

		@param v  The vector.
		@param min  The least components.
		@param max  The most.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v, min or max.
		@return  The vector. */
	static inline function Vector3Clamp(v:Vector3, min:Vector3, max:Vector3, ?out:Vector3):Vector3 {
		return v.clamp(min, max, out);
	}

	/** Returns a vector with its length kept between two values. A vector of length 0 stays 0. The two values in the wrong order are swapped.

		@param v  The vector.
		@param min  The least length.
		@param max  The most length.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The vector. */
	static inline function Vector3ClampValue(v:Vector3, min:Float, max:Float, ?out:Vector3):Vector3 {
		return v.clampLength(min, max, out);
	}

	/** Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.

		@param p  One.
		@param q  The other.
		@return  1 if they are, 0 if not. */
	static inline function Vector3Equals(p:Vector3, q:Vector3):Int {
		return p.equals(q, Raymath.EPSILON) ? 1 : 0;
	}

	/** Returns a direction bent passing into a surface, or (0, 0, 0) when it is wholly reflected instead.

		@param v  The direction, of length 1.
		@param n  The surface's normal, of length 1.
		@param r  The ratio of the refractive indices, the one it leaves over the one it enters.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or n.
		@return  The bent direction. */
	static inline function Vector3Refract(v:Vector3, n:Vector3, r:Float, ?out:Vector3):Vector3 {
		return v.refract(n, r, out);
	}

	// ---- raymath: Vector4 ----

	/** Returns (0, 0, 0, 0).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	static inline function Vector4Zero(?out:Vector4):Vector4 {
		return vector4(out, 0, 0, 0, 0);
	}

	/** Returns (1, 1, 1, 1).

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The vector. */
	static inline function Vector4One(?out:Vector4):Vector4 {
		return vector4(out, 1, 1, 1, 1);
	}

	/** Returns the sum of two vectors.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The sum. */
	static inline function Vector4Add(v1:Vector4, v2:Vector4, ?out:Vector4):Vector4 {
		return v1.add(v2, out);
	}

	/** Returns a vector with a value added to each component.

		@param v  The vector.
		@param add  The value.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The sum. */
	static function Vector4AddValue(v:Vector4, add:Float, ?out:Vector4):Vector4 {
		return vector4(out, v.x + add, v.y + add, v.z + add, v.w + add);
	}

	/** Returns one vector less another.

		@param v1  The first.
		@param v2  The one subtracted from it.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The difference. */
	static inline function Vector4Subtract(v1:Vector4, v2:Vector4, ?out:Vector4):Vector4 {
		return v1.subtract(v2, out);
	}

	/** Returns a vector with a value subtracted from each component.

		@param v  The vector.
		@param add  The value.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The difference. */
	static function Vector4SubtractValue(v:Vector4, add:Float, ?out:Vector4):Vector4 {
		return vector4(out, v.x - add, v.y - add, v.z - add, v.w - add);
	}

	/** Returns a vector's length.

		@param v  The vector.
		@return  The length. */
	static inline function Vector4Length(v:Vector4):Float {
		return v.length;
	}

	/** Returns a vector's length squared.

		@param v  The vector.
		@return  The length squared. */
	static inline function Vector4LengthSqr(v:Vector4):Float {
		return v.lengthSquared;
	}

	/** Returns the dot product.

		@param v1  One.
		@param v2  The other.
		@return  The product. */
	static inline function Vector4DotProduct(v1:Vector4, v2:Vector4):Float {
		return v1.dot(v2);
	}

	/** Returns the distance between two points.

		@param v1  One.
		@param v2  The other.
		@return  The distance. */
	static inline function Vector4Distance(v1:Vector4, v2:Vector4):Float {
		return v1.distance(v2);
	}

	/** Returns the distance between two points, squared.

		@param v1  One.
		@param v2  The other.
		@return  The distance squared. */
	static inline function Vector4DistanceSqr(v1:Vector4, v2:Vector4):Float {
		return v1.distanceSquared(v2);
	}

	/** Returns a vector scaled.

		@param v  The vector.
		@param scale  The scale.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The scaled vector. */
	static inline function Vector4Scale(v:Vector4, scale:Float, ?out:Vector4):Vector4 {
		return v.scale(scale, out);
	}

	/** Returns two vectors multiplied component by component.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The product. */
	static inline function Vector4Multiply(v1:Vector4, v2:Vector4, ?out:Vector4):Vector4 {
		return v1.multiply(v2, out);
	}

	/** Returns a vector pointing the other way.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The negated vector. */
	static inline function Vector4Negate(v:Vector4, ?out:Vector4):Vector4 {
		return v.negate(out);
	}

	/** Returns one vector divided by another, component by component.

		@param v1  The one divided.
		@param v2  The one dividing it.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The quotient. */
	static inline function Vector4Divide(v1:Vector4, v2:Vector4, ?out:Vector4):Vector4 {
		return v1.divide(v2, out);
	}

	/** Returns a vector of length 1 in the same direction, or (0, 0, 0, 0) for (0, 0, 0, 0).

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The direction. */
	static inline function Vector4Normalize(v:Vector4, ?out:Vector4):Vector4 {
		return v.normalize(out);
	}

	/** Returns the least of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The vector of the least. */
	static inline function Vector4Min(v1:Vector4, v2:Vector4, ?out:Vector4):Vector4 {
		return v1.min(v2, out);
	}

	/** Returns the most of two vectors' components, each on its own.

		@param v1  One.
		@param v2  The other.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The vector of the most. */
	static inline function Vector4Max(v1:Vector4, v2:Vector4, ?out:Vector4):Vector4 {
		return v1.max(v2, out);
	}

	/** Returns a point part of the way from one to another.

		@param v1  The start.
		@param v2  The end.
		@param amount  0 for the start, 1 for the end.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v1 or v2.
		@return  The point. */
	static inline function Vector4Lerp(v1:Vector4, v2:Vector4, amount:Float, ?out:Vector4):Vector4 {
		return Vector4.lerp(v1, v2, amount, out);
	}

	/** Returns a point moved toward a target by at most a distance.

		Returns the target itself when the target is within that distance. A distance of 0 or less leaves the point where it is.

		@param v  The point.
		@param target  The target.
		@param maxDistance  The most it moves.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v or target.
		@return  The moved point. */
	static inline function Vector4MoveTowards(v:Vector4, target:Vector4, maxDistance:Float, ?out:Vector4):Vector4 {
		return v.moveToward(target, maxDistance, out);
	}

	/** Returns 1 divided by each of a vector's components.

		@param v  The vector.
		@param out  Optional. The vector to fill; a new one when omitted. It may be v.
		@return  The inverted vector. */
	static inline function Vector4Invert(v:Vector4, ?out:Vector4):Vector4 {
		return v.inverse(out);
	}

	/** Returns whether two vectors are equal but for rounding, each component as `FloatEquals` compares it.

		@param p  One.
		@param q  The other.
		@return  1 if they are, 0 if not. */
	static inline function Vector4Equals(p:Vector4, q:Vector4):Int {
		return p.equals(q, Raymath.EPSILON) ? 1 : 0;
	}

	// ---- raymath: Matrix ----

	/** Returns a matrix's determinant.

		@param mat  The matrix.
		@return  The determinant. */
	static inline function MatrixDeterminant(mat:Matrix):Float {
		return mat.determinant;
	}

	/** Returns a matrix's trace: the sum of its diagonal.

		@param mat  The matrix.
		@return  The trace. */
	static inline function MatrixTrace(mat:Matrix):Float {
		return mat.trace;
	}

	/** Returns a matrix transposed.

		@param mat  The matrix.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be mat.
		@return  Its transpose. */
	static inline function MatrixTranspose(mat:Matrix, ?out:Matrix):Matrix {
		return mat.transpose(out);
	}

	/** Returns a matrix's inverse.

		A matrix without an inverse produces a matrix of NaN.

		@param mat  The matrix.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be mat.
		@return  Its inverse. */
	static function MatrixInvert(mat:Matrix, ?out:Matrix):Matrix {
		var inverse = mat.invert(out);
		return inverse == null ? Matrix4.fromArray(nans, 0, out) : inverse;
	}

	/** Returns the identity matrix.

		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixIdentity(?out:Matrix):Matrix {
		return out == null ? new Matrix4() : out.makeIdentity();
	}

	/** Returns the sum of two matrices.

		@param left  One.
		@param right  The other.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be left or right.
		@return  The sum. */
	static inline function MatrixAdd(left:Matrix, right:Matrix, ?out:Matrix):Matrix {
		return left.add(right, out);
	}

	/** Returns one matrix less another.

		@param left  The first.
		@param right  The one subtracted from it.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be left or right.
		@return  The difference. */
	static inline function MatrixSubtract(left:Matrix, right:Matrix, ?out:Matrix):Matrix {
		return left.subtract(right, out);
	}

	/** Returns two matrices multiplied: left, then right.

		@param left  The first.
		@param right  The second.
		@param out  Optional. The matrix to fill; a new one when omitted. It may be left or right.
		@return  The product. */
	static inline function MatrixMultiply(left:Matrix, right:Matrix, ?out:Matrix):Matrix {
		return Matrix4.compose(left, right, out);
	}

	/** Returns a translation.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixTranslate(x:Float, y:Float, z:Float, ?out:Matrix):Matrix {
		return Matrix4.fromTranslation(x, y, z, out);
	}

	/** Returns a rotation about an axis.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixRotate(axis:Vector3, angle:Float, ?out:Matrix):Matrix {
		return Matrix4.fromRotation(axis.x, axis.y, axis.z, angle, out);
	}

	/** Returns a rotation about x.

		@param angle  The angle, in radians.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixRotateX(angle:Float, ?out:Matrix):Matrix {
		return Matrix4.fromRotation(1, 0, 0, angle, out);
	}

	/** Returns a rotation about y.

		@param angle  The angle, in radians.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixRotateY(angle:Float, ?out:Matrix):Matrix {
		return Matrix4.fromRotation(0, 1, 0, angle, out);
	}

	/** Returns a rotation about z.

		@param angle  The angle, in radians.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixRotateZ(angle:Float, ?out:Matrix):Matrix {
		return Matrix4.fromRotation(0, 0, 1, angle, out);
	}

	/** Returns a rotation by three angles that turns a point about z, then y, then x. See `MatrixRotateZYX` for turning in the reverse
		order.

		@param angle  The angles, in radians.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static function MatrixRotateXYZ(angle:Vector3, ?out:Matrix):Matrix {
		return Matrix4.fromEuler(angle.x, angle.y, angle.z, XYZ, out);
	}

	/** Returns a rotation by three angles that turns a point about x, then y, then z, the reverse of `MatrixRotateXYZ`.

		@param angle  The angles, in radians.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static function MatrixRotateZYX(angle:Vector3, ?out:Matrix):Matrix {
		return Matrix4.fromEuler(angle.x, angle.y, angle.z, ZYX, out);
	}

	/** Returns a scale.

		@param x  Along x.
		@param y  Along y.
		@param z  Along z.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixScale(x:Float, y:Float, z:Float, ?out:Matrix):Matrix {
		return Matrix4.fromScale(x, y, z, out);
	}

	/** Returns a perspective projection by its near plane's edges.

		@param left  The near plane's left.
		@param right  Its right.
		@param bottom  Its bottom.
		@param top  Its top.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixFrustum(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float, ?out:Matrix):Matrix {
		return Matrix4.fromFrustum(left, right, bottom, top, nearPlane, farPlane, out);
	}

	/** Returns a perspective projection.

		@param fovY  The field of view, top to bottom, in radians.
		@param aspect  Width over height.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixPerspective(fovY:Float, aspect:Float, nearPlane:Float, farPlane:Float, ?out:Matrix):Matrix {
		return Matrix4.fromPerspective(fovY, aspect, nearPlane, farPlane, out);
	}

	/** Returns an orthographic projection.

		@param left  Left.
		@param right  Right.
		@param bottom  Bottom.
		@param top  Top.
		@param nearPlane  The near plane.
		@param farPlane  The far plane.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixOrtho(left:Float, right:Float, bottom:Float, top:Float, nearPlane:Float, farPlane:Float, ?out:Matrix):Matrix {
		return Matrix4.fromOrthographic(left, right, bottom, top, nearPlane, farPlane, out);
	}

	/** Returns a view looking from eye at target.

		@param eye  Where from.
		@param target  What at.
		@param up  Up.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function MatrixLookAt(eye:Vector3, target:Vector3, up:Vector3, ?out:Matrix):Matrix {
		return Matrix4.fromLookAt(eye.x, eye.y, eye.z, target.x, target.y, target.z, up.x, up.y, up.z, out);
	}

	/** Returns a matrix's values as an array, by columns: m0 to m15, as a shader accepts them.

		@param mat  The matrix.
		@param out  Optional. The array to fill; a new one when omitted.
		@return  The array. */
	static function MatrixToFloatV(mat:Matrix, ?out:Array<Float>):Array<Float> {
		if (out != null)
			out.resize(16);
		return mat.toArray(out);
	}

	/** Returns a matrix's values as an array, by columns: m0 to m15, as a shader and `rlMultMatrixf` accept them. raymath's macro for
		`MatrixToFloatV`'s array, the same here.

		@param mat  The matrix.
		@param out  Optional. The array to fill; a new one when omitted.
		@return  The array. */
	static function MatrixToFloat(mat:Matrix, ?out:Array<Float>):Array<Float> {
		return MatrixToFloatV(mat, out);
	}

	// ---- raymath: Quaternion ----

	/** Returns the sum of two quaternions.

		@param q1  One.
		@param q2  The other.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1 or q2.
		@return  The sum. */
	static function QuaternionAdd(q1:Quaternion, q2:Quaternion, ?out:Quaternion):Quaternion {
		return quaternion(out, q1.x + q2.x, q1.y + q2.y, q1.z + q2.z, q1.w + q2.w);
	}

	/** Returns a quaternion with a value added to each component.

		@param q  The quaternion.
		@param add  The value.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q.
		@return  The sum. */
	static function QuaternionAddValue(q:Quaternion, add:Float, ?out:Quaternion):Quaternion {
		return quaternion(out, q.x + add, q.y + add, q.z + add, q.w + add);
	}

	/** Returns one quaternion less another.

		@param q1  The first.
		@param q2  The one subtracted from it.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1 or q2.
		@return  The difference. */
	static function QuaternionSubtract(q1:Quaternion, q2:Quaternion, ?out:Quaternion):Quaternion {
		return quaternion(out, q1.x - q2.x, q1.y - q2.y, q1.z - q2.z, q1.w - q2.w);
	}

	/** Returns a quaternion with a value subtracted from each component.

		@param q  The quaternion.
		@param sub  The value.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q.
		@return  The difference. */
	static function QuaternionSubtractValue(q:Quaternion, sub:Float, ?out:Quaternion):Quaternion {
		return quaternion(out, q.x - sub, q.y - sub, q.z - sub, q.w - sub);
	}

	/** Returns the identity quaternion.

		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	static inline function QuaternionIdentity(?out:Quaternion):Quaternion {
		return out == null ? new Quaternion() : out.makeIdentity();
	}

	/** Returns a quaternion's length.

		@param q  The quaternion.
		@return  The length. */
	static inline function QuaternionLength(q:Quaternion):Float {
		return q.length;
	}

	/** Returns a quaternion of length 1 in the same direction, or the identity when its length is 0.

		@param q  The quaternion.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q.
		@return  The normalized quaternion. */
	static inline function QuaternionNormalize(q:Quaternion, ?out:Quaternion):Quaternion {
		return q.normalize(out);
	}

	/** Returns the rotation back from a quaternion's.

		@param q  The quaternion, of length 1.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q.
		@return  Its inverse. */
	static inline function QuaternionInvert(q:Quaternion, ?out:Quaternion):Quaternion {
		return q.invert(out);
	}

	/** Returns two quaternions multiplied: the rotation q2, then q1.

		@param q1  The first.
		@param q2  The second.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1 or q2.
		@return  The product. */
	static inline function QuaternionMultiply(q1:Quaternion, q2:Quaternion, ?out:Quaternion):Quaternion {
		return Quaternion.compose(q2, q1, out);
	}

	/** Returns a quaternion scaled.

		@param q  The quaternion.
		@param mul  The scale.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q.
		@return  The scaled quaternion. */
	static function QuaternionScale(q:Quaternion, mul:Float, ?out:Quaternion):Quaternion {
		return quaternion(out, q.x * mul, q.y * mul, q.z * mul, q.w * mul);
	}

	/** Returns one quaternion divided by another, component by component.

		@param q1  The one divided.
		@param q2  The one dividing it.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1 or q2.
		@return  The quotient. */
	static function QuaternionDivide(q1:Quaternion, q2:Quaternion, ?out:Quaternion):Quaternion {
		return quaternion(out, q1.x / q2.x, q1.y / q2.y, q1.z / q2.z, q1.w / q2.w);
	}

	/** Returns a quaternion part of the way from one to another, component by component.

		@param q1  The start.
		@param q2  The end.
		@param amount  0 for the start, 1 for the end.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1 or q2.
		@return  The quaternion. */
	static function QuaternionLerp(q1:Quaternion, q2:Quaternion, amount:Float, ?out:Quaternion):Quaternion {
		return quaternion(out, q1.x
			+ amount * (q2.x - q1.x), q1.y
			+ amount * (q2.y - q1.y), q1.z
			+ amount * (q2.z - q1.z), q1.w
			+ amount * (q2.w - q1.w));
	}

	/** Returns a quaternion part of the way from one to another the short way round, component by component, then normalized.

		@param q1  The start.
		@param q2  The end.
		@param amount  0 for the start, 1 for the end.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1 or q2.
		@return  The quaternion. */
	static inline function QuaternionNlerp(q1:Quaternion, q2:Quaternion, amount:Float, ?out:Quaternion):Quaternion {
		return Quaternion.nlerp(q1, q2, amount, out);
	}

	/** Returns a rotation part of the way from one to another at a steady turn, the short way round (spherical linear interpolation).

		@param q1  The start.
		@param q2  The end.
		@param amount  0 for the start, 1 for the end.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1 or q2.
		@return  The quaternion. */
	static inline function QuaternionSlerp(q1:Quaternion, q2:Quaternion, amount:Float, ?out:Quaternion):Quaternion {
		return Quaternion.slerp(q1, q2, amount, out);
	}

	/** Returns a rotation part of the way along a cubic Hermite curve, from one quaternion to another, leaving and arriving along tangents,
		normalized.

		@param q1  The start.
		@param outTangent1  The tangent leaving it.
		@param q2  The end.
		@param inTangent2  The tangent arriving at it.
		@param t  0 for the start, 1 for the end.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q1, outTangent1, q2 or inTangent2.
		@return  The quaternion. */
	static inline function QuaternionCubicHermiteSpline(q1:Quaternion, outTangent1:Quaternion, q2:Quaternion, inTangent2:Quaternion, t:Float,
			?out:Quaternion):Quaternion {
		return Quaternion.hermite(q1, outTangent1, q2, inTangent2, t, out);
	}

	/** Returns the rotation turning one direction to another.

		Accepts directions of any length.

		Opposite directions produce half a turn about a direction square to the first.

		@param from  The direction turned from.
		@param to  The direction turned to.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion, of length 1; the identity when either direction is all 0. */
	static inline function QuaternionFromVector3ToVector3(from:Vector3, to:Vector3, ?out:Quaternion):Quaternion {
		return Quaternion.fromBetween(from, to, out);
	}

	/** Returns a rotation matrix's rotation as a quaternion.

		@param mat  The matrix.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	static inline function QuaternionFromMatrix(mat:Matrix, ?out:Quaternion):Quaternion {
		return Quaternion.fromRotationMatrix(mat, out);
	}

	/** Returns a quaternion's rotation as a matrix.

		@param q  The quaternion.
		@param out  Optional. The matrix to fill; a new one when omitted.
		@return  The matrix. */
	static inline function QuaternionToMatrix(q:Quaternion, ?out:Matrix):Matrix {
		return q.toMatrix(out);
	}

	/** Returns the rotation about an axis as a quaternion, normalized.

		Returns the identity for an axis of length 0.

		@param axis  The axis.
		@param angle  The angle, in radians.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	static inline function QuaternionFromAxisAngle(axis:Vector3, angle:Float, ?out:Quaternion):Quaternion {
		return Quaternion.fromAxisAngle(axis.x, axis.y, axis.z, angle, out);
	}

	/** Finds a quaternion's rotation as an axis and an angle about it.

		Returns x as the axis when the angle is 0.

		@param q  The quaternion, of length 1.
		@param outAxis  Its first element is set to the axis, of length 1.
		@param outAngle  Its first element is set to the angle, in radians, 0 to pi. */
	static inline function QuaternionToAxisAngle(q:Quaternion, outAxis:Array<Vector3>, outAngle:Array<Float>):Void {
		outAxis[0] = q.getAxis();
		outAngle[0] = q.angle;
	}

	/** Returns a rotation by Euler angles as a quaternion.

		@param pitch  About x, in radians.
		@param yaw  About y.
		@param roll  About z.
		@param out  Optional. The quaternion to fill; a new one when omitted.
		@return  The quaternion. */
	static inline function QuaternionFromEuler(pitch:Float, yaw:Float, roll:Float, ?out:Quaternion):Quaternion {
		return Quaternion.fromEuler(pitch, yaw, roll, ZYX, out);
	}

	/** Returns a quaternion's rotation as Euler angles: about x (pitch), y (yaw) and z (roll), as `QuaternionFromEuler` accepts them.

		At a yaw of a quarter turn either way, where pitch and roll turn about one axis, the roll is 0 and the pitch carries the whole
		turn.

		@param q  The quaternion, of length 1.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The angles, in radians. */
	static inline function QuaternionToEuler(q:Quaternion, ?out:Vector3):Vector3 {
		return q.toEuler(ZYX, out);
	}

	/** Returns a quaternion's four components transformed by a matrix, as a point with w.

		@param q  The quaternion.
		@param mat  The matrix.
		@param out  Optional. The quaternion to fill; a new one when omitted. It may be q.
		@return  The transformed quaternion. */
	static function QuaternionTransform(q:Quaternion, mat:Matrix, ?out:Quaternion):Quaternion {
		return quaternion(out, mat.m0 * q.x
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
	static inline function QuaternionEquals(p:Quaternion, q:Quaternion):Int {
		return p.equals(q, Raymath.EPSILON) ? 1 : 0;
	}

	/** Splits a transform matrix into its translation, rotation and scale.

		A matrix that shears produces the nearest rotation and the scale along that rotation's axes, the shear lost. One that mirrors
		produces a scale less than 0 along each axis.

		@param mat  The matrix.
		@param translation  Set to its translation.
		@param rotation  Set to its rotation.
		@param scale  Set to its scale. */
	static function MatrixDecompose(mat:Matrix, translation:Vector3, rotation:Quaternion, scale:Vector3):Void {
		mat.decompose(translation, rotation, scale);
		// helix-math mirrors along x alone. raylib's mirrors along all three: the same matrix, its rotation half a turn about its x.
		if (scale.x < 0) {
			scale.set(scale.x, -scale.y, -scale.z);
			rotation.set(rotation.w, rotation.z, -rotation.y, -rotation.x);
		}
	}

	// The out filled, or a new value: each argument is read before out is written, so out may be any input.

	static inline function vector2(out:Null<Vector2>, x:Float, y:Float):Vector2 {
		return out == null ? new Vector2(x, y) : out.set(x, y);
	}

	static inline function vector3(out:Null<Vector3>, x:Float, y:Float, z:Float):Vector3 {
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	static inline function vector4(out:Null<Vector4>, x:Float, y:Float, z:Float, w:Float):Vector4 {
		return out == null ? new Vector4(x, y, z, w) : out.set(x, y, z, w);
	}

	static inline function quaternion(out:Null<Quaternion>, x:Float, y:Float, z:Float, w:Float):Quaternion {
		return out == null ? new Quaternion(x, y, z, w) : out.set(x, y, z, w);
	}

	// The 16 numbers of MatrixInvert's answer for a matrix without an inverse.
	static final nans = [for (_ in 0...16) Math.NaN];

	// The matrix Vector3Unproject inverts, reused.
	static final unprojection = new Matrix4();

	// A number as C's float holds it.
	static inline function f32(x:Float):Float {
		return haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(x));
	}

	// C's fminf and fmaxf, which return the number when the other is NaN, where Math.min and Math.max return NaN.

	static function fminf(a:Float, b:Float):Float {
		return Math.isNaN(a) ? b : Math.isNaN(b) ? a : a < b ? a : b;
	}

	static function fmaxf(a:Float, b:Float):Float {
		return Math.isNaN(a) ? b : Math.isNaN(b) ? a : a > b ? a : b;
	}
	#end
}
