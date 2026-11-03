package helix.geometry;

import helix.math.Vector2D;

/** Provides tests on points, segments, triangles, polygons and circles in a plane, their points given as plain numbers.

	Lines that are parallel within a ten-millionth (by the cross product of their directions) don't cross. */
class Geometry2D {
	static inline final EPSILON = 1.1920929e-7;

	/** Returns whether two segments cross, and where. Parallel segments, overlapping ones too, don't.

		Each segment is a start plus a fraction of its direction, and they cross when both fractions are from 0 to 1, so a nearly
		vertical or nearly horizontal segment is tested as any other.
		@param ax  The first segment's start x.
		@param ay  Its start y.
		@param bx  Its end x.
		@param by  Its end y.
		@param cx  The second segment's start x.
		@param cy  Its start y.
		@param dx  Its end x.
		@param dy  Its end y.
		@param out  Optional. Set to where they cross, when they do: on the first segment, at its fraction.
		@return  True when they cross, their ends included. */
	public static function intersectSegments(ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float, dx:Float, dy:Float, ?out:Vector2D):Bool {
		var rx = bx - ax, ry = by - ay, sx = dx - cx, sy = dy - cy;
		var div = rx * sy - ry * sx;
		if (Math.abs(div) < EPSILON)
			return false;
		var acx = cx - ax, acy = cy - ay;
		var t = (acx * sy - acy * sx) / div, u = (acx * ry - acy * rx) / div;
		if (t < 0 || t > 1 || u < 0 || u > 1)
			return false;
		if (out != null)
			out.set(ax + t * rx, ay + t * ry);
		return true;
	}

	/** Returns whether a point is inside a triangle, its edges not included.

		@param x  The point's x.
		@param y  Its y.
		@param ax  The triangle's first corner's x.
		@param ay  Its y.
		@param bx  The second corner's x.
		@param by  Its y.
		@param cx  The third corner's x.
		@param cy  Its y.
		@return  True when it is inside; false for a triangle with no area. */
	public static function isPointInTriangle(x:Float, y:Float, ax:Float, ay:Float, bx:Float, by:Float, cx:Float, cy:Float):Bool {
		var d = (by - cy) * (ax - cx) + (cx - bx) * (ay - cy);
		var alpha = ((by - cy) * (x - cx) + (cx - bx) * (y - cy)) / d;
		var beta = ((cy - ay) * (x - cx) + (ax - cx) * (y - cy)) / d;
		return alpha > 0 && beta > 0 && 1 - alpha - beta > 0;
	}

	/** Returns whether a point is inside a polygon, by how many of its edges a ray from the point crosses. A point on an edge may count
		either way.

		@param x  The point's x.
		@param y  Its y.
		@param points  The polygon's corners in order, flat: x, y, x, y.
		@return  True when it is inside; false for fewer than 3 corners. */
	public static function isPointInPolygon(x:Float, y:Float, points:Array<Float>):Bool {
		var count = points.length >> 1, inside = false;
		if (count < 3)
			return false;
		var j = count - 1;
		for (i in 0...count) {
			var ix = points[i * 2],
				iy = points[i * 2 + 1],
				jx = points[j * 2],
				jy = points[j * 2 + 1];
			if ((iy > y) != (jy > y) && x < (jx - ix) * (y - iy) / (jy - iy) + ix)
				inside = !inside;
			j = i;
		}
		return inside;
	}

	/** Returns how far a point is from the nearest point of a segment.

		@param x  The point's x.
		@param y  Its y.
		@param ax  The segment's start x.
		@param ay  Its start y.
		@param bx  Its end x.
		@param by  Its end y.
		@return  The distance. */
	public static function getDistanceToSegment(x:Float, y:Float, ax:Float, ay:Float, bx:Float, by:Float):Float {
		var dx = bx - ax, dy = by - ay, lengthSquared = dx * dx + dy * dy;
		var t = lengthSquared == 0 ? 0 : ((x - ax) * dx + (y - ay) * dy) / lengthSquared;
		t = t < 0 ? 0 : t > 1 ? 1 : t;
		var nx = ax + t * dx - x, ny = ay + t * dy - y;
		return Math.sqrt(nx * nx + ny * ny);
	}

	/** Returns whether a circle and a segment touch.

		@param cx  The circle's center x.
		@param cy  Its center y.
		@param radius  Its radius.
		@param ax  The segment's start x.
		@param ay  Its start y.
		@param bx  Its end x.
		@param by  Its end y.
		@return  True when they touch, the circle's edge included. */
	public static function intersectsCircleSegment(cx:Float, cy:Float, radius:Float, ax:Float, ay:Float, bx:Float, by:Float):Bool
		return getDistanceToSegment(cx, cy, ax, ay, bx, by) <= radius;
}
