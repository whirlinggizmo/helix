import helix.geometry.Geometry3D;
import helix.math.Vector3;

/** Checks Geometry3D with the library alone, against answers worked by hand: the nearest point on a segment along it, before its start,
	past its end and of no length; the distance to a segment; the nearest point on a triangle over its inside, each edge and each corner,
	and on one of no area; and where two segments come nearest, crossing, apart, parallel, end to end and of no length. */
class Geometry3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) <= tolerance;

	static function at(v:Vector3, x:Float, y:Float, z:Float, tolerance = 1e-12):Bool
		return near(v.x, x, tolerance) && near(v.y, y, tolerance) && near(v.z, z, tolerance);

	// The nearest point of the triangle (0, 0, 0), (4, 0, 0), (0, 4, 0).
	static function onTriangle(x:Float, y:Float, z:Float):Vector3
		return Geometry3D.getClosestPointOnTriangle(x, y, z, 0, 0, 0, 4, 0, 0, 0, 4, 0);

	// The nearest point of a triangle found by trying many points of the triangle: within a step's length of the true one.
	static function searched(x:Float, y:Float, z:Float, t:Array<Float>):Float {
		var best = Math.POSITIVE_INFINITY;
		var steps = 200;
		for (i in 0...steps + 1)
			for (j in 0...steps + 1 - i) {
				var u = i / steps, v = j / steps, w = 1 - u - v;
				var dx = t[0] * w + t[3] * u + t[6] * v - x,
					dy = t[1] * w + t[4] * u + t[7] * v - y,
					dz = t[2] * w + t[5] * u + t[8] * v - z;
				var distance = dx * dx + dy * dy + dz * dz;
				if (distance < best)
					best = distance;
			}
		return Math.sqrt(best);
	}

	static function main():Void {
		// A segment.
		check(at(Geometry3D.getClosestPointOnSegment(3, 5, 2, 0, 0, 0, 10, 0, 0), 3, 0, 0), "beside a segment: the point along it");
		check(at(Geometry3D.getClosestPointOnSegment(-4, 5, 2, 0, 0, 0, 10, 0, 0), 0, 0, 0)
			&& at(Geometry3D.getClosestPointOnSegment(14, 5, 2, 0, 0, 0, 10, 0, 0), 10, 0, 0),
			"before its start and past its end: the ends");
		check(at(Geometry3D.getClosestPointOnSegment(2.5, 2, 3, 1, 2, 3, 3, 0, 5), 1.5, 1.5, 3.5), "a slanted segment");
		check(at(Geometry3D.getClosestPointOnSegment(9, 9, 9, 1, 2, 3, 1, 2, 3), 1, 2, 3), "a segment of no length: its start");
		var point = new Vector3();
		check(Geometry3D.getClosestPointOnSegment(5, 1, 0, 0, 0, 0, 10, 0, 0, point) == point
			&& at(point, 5, 0, 0), "into the vector provided");
		check(near(Geometry3D.getDistanceToSegment(3, 3, 4, 0, 0, 0, 10, 0, 0), 5)
			&& near(Geometry3D.getDistanceToSegment(-3, 4, 0, 0, 0, 0, 10, 0, 0), 5)
			&& near(Geometry3D.getDistanceToSegment(10, 0, 12, 0, 0, 0, 10, 0, 0), 12)
			&& Geometry3D.getDistanceToSegment(4, 0, 0, 0, 0, 0, 10, 0, 0) == 0,
			"the distance beside it, past each end, and on it");
		check(near(Geometry3D.getDistanceToSegment(4, 6, 3, 1, 2, 3, 1, 2, 3), 5), "the distance to a segment of no length");

		// A triangle: its inside, its three edges and its three corners.
		check(at(onTriangle(1, 1, 5), 1, 1, 0) && at(onTriangle(1, 2, -3), 1, 2, 0), "over a triangle's inside, from either side: straight down");
		check(at(onTriangle(1, 1, 0), 1, 1, 0), "on the triangle: the point");
		check(at(onTriangle(-1, -1, 2), 0, 0, 0) && at(onTriangle(6, -1, 0), 4, 0, 0) && at(onTriangle(-1, 6, 1), 0, 4, 0), "past each corner: the corner");
		check(at(onTriangle(2, -3, 1), 2, 0, 0) && at(onTriangle(-3, 2, 1), 0, 2, 0) && at(onTriangle(3, 3, 1), 2, 2, 0),
			"past each edge: the point along the edge");
		check(at(onTriangle(4, 0, 9), 4, 0, 0) && at(onTriangle(2, 2, 9), 2, 2, 0), "over a corner, and over an edge");
		check(onTriangle(7, 7, 7) != point
			&& Geometry3D.getClosestPointOnTriangle(1, 1, 5, 0, 0, 0, 4, 0, 0, 0, 4, 0, point) == point
			&& at(point, 1, 1, 0),
			"into the vector provided");
		check(at(Geometry3D.getClosestPointOnTriangle(3, 1, 0, 0, 0, 0, 2, 0, 0, 4, 0, 0), 3, 0, 0),
			"a triangle of no area, its corners in a line: that segment");
		check(at(Geometry3D.getClosestPointOnTriangle(3, 1, 0, 2, 2, 2, 2, 2, 2, 2, 2, 2), 2, 2, 2), "a triangle of one point: that point");
		var leaning = [1., 0, 2, 5, 1, -1, 2, 4, 3];
		var worst = 0.;
		for (index in 0...40) {
			var x = (index * 7 % 11) - 3.3,
				y = (index * 5 % 13) - 4.1,
				z = (index * 3 % 7) - 2.7;
			Geometry3D.getClosestPointOnTriangle(x, y, z, leaning[0], leaning[1], leaning[2], leaning[3], leaning[4], leaning[5], leaning[6], leaning[7],
				leaning[8], point);
			var found = Math.sqrt((point.x - x) * (point.x - x) + (point.y - y) * (point.y - y) + (point.z - z) * (point.z - z));
			var gap = Math.abs(found - searched(x, y, z, leaning));
			// The found point is never further than the searched one, and the search is within a step of the truth.
			if (found > searched(x, y, z, leaning) + 1e-9 || gap > .05)
				worst = Math.max(worst, gap + 1);
		}
		check(worst == 0, "a leaning triangle: 40 points' nearest as near as a search of the triangle finds");

		// Two segments.
		var a = new Vector3(), b = new Vector3();
		check(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 2, 0, 0, 1, -1, 0, 1, 1, 0, a, b) == 0
			&& at(a, 1, 0, 0)
			&& at(b, 1, 0, 0),
			"segments crossing: no distance, both points the crossing");
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 2, 0, 0, 1, -1, 3, 1, 1, 3, a, b), 3)
			&& at(a, 1, 0, 0)
			&& at(b, 1, 0, 3),
			"one passing over the other: the gap, and the point on each");
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 1, 0, 0, 3, 2, 0, 3, 5, 0, a, b), Math.sqrt(8))
			&& at(a, 1, 0, 0)
			&& at(b, 3, 2, 0),
			"short of each other: an end of each");
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 4, 0, 0, 1, 2, -3, 1, 2, 3, a, b), 2)
			&& at(a, 1, 0, 0)
			&& at(b, 1, 2, 0),
			"the middle of each");
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 2, 0, 0, 0, 1, 0, 2, 1, 0, a, b), 1)
			&& at(a, 0, 0, 0)
			&& at(b, 0, 1, 0),
			"parallel, side by side: the first's start and the point of the second beside it");
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 2, 0, 0, 5, 1, 0, 7, 1, 0, a, b), Math.sqrt(10))
			&& at(a, 2, 0, 0)
			&& at(b, 5, 1, 0),
			"parallel, one past the other: the nearest ends");
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 2, 0, 0, -7, 1, 0, -5, 1, 0, a, b), Math.sqrt(26))
			&& at(a, 0, 0, 0)
			&& at(b, -5, 1, 0),
			"parallel, one before the other: the nearest ends");
		check(near(Geometry3D.getClosestPointsBetweenSegments(1, 2, 3, 1, 2, 3, 4, 6, 3, 4, 6, 3, a, b), 5)
			&& at(a, 1, 2, 3)
			&& at(b, 4, 6, 3),
			"both of no length: their points");
		check(near(Geometry3D.getClosestPointsBetweenSegments(5, 3, 0, 5, 3, 0, 0, 0, 0, 10, 0, 0, a, b), 3)
			&& at(a, 5, 3, 0)
			&& at(b, 5, 0, 0),
			"the first of no length: its point, and the second's nearest");
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 10, 0, 0, 12, 0, 4, 12, 0, 4, a, b), Math.sqrt(20))
			&& at(a, 10, 0, 0)
			&& at(b, 12, 0, 4),
			"the second of no length: its point, and the first's nearest");
		a.set(9, 9, 9);
		check(near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 2, 0, 0, 1, -1, 3, 1, 1, 3), 3)
			&& near(Geometry3D.getClosestPointsBetweenSegments(0, 0, 0, 2, 0, 0, 1, -1, 3, 1, 1, 3, null, b), 3)
			&& at(a, 9, 9, 9)
			&& at(b, 1, 0, 3),
			"the distance alone, and with one point asked for");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
