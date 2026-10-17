import helix.collision.Collide2D;
import helix.collision.Hit2D;
import helix.collision.Move2D;
import helix.collision.SpatialHash2D;

/** 2D collision (helix.collision): overlaps of rectangles, circles and polygons, points inside, segments and rays with where and the
	normal, sweeps, a box moved and slid over tiles, and a spatial hash narrowing the pairs. */
class CollisionTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, e = 1e-9):Bool
		return Math.abs(a - b) < e;

	static function main():Void {
		// Overlaps.
		check(Collide2D.rectRect(0, 0, 10, 10, 5, 5, 10, 10)
			&& !Collide2D.rectRect(0, 0, 10, 10, 10, 0, 10, 10)
			&& !Collide2D.rectRect(0, 0, 10, 10, 11, 0, 1, 1),
			"Rectangles overlap, not when touching");
		check(Collide2D.circleCircle(0, 0, 5, 8, 0, 4) && !Collide2D.circleCircle(0, 0, 5, 9, 0, 4), "Circles overlap, not when touching");
		check(Collide2D.rectCircle(0, 0, 10, 10, 12, 5, 3)
			&& !Collide2D.rectCircle(0, 0, 10, 10, 13, 5, 3)
			&& Collide2D.rectCircle(0, 0, 10, 10, 5, 5, 1),
			"A rectangle and a circle: by the nearest point, and a circle inside");
		check(!Collide2D.rectCircle(0, 0, 10, 10, 12, 12, 2.8)
			&& Collide2D.rectCircle(0, 0, 10, 10, 12, 12, 2.9), "at a corner, by distance (sqrt 8 away)");
		check(Collide2D.pointInRect(0, 0, 0, 0, 10, 10)
			&& !Collide2D.pointInRect(10, 5, 0, 0, 10, 10)
			&& Collide2D.pointInCircle(3, 4, 0, 0, 5.1)
			&& !Collide2D.pointInCircle(3, 4, 0, 0, 5),
			"Points in a rectangle (its left and top edges in, right and bottom out) and a circle");
		var square = [0., 0, 10, 0, 10, 10, 0, 10],
			arrow = [0., 0, 10, 5, 0, 10, 4, 5];
		check(Collide2D.pointInPolygon(5, 5, square)
			&& !Collide2D.pointInPolygon(15, 5, square)
			&& Collide2D.pointInPolygon(6, 5, arrow)
			&& Collide2D.pointInPolygon(1.5, 1, arrow)
			&& !Collide2D.pointInPolygon(1, 5, arrow)
			&& !Collide2D.pointInPolygon(3, 1, arrow),
			"Points in polygons, concave too");
		var hit = new Hit2D();
		var diamond = [13., 3, 18, 8, 13, 13, 8, 8];
		check(Collide2D.polygonPolygon(square, [8., 8, 18, 8, 18, 18, 8, 18])
			&& !Collide2D.polygonPolygon(square, [10., 0, 20, 0, 20, 10, 10, 10])
			&& Collide2D.polygonPolygon(square, diamond)
			&& !Collide2D.polygonPolygon(square, [5., 10, 15, 20, 5, 30, -5, 20]),
			"Convex polygons overlap by the separating axis theorem; a diamond's tip in, or just touching, out");
		Collide2D.polygonPolygon(square, [8., 0, 18, 0, 18, 10, 8, 10], hit);
		check(near(hit.depth, 2) && near(hit.normalX, -1) && near(hit.normalY, 0), "The least move apart, out of the other");
		check(Collide2D.polygonCircle(square, 12, 5, 3)
			&& !Collide2D.polygonCircle(square, 13.5, 5, 3)
			&& Collide2D.polygonCircle(square, 5, 5, 1),
			"A polygon and a circle: by its edges, and a circle inside");
		check(Collide2D.rectPolygon(0, 0, 10, 10, diamond)
			&& !Collide2D.rectPolygon(0, 0, 10, 10, [20., 0, 30, 0, 25, 10]), "A rectangle and a polygon");

		// Segments and rays.
		check(Collide2D.segmentSegment(0, 0, 10, 10, 0, 10, 10, 0, hit) && near(hit.time, .5) && near(hit.x, 5) && near(hit.y, 5),
			"Crossing segments, where along the first");
		check(near(hit.normalX, -Math.sqrt(.5)) && near(hit.normalY, -Math.sqrt(.5)), "The crossed segment's normal faces the first's start");
		check(!Collide2D.segmentSegment(0, 0, 10, 0, 0, 1, 10, 1) && !Collide2D.segmentSegment(0, 0, 10, 0, 5, 0, 5, 10),
			"Parallel, or only touching: no crossing");
		check(Collide2D.rayRect(-5, 5, 20, 0, 0, 0, 10, 10, hit)
			&& near(hit.time, .25)
			&& near(hit.x, 0)
			&& near(hit.y, 5)
			&& hit.normalX == -1
			&& hit.normalY == 0,
			"A ray meets a rectangle's left side with its normal");
		check(Collide2D.rayRect(5, 20, 0, -30, 0, 0, 10, 10, hit)
			&& near(hit.time, 1 / 3)
			&& hit.normalY == 1, "from below, the bottom's normal");
		check(!Collide2D.rayRect(-5, 15, 20, 0, 0, 0, 10, 10, hit)
			&& !Collide2D.rayRect(-5, 5, 2, 0, 0, 0, 10, 10, hit), "A miss, and a ray too short");
		check(Collide2D.rayRect(5, 5, 20, 0, 0, 0, 10, 10, hit) && hit.time == 0 && hit.normalX == 0, "From inside: time 0, no normal");
		check(Collide2D.rayCircle(-10, 0, 20, 0, 0, 0, 5, hit) && near(hit.time, .25) && near(hit.x, -5) && near(hit.normalX, -1),
			"A ray meets a circle with its normal");
		check(!Collide2D.rayCircle(-10, 6, 20, 0, 0, 0, 5, hit)
			&& !Collide2D.rayCircle(-10, 0, 4, 0, 0, 0, 5, hit), "A miss, and too short");
		check(Collide2D.rayCircle(1, 1, 20, 0, 0, 0, 5, hit) && hit.time == 0, "From inside: time 0");

		// Sweeps.
		check(Collide2D.sweepRectRect(0, 0, 4, 4, 20, 0, 10, 0, 4, 4, hit)
			&& near(hit.time, .3)
			&& near(hit.x, 6)
			&& hit.normalX == -1,
			"A rectangle swept into another stops at its side");
		check(!Collide2D.sweepRectRect(0, 0, 4, 4, 20, 0, 10, 5, 4, 4, hit)
			&& Collide2D.sweepRectRect(0, 0, 4, 4, 20, 0, 2, 2, 4, 4, hit)
			&& hit.time == 0,
			"A sweep that misses, and one already overlapping");
		check(Collide2D.sweepCircleCircle(0, 0, 2, 20, 0, 10, 0, 3, hit) && near(hit.time, .25) && near(hit.x, 5),
			"Circles swept together meet at their radii");

		// Move and slide over tiles: a floor at row 2 (y 20 to 30), a wall at column 5 (x 50 to 60).
		var solid = (col:Int, row:Int) -> row == 2 || col == 5;
		var move = new Move2D();
		Collide2D.moveAndSlide(10, 5, 8, 8, 0, 20, 10, solid, move);
		check(near(move.x, 10) && near(move.y, 12) && move.bottom && !move.top && !move.left && !move.right,
			"Falling onto the floor stops on it, bottom touching");
		Collide2D.moveAndSlide(10, 12, 8, 8, 100, 0, 10, solid, move);
		check(near(move.x, 42) && near(move.y, 12) && move.right && !move.bottom, "Running into the wall stops at it, right touching");
		Collide2D.moveAndSlide(42, 12, 8, 8, -100, 0, 10, solid, move);
		check(near(move.x, -58) && !move.left, "Nothing to the left: all the way");
		Collide2D.moveAndSlide(70, 12, 8, 8, -30, 0, 10, solid, move);
		check(near(move.x, 60) && move.left, "From the right, the wall's other side, left touching");
		Collide2D.moveAndSlide(10, 35, 8, 8, 0, -20, 10, solid, move);
		check(near(move.y, 30) && move.top, "Jumping into the floor from below, top touching");
		Collide2D.moveAndSlide(10, 12, 8, 8, 3, 5, 10, solid, move);
		check(near(move.x, 13) && near(move.y, 12) && move.bottom, "A slide along the floor: across, down stopped");
		Collide2D.moveAndSlide(10, 12, 8, 8, 0, 0, 10, solid, move);
		check(near(move.x, 10) && near(move.y, 12) && !move.bottom, "Not moving touches nothing");
		Collide2D.moveAndSlide(10, 12, 8, 8, 50, 8, 10, solid, move);
		check(near(move.x, 42) && near(move.y, 12) && move.right && move.bottom, "Both at once: the wall and the floor");

		// A spatial hash narrows the pairs.
		var hash = new SpatialHash2D<{name:String}>(10);
		var a = {name: "a"}, b = {name: "b"}, c = {name: "c"};
		hash.insert(a, 0, 0, 5, 5);
		hash.insert(b, 12, 12, 5, 5);
		hash.insert(c, 8, 8, 30, 30);
		var found = [];
		hash.query(0, 0, 10, 10, found);
		var names = found.map(i -> i.name);
		names.sort((x, y) -> x < y ? -1 : 1);
		check(hash.getCount() == 3 && names.join(",") == "a,c", "A query gives the items in the cells it covers, each once");
		hash.query(50, 50, 5, 5, found);
		check(found.length == 0, "Nothing far away");
		hash.update(a, 50, 50, 5, 5);
		hash.query(50, 50, 5, 5, found);
		check(found.length == 1 && found[0] == a && hash.getCount() == 3, "A moved item is found at its new place");
		hash.query(0, 0, 5, 5, found);
		check(found.indexOf(a) < 0, "and not at its old one");
		check(hash.remove(b) && !hash.remove(b) && hash.getCount() == 2, "Removed once");
		hash.query(0, 0, 100, 100, found);
		check(found.length == 2, "A wide query finds each of the rest once");
		hash.clear();
		hash.query(0, 0, 100, 100, found);
		check(found.length == 0 && hash.getCount() == 0, "Cleared");
		var threw = false;
		try
			new SpatialHash2D<{}>(0)
		catch (e:Dynamic)
			threw = true;
		check(threw, "A cell size of 0 is refused");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
