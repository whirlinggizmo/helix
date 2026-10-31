import helix.math.DistanceField2D;
import helix.math.Geometry2D;
import helix.math.Interpolate;
import helix.math.Vector2D;
import helix.math.RectPacker2D;

/** Checks Geometry2D, Interpolate's spline pieces, DistanceField2D and RectPacker2D with the library alone: segments crossing (parallel
	and end-to-end ones too), points in triangles and polygons, distances to segments and circles touching them; each spline piece at its
	ends and middle; a distance field against measured distances; and rectangles packed apart, inside the area, tallest first. */
class GeometryTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function main():Void {
		var p = new Vector2D();
		check(Geometry2D.intersectSegments(0, 0, 10, 10, 0, 10, 10, 0, p) && near(p.x, 5) && near(p.y, 5), "segments crossing, and where");
		check(!Geometry2D.intersectSegments(0, 0, 4, 4, 0, 10, 10, 0), "short of each other: no crossing");
		check(!Geometry2D.intersectSegments(0, 0, 10, 0, 0, 1, 10, 1) && !Geometry2D.intersectSegments(0, 0, 10, 0, 5, 0, 15, 0),
			"parallel, and overlapping: no crossing");
		check(Geometry2D.intersectSegments(0, 0, 10, 0, 10, -5, 10, 5, p) && near(p.x, 10), "meeting at an end crosses");
		check(Geometry2D.intersectSegments(5, -5, 5, 5, 0, 0, 10, 0, p) && near(p.x, 5) && near(p.y, 0), "a vertical segment");

		check(Geometry2D.isPointInTriangle(2, 1, 0, 0, 6, 0, 0, 6), "inside a triangle");
		check(!Geometry2D.isPointInTriangle(5, 5, 0, 0, 6, 0, 0, 6) && !Geometry2D.isPointInTriangle(3, 0, 0, 0, 6, 0, 0, 6),
			"outside, and on an edge: not in");
		check(Geometry2D.isPointInTriangle(2, 1, 0, 0, 0, 6, 6, 0), "either winding");
		var square = [0., 0, 10, 0, 10, 10, 0, 10],
			notch = [0., 0, 10, 0, 10, 10, 5, 2, 0, 10];
		check(Geometry2D.isPointInPolygon(5, 5, square) && !Geometry2D.isPointInPolygon(11, 5, square), "in and out of a square");
		check(!Geometry2D.isPointInPolygon(5, 8, notch) && Geometry2D.isPointInPolygon(8, 5, notch), "a concave polygon's notch is out");
		check(!Geometry2D.isPointInPolygon(0, 0, [0., 0, 1, 1]), "under 3 corners, nothing is in");

		check(near(Geometry2D.getDistanceToSegment(5, 3, 0, 0, 10, 0), 3), "to a segment's middle");
		check(near(Geometry2D.getDistanceToSegment(13, 4, 0, 0, 10, 0), 5), "past its end, to the end");
		check(near(Geometry2D.getDistanceToSegment(3, 4, 0, 0, 0, 0), 5), "to a segment of no length, its point");
		check(Geometry2D.intersectsCircleSegment(5, 3, 3, 0, 0, 10, 0) && !Geometry2D.intersectsCircleSegment(5, 3, 2.9, 0, 0, 10, 0),
			"a circle touching a segment, edge included");

		check(near(Interpolate.catmullRom(0, 1, 2, 3, 0), 1)
			&& near(Interpolate.catmullRom(0, 1, 2, 3, 1), 2)
			&& near(Interpolate.catmullRom(0, 1, 2, 3, .5), 1.5),
			"Catmull-Rom: through the middle two, evenly on a line");
		check(near(Interpolate.bSpline(0, 6, 12, 18, 0), 6) && near(Interpolate.bSpline(0, 0, 6, 0, 0), 1),
			"B-spline: on a line through its points; near, not through, a peak");
		check(near(Interpolate.quadraticBezier(0, 10, 0, 0), 0)
			&& near(Interpolate.quadraticBezier(0, 10, 0, .5), 5)
			&& near(Interpolate.quadraticBezier(0, 10, 4, 1), 4),
			"quadratic Bezier: its ends, halfway to the control point");
		check(near(Interpolate.cubicBezier(0, 10, 10, 0, .5), 7.5) && near(Interpolate.cubicBezier(1, 5, 7, 2, 1), 2), "cubic Bezier");

		// A 7 by 5 grid, zeros at (1, 1) and (5, 3): each cell's squared distance to the nearer.
		var grid = [for (_ in 0...35) 1e20];
		grid[1 * 7 + 1] = 0;
		grid[3 * 7 + 5] = 0;
		DistanceField2D.transform(grid, 7, 5);
		var right = true;
		for (y in 0...5)
			for (x in 0...7) {
				var a = (x - 1) * (x - 1) + (y - 1) * (y - 1),
					b = (x - 5) * (x - 5) + (y - 3) * (y - 3);
				right = right && grid[y * 7 + x] == (a < b ? a : b);
			}
		check(right, "a distance field: each cell's squared distance to the nearest zero");

		var sizes = [10, 30, 20, 10, 20, 20, 5, 5, 0, 4],
			places = RectPacker2D.pack(40, 40, sizes);
		var placed = true;
		for (i in 0...4) {
			var x = places[i * 3],
				y = places[i * 3 + 1],
				w = sizes[i * 2],
				h = sizes[i * 2 + 1];
			placed = placed && places[i * 3 + 2] == 1 && x >= 0 && y >= 0 && x + w <= 40 && y + h <= 40;
			for (j in 0...i) {
				var ox = places[j * 3], oy = places[j * 3 + 1];
				placed = placed && (x + w <= ox || ox + sizes[j * 2] <= x || y + h <= oy || oy + sizes[j * 2 + 1] <= y);
			}
		}
		check(placed, "packed: every rectangle inside the area, none overlapping");
		check(places[0] == 0 && places[1] == 0 && places[12] == 0 && places[13] == 0 && places[14] == 1, "the tallest at the corner; an empty one at 0, 0");
		var full = RectPacker2D.pack(10, 10, [10, 10, 1, 1]);
		check(full[2] == 1 && full[5] == 0, "one too many doesn't fit, and says so");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
