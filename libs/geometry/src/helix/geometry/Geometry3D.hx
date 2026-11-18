package helix.geometry;

import helix.math.MathTools;
import helix.math.Vector3;

/** Provides tests on points, segments and triangles in space, their points given as plain numbers, as `Geometry2D` does in a plane.

	```haxe
	// How far a ball is from a rail, and the point of the rail the ball is nearest.
	var nearest = Geometry3D.getClosestPointOnSegment(ball.x, ball.y, ball.z, 0, 1, 0, 10, 1, 0);
	```

	Each test that returns a point writes it into an optional out, the last argument, and returns it: a new vector when omitted. */
class Geometry3D {
	/** Returns the point on a segment nearest a point.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param ax  The segment's start x.
		@param ay  The start's y.
		@param az  The start's z.
		@param bx  The segment's end x.
		@param by  The end's y.
		@param bz  The end's z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The nearest point; the start for a segment of no length. */
	public static function getClosestPointOnSegment(x:Float, y:Float, z:Float, ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float,
			?out:Vector3):Vector3 {
		var dx = bx - ax, dy = by - ay, dz = bz - az;
		var lengthSquared = dx * dx + dy * dy + dz * dz;
		var t = lengthSquared == 0 ? 0 : ((x - ax) * dx + (y - ay) * dy + (z - az) * dz) / lengthSquared;
		t = MathTools.clamp01(t);
		x = ax + dx * t;
		y = ay + dy * t;
		z = az + dz * t;
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	/** Returns how far a point is from a segment.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param ax  The segment's start x.
		@param ay  The start's y.
		@param az  The start's z.
		@param bx  The segment's end x.
		@param by  The end's y.
		@param bz  The end's z.
		@return  The distance. */
	public static function getDistanceToSegment(x:Float, y:Float, z:Float, ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float):Float {
		var dx = bx - ax, dy = by - ay, dz = bz - az;
		var lengthSquared = dx * dx + dy * dy + dz * dz;
		var t = lengthSquared == 0 ? 0 : ((x - ax) * dx + (y - ay) * dy + (z - az) * dz) / lengthSquared;
		t = MathTools.clamp01(t);
		x -= ax + dx * t;
		y -= ay + dy * t;
		z -= az + dz * t;
		return Math.sqrt(x * x + y * y + z * z);
	}

	/** Returns the point on a triangle nearest a point: inside the triangle, on an edge or at a corner.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param ax  The first corner's x.
		@param ay  The first corner's y.
		@param az  The first corner's z.
		@param bx  The second corner's x.
		@param by  The second corner's y.
		@param bz  The second corner's z.
		@param cx  The third corner's x.
		@param cy  The third corner's y.
		@param cz  The third corner's z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The nearest point. A triangle of no area is taken as the segment or the point its corners make. */
	public static function getClosestPointOnTriangle(x:Float, y:Float, z:Float, ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float,
			cy:Float, cz:Float, ?out:Vector3):Vector3 {
		if (out == null)
			out = new Vector3();
		// Which of the triangle's seven regions the point is over: a corner, an edge or the inside (Ericson's Real-Time Collision
		// Detection, 5.1.5).
		var abx = bx - ax, aby = by - ay, abz = bz - az;
		var acx = cx - ax, acy = cy - ay, acz = cz - az;
		var apx = x - ax, apy = y - ay, apz = z - az;
		var d1 = abx * apx + aby * apy + abz * apz,
			d2 = acx * apx + acy * apy + acz * apz;
		if (d1 <= 0 && d2 <= 0)
			return out.set(ax, ay, az);
		var bpx = x - bx, bpy = y - by, bpz = z - bz;
		var d3 = abx * bpx + aby * bpy + abz * bpz,
			d4 = acx * bpx + acy * bpy + acz * bpz;
		if (d3 >= 0 && d4 <= d3)
			return out.set(bx, by, bz);
		var vc = d1 * d4 - d3 * d2;
		if (vc <= 0 && d1 >= 0 && d3 <= 0) {
			var v = d1 / (d1 - d3);
			return out.set(ax + abx * v, ay + aby * v, az + abz * v);
		}
		var cpx = x - cx, cpy = y - cy, cpz = z - cz;
		var d5 = abx * cpx + aby * cpy + abz * cpz,
			d6 = acx * cpx + acy * cpy + acz * cpz;
		if (d6 >= 0 && d5 <= d6)
			return out.set(cx, cy, cz);
		var vb = d5 * d2 - d1 * d6;
		if (vb <= 0 && d2 >= 0 && d6 <= 0) {
			var w = d2 / (d2 - d6);
			return out.set(ax + acx * w, ay + acy * w, az + acz * w);
		}
		var va = d3 * d6 - d5 * d4;
		if (va <= 0 && d4 - d3 >= 0 && d5 - d6 >= 0) {
			var w = (d4 - d3) / (d4 - d3 + (d5 - d6));
			return out.set(bx + (cx - bx) * w, by + (cy - by) * w, bz + (cz - bz) * w);
		}
		var sum = va + vb + vc;
		if (sum == 0)
			return out.set(ax, ay, az);
		var v = vb / sum, w = vc / sum;
		return out.set(ax + abx * v + acx * w, ay + aby * v + acy * w, az + abz * v + acz * w);
	}

	/** Finds where two segments come nearest each other.

		@param a1x  The first segment's start x.
		@param a1y  The first segment's start y.
		@param a1z  The first segment's start z.
		@param a2x  The first segment's end x.
		@param a2y  The first segment's end y.
		@param a2z  The first segment's end z.
		@param b1x  The second segment's start x.
		@param b1y  The second segment's start y.
		@param b1z  The second segment's start z.
		@param b2x  The second segment's end x.
		@param b2y  The second segment's end y.
		@param b2z  The second segment's end z.
		@param outA  Optional. Set to the point on the first segment.
		@param outB  Optional. Set to the point on the second segment.
		@return  How far apart the two points are: 0 when the segments cross. Parallel segments give the first segment's start and the
			point of the second nearest that start, or the nearest pair of ends when that start is past the second segment. */
	public static function getClosestPointsBetweenSegments(a1x:Float, a1y:Float, a1z:Float, a2x:Float, a2y:Float, a2z:Float, b1x:Float, b1y:Float, b1z:Float,
			b2x:Float, b2y:Float, b2z:Float, ?outA:Vector3, ?outB:Vector3):Float {
		// Each segment is its start plus a fraction of its direction: s along the first, t along the second (Ericson's Real-Time
		// Collision Detection, 5.1.9).
		var d1x = a2x - a1x, d1y = a2y - a1y, d1z = a2z - a1z;
		var d2x = b2x - b1x, d2y = b2y - b1y, d2z = b2z - b1z;
		var rx = a1x - b1x, ry = a1y - b1y, rz = a1z - b1z;
		var a = d1x * d1x + d1y * d1y + d1z * d1z,
			e = d2x * d2x + d2y * d2y + d2z * d2z,
			f = d2x * rx + d2y * ry + d2z * rz;
		var s = 0., t = 0.;
		if (a == 0) {
			if (e != 0)
				t = MathTools.clamp01(f / e);
		} else {
			var c = d1x * rx + d1y * ry + d1z * rz;
			if (e == 0)
				s = MathTools.clamp01(-c / a);
			else {
				var b = d1x * d2x + d1y * d2y + d1z * d2z;
				var denominator = a * e - b * b;
				if (denominator > 0)
					s = MathTools.clamp01((b * f - c * e) / denominator);
				t = (b * s + f) / e;
				if (t < 0) {
					t = 0;
					s = MathTools.clamp01(-c / a);
				} else if (t > 1) {
					t = 1;
					s = MathTools.clamp01((b - c) / a);
				}
			}
		}
		var ax = a1x + d1x * s, ay = a1y + d1y * s, az = a1z + d1z * s;
		var bx = b1x + d2x * t, by = b1y + d2y * t, bz = b1z + d2z * t;
		if (outA != null)
			outA.set(ax, ay, az);
		if (outB != null)
			outB.set(bx, by, bz);
		ax -= bx;
		ay -= by;
		az -= bz;
		return Math.sqrt(ax * ax + ay * ay + az * az);
	}
}
