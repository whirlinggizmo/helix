import helix.geometry.Mesh3D;
import helix.geometry.Ray3D;
import helix.geometry.RayHit3D;
import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.math.Vector3D;

/** Checks Ray3D with the library alone, against hits worked by hand: a plane from either side, along it and behind; a sphere from
	outside, from inside, behind and missed; bounds through each face, from inside, along a face and empty; a triangle from both sides,
	on its edge, off it and of no area; a mesh's nearest triangle, moved, and which; distances in the direction's lengths; a ray moved by
	a transform; and every hit into the one given, a miss leaving it as it was. */
class Ray3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) <= tolerance;

	static function at(v:Vector3D, x:Float, y:Float, z:Float, tolerance = 1e-12):Bool
		return near(v.x, x, tolerance) && near(v.y, y, tolerance) && near(v.z, z, tolerance);

	// Whether a hit is at a distance, a point and a normal.
	static function is(hit:Null<RayHit3D>, distance:Float, point:Array<Float>, normal:Array<Float>, triangle = -1):Bool
		return hit != null
			&& near(hit.distance, distance)
			&& at(hit.point, point[0], point[1], point[2])
			&& at(hit.normal, normal[0], normal[1], normal[2])
			&& hit.triangleIndex == triangle;

	static function main():Void {
		var ray = new Ray3D();
		check(at(ray.origin, 0, 0, 0) && at(ray.direction, 0, 0, -1), "made at the origin, along -z");
		check(ray.set(1, 2, 3, 0, 0, 2) == ray && at(ray.computePoint(1.5), 1, 2, 6), "a point along it, in the direction's lengths");
		var other = new Ray3D().copyFrom(ray);
		check(at(other.origin, 1, 2, 3) && at(other.direction, 0, 0, 2) && other.origin != ray.origin, "copied");

		// A plane.
		var down = new Ray3D().set(0, 10, 0, 0, -2, 0);
		check(is(down.intersectPlane(0, 0, 0, 0, 1, 0), 5, [0, 0, 0], [0, 1, 0]), "the ground from above: the direction's lengths");
		check(is(new Ray3D().set(3, -4, 1, 0, 1, 0).intersectPlane(0, 0, 0, 0, 2, 0), 4, [3, 0, 1], [0, 1, 0]),
			"from below too, its normal the plane's as given, made length 1");
		check(new Ray3D().set(0, 10, 0, 1, 0, 0).intersectPlane(0, 0, 0, 0, 1, 0) == null, "along it: none");
		check(new Ray3D().set(0, 10, 0, 0, 1, 0).intersectPlane(0, 0, 0, 0, 1, 0) == null, "away from it: none");

		// A sphere.
		var toSphere = new Ray3D().set(0, 0, 10, 0, 0, -1);
		check(is(toSphere.intersectSphere(0, 0, 0, 2), 8, [0, 0, 2], [0, 0, 1]), "a sphere from outside: where it goes in");
		check(is(new Ray3D().set(0, 0, 0, 1, 0, 0).intersectSphere(0, 0, 0, 2), 2, [2, 0, 0], [1, 0, 0]),
			"from inside: where it comes out, its normal still out");
		check(new Ray3D().set(0, 0, 10, 0, 0, 1).intersectSphere(0, 0, 0, 2) == null, "behind it: none");
		check(new Ray3D().set(3, 0, 10, 0, 0, -1).intersectSphere(0, 0, 0, 2) == null, "beside it: none");
		var grazing = new Ray3D().set(2, 0, 10, 0, 0, -1).intersectSphere(0, 0, 0, 2);
		check(is(grazing, 10, [2, 0, 0], [1, 0, 0]), "touching its edge: met there");

		// Bounds.
		var box = new Bounds3D().set(-1, -2, -3, 1, 2, 3);
		check(is(new Ray3D().set(5, 0, 0, -1, 0, 0).intersectBounds(box), 4, [1, 0, 0], [1, 0, 0]), "bounds through +x");
		check(is(new Ray3D().set(0, -6, 0, 0, 2, 0).intersectBounds(box), 2, [0, -2, 0], [0, -1, 0]), "through -y");
		check(is(new Ray3D().set(.5, .5, 9, 0, 0, -1).intersectBounds(box), 6, [.5, .5, 3], [0, 0, 1]), "through +z");
		check(is(new Ray3D().set(0, 0, 0, 0, 0, -1).intersectBounds(box), 3, [0, 0, -3], [0, 0, -1]),
			"from inside: where it comes out, its normal out of that face");
		check(is(new Ray3D().set(-5, 3, 0, 2, -1, 0).intersectBounds(box), 2, [-1, 1, 0], [-1, 0, 0]), "slanting in through -x");
		check(new Ray3D().set(5, 0, 0, 1, 0, 0).intersectBounds(box) == null, "behind it: none");
		check(new Ray3D().set(5, 5, 0, -1, 0, 0).intersectBounds(box) == null, "beside it, along it: none");
		check(new Ray3D().set(0, 0, 0, 1, 0, 0).intersectBounds(new Bounds3D()) == null, "empty bounds: none");

		// A triangle, counterclockwise from +z.
		var front = new Ray3D().set(.25, .25, 5, 0, 0, -1),
			back = new Ray3D().set(.25, .25, -5, 0, 0, 1);
		check(is(front.intersectTriangle(0, 0, 0, 1, 0, 0, 0, 1, 0), 5, [.25, .25, 0], [0, 0, 1]), "a triangle from its front");
		check(is(back.intersectTriangle(0, 0, 0, 1, 0, 0, 0, 1, 0), 5, [.25, .25, 0], [0, 0, 1]), "from its back, its normal its front's");
		check(new Ray3D().set(.6, .6, 5, 0, 0, -1).intersectTriangle(0, 0, 0, 1, 0, 0, 0, 1, 0) == null, "beside it: none");
		check(new Ray3D().set(.5, .5, 5, 0, 0, -1).intersectTriangle(0, 0, 0, 1, 0, 0, 0, 1, 0) != null, "on its edge: met");
		check(new Ray3D().set(0, 0, 5, 1, 0, 0).intersectTriangle(0, 0, 0, 1, 0, 0, 0, 1, 0) == null, "along its plane: none");
		check(front.intersectTriangle(0, 0, 0, 1, 0, 0, 2, 0, 0) == null, "no area: none");
		check(new Ray3D().set(.25, .25, -5, 0, 0, -1).intersectTriangle(0, 0, 0, 1, 0, 0, 0, 1, 0) == null, "behind: none");

		// A mesh: a box 2 across, moved to x 10.
		var cube = Mesh3D.fromBox(2, 2, 2),
			placed = Matrix3D.fromTranslation(10, 0, 0);
		var along = new Ray3D().set(0, .5, .25, 1, 0, 0);
		var hit = along.intersectMesh(cube, placed);
		check(hit != null && near(hit.distance, 9) && at(hit.point, 9, .5, .25) && at(hit.normal, -1, 0, 0), "a mesh moved: its nearest face, in the world");
		var hitTriangle = hit.triangleIndex,
			p = cube.positions,
			i = cube.indices;
		var normalX = 0.;
		for (c in 0...3)
			normalX += p[i[hitTriangle * 3 + c] * 3];
		check(hitTriangle >= 0 && normalX == -3, "its triangle, counted as the indices give them: one of the -x face's");
		check(new Ray3D().set(5, .5, .25, 1, 0, 0).intersectMesh(cube) == null, "behind it: none");
		var inside = new Ray3D().set(0, .5, .25, 1, 0, 0).intersectMesh(cube);
		check(inside != null && near(inside.distance, 1) && at(inside.normal, 1, 0, 0), "from inside a closed mesh: where it comes out");
		var flat = Mesh3D.fromBox(2, 2, 2).toUnindexed();
		var unindexed = along.intersectMesh(flat, placed);
		check(unindexed != null && near(unindexed.distance, 9) && unindexed.triangleIndex == hitTriangle, "without indices, the same triangle");

		// Into the hit given; a miss leaves it.
		var given = new RayHit3D();
		check(toSphere.intersectSphere(0, 0, 0, 2, given) == given && near(given.distance, 8), "a hit into the one given");
		check(toSphere.intersectSphere(50, 0, 0, 2, given) == null
			&& near(given.distance, 8)
			&& at(given.point, 0, 0, 2), "a miss: it unchanged");
		check(along.intersectMesh(cube, placed, given) == given && given.triangleIndex == hitTriangle, "a mesh's hit into the one given");
		check(toSphere.intersectPlane(0, 0, 0, 0, 0, 1, given) == given && given.triangleIndex == -1, "another test's: no triangle");
		var copy = new RayHit3D().copyFrom(given);
		check(copy.distance == given.distance
			&& at(copy.point, given.point.x, given.point.y, given.point.z)
			&& copy.point != given.point, "copied");

		// A ray moved: into a mesh's own space with its transform's inverse.
		var inverse = placed.invert();
		var local = along.transform(inverse);
		check(at(local.origin, -10, .5, .25) && at(local.direction, 1, 0, 0) && local != along, "moved: its origin as a point, its direction not");
		var turned = new Ray3D().set(0, 0, 0, 1, 0, 0);
		check(turned.transform(Matrix3D.fromRotation(0, 1, 0, Math.PI / 2), turned) == turned
			&& at(turned.direction, 0, 0, -1, 1e-15), "turned in place");
		var localHit = local.intersectMesh(cube);
		check(localHit != null && near(localHit.distance, hit.distance), "in the mesh's space, the same distance");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
