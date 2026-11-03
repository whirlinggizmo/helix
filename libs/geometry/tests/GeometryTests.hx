import helix.geometry.Geometry2D;
import helix.math.Vector2D;

/** Checks Geometry2D with the library alone: segments crossing (parallel, end-to-end and nearly vertical ones too), points in triangles and polygons,
	distances to segments and circles touching them. */
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
		check(Geometry2D.intersectSegments(520.21936, 67.8957138, 520.219299, 179.760956, 469.264191, 99.073822, 571.237671, 101.955383, p)
			&& Math.abs(p.x - 520.2193422) < 1e-6
			&& Math.abs(p.y - 100.5137099) < 1e-6,
			"a nearly vertical segment, its x spanning a few millionths");

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

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
