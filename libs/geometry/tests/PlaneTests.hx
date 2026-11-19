import helix.geometry.Aabb3D;
import helix.math.Matrix4;
import helix.geometry.Plane;
import helix.geometry.Sphere;
import helix.math.Vector3;

/** Checks Plane with the library alone, against answers worked by hand: made through a point and through three points, a direction of
	no length and points in a line; distances in front and behind; the nearest point; a segment crossing, touching, apart and lying in
	the plane; three planes' point; spheres and boxes touching and apart; and a plane moved by matrices that turn, scale each axis by
	its own amount, shear, mirror and flatten. */
class PlaneTests {
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

	static function is(plane:Plane, x:Float, y:Float, z:Float, distance:Float, tolerance = 1e-12):Bool
		return at(plane.normal, x, y, z, tolerance) && near(plane.distance, distance, tolerance);

	// Whether a plane moved by a matrix keeps every point on the side the point was on, and the plane's points on the plane.
	static function keepsSides(plane:Plane, matrix:Matrix4):Bool {
		var moved = plane.transform(matrix);
		if (!near(moved.normal.length, 1))
			return false;
		var point = new Vector3(), on = new Vector3();
		for (index in 0...60) {
			var x = (index * 7 % 11) - 5.3,
				y = (index * 5 % 13) - 6.1,
				z = (index * 3 % 7) - 3.7;
			var before = plane.getDistanceTo(x, y, z);
			matrix.transformPoint(x, y, z, point);
			var after = moved.getDistanceTo(point.x, point.y, point.z);
			if (Math.abs(before) > 1e-9 && (before > 0) != (after > 0))
				return false;
			plane.getClosestPoint(x, y, z, on);
			matrix.transformPoint(on.x, on.y, on.z, on);
			if (!near(moved.getDistanceTo(on.x, on.y, on.z), 0, 1e-9))
				return false;
		}
		return true;
	}

