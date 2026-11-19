import helix.geometry.Aabb3D;
import helix.math.Matrix4;
import helix.geometry.Sphere;
import helix.math.Vector3;

/** Checks Sphere with the library alone, against answers worked by hand: made, set, copied and empty; around a box and around points
	at an offset and a stride; points inside, on and outside; spheres and boxes touching and apart; the nearest point; grown to hold a
	point; the union of two apart, one in the other and an empty one; moved by a matrix; and the box around the sphere. */
class SphereTests {
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

	static function is(sphere:Sphere, x:Float, y:Float, z:Float, radius:Float, tolerance = 1e-12):Bool
		return at(sphere.center, x, y, z, tolerance) && near(sphere.radius, radius, tolerance);

	static function main():Void {
		var unit = new Sphere();
		check(is(unit, 0, 0, 0, 1) && !unit.isEmpty, "made: of radius 1 at the origin");
		var ball = new Sphere(1, 2, 3, 4);
		check(is(ball, 1, 2, 3, 4) && ball.set(5, 6, 7, 8) == ball && is(ball, 5, 6, 7, 8), "made and set");
		var copy = new Sphere().copyFrom(ball);
		check(is(copy, 5, 6, 7, 8) && copy.center != ball.center, "copied, with a center of its own");
		check(copy.makeEmpty() == copy && copy.isEmpty && is(copy, 0, 0, 0, -1) && !ball.isEmpty, "made empty, the original unchanged");
		check(new Sphere(0, 0, 0, 0).isEmpty == false && new Sphere(0, 0, 0, -.001).isEmpty && new Sphere(0, 0, 0, Math.NaN).isEmpty,
			"a radius of 0 holds its center; below 0, or not a number, is empty");

		// Around a box, and around points.
		check(is(Sphere.fromBounds(new Aabb3D().set(-1, -2, -3, 1, 2, 3)), 0, 0, 0, Math.sqrt(14)), "around a box: its center, half its diagonal");
		check(is(Sphere.fromBounds(new Aabb3D().set(2, 2, 2, 4, 2, 2)), 3, 2, 2, 1), "around a box of no height or depth");
		var into = new Sphere();
		check(Sphere.fromBounds(new Aabb3D(), into) == into && into.isEmpty, "around an empty box: empty, into the sphere provided");
		var points = [0., 0, 0, 2, 0, 0, 1, 1, 0];
		check(is(Sphere.fromPoints(points, 3), 1, .5, 0, Math.sqrt(1.25)), "around points: the middle of their bounds, the farthest point's distance");
		check(is(Sphere.fromPoints(points, 1), 0, 0, 0, 0) && is(Sphere.fromPoints(points, 2), 1, 0, 0, 1), "around one point, and two");
		var spaced = [9., 9, 0, 0, 0, 7, 7, 4, 0, 0, 7, 7, 0, 6, 0, 7, 7];
		check(is(Sphere.fromPoints(spaced, 3, 2, 5), 2, 3, 0, Math.sqrt(13)), "around points at an offset and a stride");
		check(Sphere.fromPoints(points, 0, 0, 3, into) == into && into.isEmpty, "around no points: empty");
		check(Sphere.fromPoints(points, 3, 0, 3, into) == into
			&& is(into, 1, .5, 0, Math.sqrt(1.25)), "around points, into the sphere provided");
		var holds = true;
		for (index in 0...3)
			holds = holds && into.contains(points[index * 3], points[index * 3 + 1], points[index * 3 + 2]);
		check(holds, "the sphere around points holds each of them");

		// Points.
		var reach = new Sphere(1, 0, 0, 2);
		check(reach.contains(1, 0, 0) && reach.contains(2, 1, 1) && reach.contains(3, 0, 0) && reach.contains(1, -2, 0), "a point inside, and on the surface");
		check(!reach.contains(3.01, 0, 0) && !reach.contains(2.2, 1.2, 1.2), "a point just outside");
		check(new Sphere(1, 0, 0, 0).contains(1, 0, 0) && !new Sphere(1, 0, 0, -1).contains(1, 0, 0),
			"radius 0 holds its center; an empty sphere holds no point");

		// Spheres and boxes.
		check(reach.intersects(new Sphere(4, 0, 0, 1))
			&& reach.intersects(new Sphere(1, .5, 0, .1))
			&& reach.intersects(new Sphere(1, 0, 0, 50))
			&& !reach.intersects(new Sphere(4.01, 0, 0, 1)),
			"spheres touching, one in the other, and just apart");
		check(!reach.intersects(new Sphere(1, 0, 0, -1))
			&& !new Sphere(1, 0, 0, -1).intersects(reach) && !new Sphere(0, 0, 0, -1).intersects(new Sphere(0, 0, 0, -1)),
			"an empty sphere overlaps no sphere");
		var crate = new Aabb3D().set(-1, -1, -1, 1, 2, 1);
		check(new Sphere(0, 0, 0,
			.1).intersectsBounds(crate)
				&& new Sphere(2, 3, 0,
					Math.sqrt(2)).intersectsBounds(crate)
						&& !new Sphere(2, 3, 0,
							1.41).intersectsBounds(crate)
								&& new Sphere(1.5, 0, 0, .5).intersectsBounds(crate)
									&& !new Sphere(1.5, 0, 0, .49).intersectsBounds(crate),
			"a box: inside, touching a corner and a face, and just apart");
		check(!reach.intersectsBounds(new Aabb3D())
			&& !new Sphere(0, 0, 0, -1).intersectsBounds(crate), "an empty box, and an empty sphere: never");

		// The nearest point.
		check(at(reach.getClosestPoint(7, 0, 0), 3, 0, 0) && at(reach.getClosestPoint(1, 3, 4), 1, 1.2, 1.6),
			"the nearest point to one outside: on the surface");
		check(at(reach.getClosestPoint(1.5, .5, -1), 1.5, .5, -1)
			&& at(reach.getClosestPoint(1, 0, 0), 1, 0, 0), "to a point inside: the point");
		check(at(new Sphere(4, 5, 6, -1).getClosestPoint(9, 9, 9), 4, 5, 6), "of an empty sphere: its center");
		var point = new Vector3();
		check(reach.getClosestPoint(1, -9, 0, point) == point && at(point, 1, -2, 0), "the nearest point, into the vector provided");

		// Grown to hold a point.
		var grown = new Sphere(0, 0, 0, 1);
		check(grown.expand(.5, .5, 0) == grown && is(grown, 0, 0, 0, 1), "a point inside: unchanged");
		check(grown.expand(3, 0, 0) == grown && is(grown, 1, 0, 0, 2) && grown.contains(-1, 0, 0) && grown.contains(3, 0, 0),
			"a point outside: the far side stays, the near side reaches the point");
		check(is(grown.expand(1, 0, -4), 1, 0, -1, 3), "and again, along another axis");
		check(is(new Sphere().makeEmpty().expand(4, 5, 6), 4, 5, 6, 0), "an empty sphere becomes the point");
		var around = new Sphere().makeEmpty();
		for (index in 0...3)
			around.expand(points[index * 3], points[index * 3 + 1], points[index * 3 + 2]);
		holds = true;
		for (index in 0...3) {
			var dx = points[index * 3] - around.center.x,
				dy = points[index * 3 + 1] - around.center.y,
				dz = points[index * 3 + 2] - around.center.z;
			holds = holds && Math.sqrt(dx * dx + dy * dy + dz * dz) <= around.radius + 1e-12;
		}
		check(holds, "grown from empty over points: holds each of them");

		// The union.
		var left = new Sphere(0, 0, 0, 1), right = new Sphere(4, 0, 0, 1);
		var joined = left.union(right);
		check(is(joined, 2, 0, 0, 3) && joined != left && is(left, 0, 0, 0, 1) && is(right, 4, 0, 0, 1), "two apart: around both, into a new sphere");
		check(is(new Sphere(0, 0, 0, 1).union(new Sphere(0, 3, 0, 2)), 0, 2, 0, 3), "two overlapping, of different sizes");
		check(is(new Sphere(0, 0, 0, 5).union(new Sphere(1, 1, 0, 1)), 0, 0, 0, 5)
			&& is(new Sphere(1, 1, 0, 1).union(new Sphere(0, 0, 0, 5)), 0, 0, 0, 5),
			"one in the other: the larger");
		check(is(new Sphere(2, 2, 2, 1).union(new Sphere(2, 2, 2, 3)), 2, 2, 2, 3), "two with one center");
		check(is(left.union(new Sphere(9, 9, 9, -1)), 0, 0, 0, 1)
			&& is(new Sphere(9, 9, 9, -1).union(right), 4, 0, 0, 1), "an empty one adds nothing");
		check(new Sphere(0, 0, 0, -1).union(new Sphere(5, 5, 5, -1)).isEmpty, "two empty ones: empty");
		var a = new Sphere(0, 0, 0, 1), b = new Sphere(4, 0, 0, 1);
		check(a.union(b, a) == a && is(a, 2, 0, 0, 3) && is(b, 4, 0, 0, 1), "into the sphere itself");
		a.set(0, 0, 0, 1);
		check(a.union(b, b) == b && is(b, 2, 0, 0, 3) && is(a, 0, 0, 0, 1), "into the other sphere");

		// Moved by a matrix.
		check(is(reach.transform(Matrix4.fromTranslation(1, 2, 3)), 2, 2, 3, 2), "moved");
		check(is(reach.transform(Matrix4.fromScale(2, 3, 1)), 2, 0, 0, 6), "scaled by each axis's own amount: the radius by the largest");
		check(is(reach.transform(Matrix4.fromScale(-2, 1, 1)), -2, 0, 0, 4), "mirrored and scaled");
		check(is(reach.transform(Matrix4.fromRotation(0, 0, 1, Math.PI / 2).appendTranslation(0, 0, 5)), 0, 1, 5, 2, 1e-12), "turned, then moved");
		check(new Sphere(1, 1, 1, -1).transform(Matrix4.fromScale(2, 2, 2)).isEmpty, "an empty sphere stays empty");
		var moving = new Sphere(1, 0, 0, 2);
		check(moving.transform(Matrix4.fromScale(3, 3, 3), moving) == moving && is(moving, 3, 0, 0, 6), "into the sphere itself");
		check(reach.transform(Matrix4.fromTranslation(1, 0, 0), into) == into
			&& is(into, 2, 0, 0, 2)
			&& is(reach, 1, 0, 0, 2), "into the sphere provided");

		// The box around.
		var bounds = reach.getBounds();
		check(bounds.minX == -1 && bounds.maxX == 3 && bounds.minY == -2 && bounds.maxY == 2 && bounds.minZ == -2 && bounds.maxZ == 2, "the box around");
		var box = new Aabb3D().set(0, 0, 0, 1, 1, 1);
		check(new Sphere(0, 0, 0, -1).getBounds(box) == box && box.isEmpty, "of an empty sphere: an empty box, into the box provided");
		check(is(Sphere.fromBounds(new Sphere(3, 4, 5, 0).getBounds()), 3, 4, 5, 0), "of a sphere of radius 0: its center");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