	static function main():Void {
		var ground = new Plane();
		check(is(ground, 0, 1, 0, 0), "made: the ground, facing up");
		var wall = new Plane(1, 0, 0, -3);
		check(is(wall, 1, 0, 0, -3) && wall.getDistanceTo(5, 9, 9) == 2 && wall.getDistanceTo(0, 0, 0) == -3,
			"made facing +x at x 3: distances in front and behind");
		check(ground.set(0, 0, 1, 4) == ground && is(ground, 0, 0, 1, 4), "set");
		var copy = new Plane().copyFrom(wall);
		check(is(copy, 1, 0, 0, -3) && copy.normal != wall.normal, "copied, with a normal of its own");

		// Through a point, and through three.
		var floor = Plane.fromPointNormal(0, 2, 0, 0, 1, 0);
		check(is(floor, 0, 1, 0, -2) && floor.getDistanceTo(7, 5, -1) == 3 && floor.getDistanceTo(0, 0, 0) == -2, "through a point: above and below");
		check(is(Plane.fromPointNormal(0, 2, 0, 0, 5, 0), 0, 1, 0, -2), "a direction of any length");
		check(is(Plane.fromPointNormal(1, 1, 1, 3, 0, 4), .6, 0, .8, -1.4), "a tilted direction, made of length 1");
		check(is(Plane.fromPointNormal(4, 2, 9, 0, 0, 0), 0, 1, 0, -2), "a direction of length 0: facing up, through the point");
		var into = new Plane();
		check(Plane.fromPointNormal(0, 0, 5, 0, 0, -1, into) == into && is(into, 0, 0, -1, 5), "into the plane provided");
		check(is(Plane.fromPoints(0, 1, 0, 1, 1, 0, 0, 1, -1), 0, 1, 0, -1), "three points counterclockwise from above: facing up");
		check(is(Plane.fromPoints(0, 1, 0, 0, 1, -1, 1, 1, 0), 0, -1, 0, 1), "the same points the other way round: facing down");
		check(is(Plane.fromPoints(1, 3, 1, 2, 3, 1, 3, 3, 1), 0, 1, 0, -3), "three points in a line: facing up, through the first");
		check(Plane.fromPoints(0, 0, 0, 0, 0, 1, 0, 1, 0, into) == into && is(into, -1, 0, 0, 0), "three points into the plane provided");

		// The nearest point.
		var tilted = Plane.fromPointNormal(0, 0, 0, 1, 1, 0);
		check(at(tilted.getClosestPoint(2, 0, 5), 1, -1, 5), "the nearest point on a tilted plane");
		var point = new Vector3();
		check(floor.getClosestPoint(3, -8, 4, point) == point && at(point, 3, 2, 4), "the nearest point, into the vector provided");

		// A segment.
		check(at(floor.intersectSegment(0, 0, 0, 0, 8, 0), 0, 2, 0), "a segment crossing, and where");
		check(at(floor.intersectSegment(1, 6, 1, 3, 0, 5), 7 / 3, 2, 11 / 3), "a slanted segment from the front to the back");
		check(at(floor.intersectSegment(1, 2, 1, 5, 9, 5), 1, 2, 1) && at(floor.intersectSegment(5, 9, 5, 1, 2, 1), 1, 2, 1),
			"an end on the plane crosses there");
		check(at(floor.intersectSegment(1, 2, 1, 6, 2, 4), 1, 2, 1), "a segment lying in the plane: its start");
		point.set(9, 9, 9);
		check(floor.intersectSegment(0, 3, 0, 5, 8, 0, point) == null
			&& floor.intersectSegment(0, 1, 0, 5, -8, 0, point) == null
			&& at(point, 9, 9, 9),
			"both ends on one side: none, the vector unchanged");
		check(floor.intersectSegment(0, 0, 0, 0, 4, 0, point) == point && at(point, 0, 2, 0), "a crossing into the vector provided");

		// Three planes.
		var atX = Plane.fromPointNormal(1, 0, 0, 1, 0, 0),
			atY = Plane.fromPointNormal(0, 2, 0, 0, -1, 0),
			atZ = Plane.fromPointNormal(0, 0, 3, 0, 0, 1);
		check(at(Plane.intersectPlanes(atX, atY, atZ), 1, 2, 3), "three planes square to each other: their corner");
		var leaning = Plane.fromPointNormal(1, 2, 3, 1, 2, -1),
			other = Plane.fromPointNormal(1, 2, 3, -3, 1, 1);
		check(at(Plane.intersectPlanes(leaning, other, atX), 1, 2, 3), "three leaning planes through one point");
		point.set(9, 9, 9);
		check(Plane.intersectPlanes(atX, Plane.fromPointNormal(5, 0, 0, 1, 0, 0), atZ, point) == null && at(point, 9, 9, 9),
			"two of them parallel: none, the vector unchanged");
		check(Plane.intersectPlanes(atX, atY, Plane.fromPointNormal(0, 0, 0, 1, 1, 0)) == null, "all three along one line: none");
		check(Plane.intersectPlanes(atX, atY, atZ, point) == point && at(point, 1, 2, 3), "the point into the vector provided");

		// Spheres and boxes.
		check(floor.intersectsSphere(new Sphere(0, 2.5, 0, 1))
			&& floor.intersectsSphere(new Sphere(0, 1, 0, 1))
			&& floor.intersectsSphere(new Sphere(4, 3, 4, 1))
			&& !floor.intersectsSphere(new Sphere(0, 3.01, 0, 1))
			&& !floor.intersectsSphere(new Sphere(0, .99, 0, 1)),
			"a sphere crossing, touching from either side, and just apart");
		check(!floor.intersectsSphere(new Sphere(0, 2, 0, 1).makeEmpty())
			&& !floor.intersectsSphere(new Sphere(0, 2, 0, -1)), "an empty sphere: never");
		check(floor.intersectsBounds(new Aabb3D().set(-1, 1, -1, 1, 3, 1))
			&& floor.intersectsBounds(new Aabb3D().set(-1, 2, -1, 1, 3, 1))
			&& !floor.intersectsBounds(new Aabb3D().set(-1, 2.01, -1, 1, 3, 1))
			&& !floor.intersectsBounds(new Aabb3D().set(-1, -3, -1, 1, 1.99, 1)),
			"a box crossing, touching, and just apart on either side");
		check(tilted.intersectsBounds(new Aabb3D().set(-3, 1, 0, -1, 3, 1))
			&& tilted.intersectsBounds(new Aabb3D().set(.99, -1, 0, 2, 0, 1))
			&& !tilted.intersectsBounds(new Aabb3D().set(1.01, -1, 0, 2, 0, 1)),
			"a tilted plane through a box's corners, just into one, and just apart");
		check(!floor.intersectsBounds(new Aabb3D()), "an empty box: never");

		// Moved by a matrix.
		check(is(floor.transform(Matrix4.fromTranslation(5, 3, -2)), 0, 1, 0, -5), "moved up 3");
		check(is(floor.transform(Matrix4.fromRotation(0, 0, 1, Math.PI / 2)), -1, 0, 0, -2, 1e-12), "turned a quarter around z: facing -x");
		check(is(tilted.transform(Matrix4.fromScale(2, 1, 1)), 1 / Math.sqrt(5), 2 / Math.sqrt(5), 0, 0), "scaled along x alone: the normal leans to y");
		check(is(wall.transform(Matrix4.fromScale(-1, 1, 1)), -1, 0, 0, -3)
			&& wall.transform(Matrix4.fromScale(-1, 1, 1)).getDistanceTo(-5, 0, 0) == 2,
			"mirrored: the front stays the front");
		check(is(floor.transform(Matrix4.fromScale(1, 3, 1)), 0, 1, 0, -6), "scaled along its normal: three times as far");
		var shear = Matrix4.fromArray([1, 0, 0, 0, .7, 1, .2, 0, 0, -.4, 1, 0, 2, -1, 3, 1]);
		var mixed = Matrix4.fromScale(-2, .5, 3).appendRotation(1, 2, -1, 1.1).appendTranslation(4, -2, 1);
		var planes = [floor, wall, tilted, leaning, other];
		var matrices = [
			Matrix4.fromRotation(1, 1, 1, .8),
			Matrix4.fromScale(3, .25, 1.5),
			Matrix4.fromScale(1, -2, 1),
			shear,
			mixed,
			Matrix4.compose(shear, mixed)
		];
		for (p in 0...planes.length)
			for (m in 0...matrices.length)
				check(keepsSides(planes[p], matrices[m]), 'plane $p moved by matrix $m: each point on the side the point was, the normal of length 1');
		check(is(new Plane().transform(Matrix4.fromScale(1, 0, 1)), 0, 1, 0, 0), "flattened along its normal: the same plane");
		check(is(floor.transform(Matrix4.fromScale(0, 0, 1)), 0, 1, 0, 0), "flattened to a line: its normal kept, through the moved point");
		var moving = new Plane().copyFrom(floor);
		check(moving.transform(Matrix4.fromTranslation(0, 1, 0), moving) == moving && is(moving, 0, 1, 0, -3) && is(floor, 0, 1, 0, -2),
			"moved into the plane itself");
		check(floor.transform(Matrix4.fromTranslation(0, 1, 0), into) == into && is(into, 0, 1, 0, -3), "moved into the plane provided");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
