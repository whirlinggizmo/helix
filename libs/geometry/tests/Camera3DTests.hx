import helix.geometry.Camera3D;
import helix.geometry.Frustum3D;
import helix.geometry.Ray3D;
import helix.math.Matrix3D;
import helix.math.Vector3D;

/** Checks Camera3D with the library alone: made and copied; its view matrix, projections, a point projected and the ray through a
	point in the view, perspective and orthographic, pinned to values computed apart from Haxe (the ray from the inverse view-projection,
	not the way the camera finds it), the view and projections also to raylib 5.5's MatrixLookAt, MatrixPerspective and MatrixOrtho;
	its scale and a rotation of another length ignored; each result into a new value or one given, alike, even when the one given is
	its own position; a point on the ray projecting back to where it was picked; and what its frustum holds. */
class Camera3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) < tolerance;

	static function at(p:Vector3D, x:Float, y:Float, z:Float, tolerance = 1e-12):Bool
		return near(p.x, x, tolerance) && near(p.y, y, tolerance) && near(p.z, z, tolerance);

	static function matrixIs(m:Matrix3D, values:Array<Float>, tolerance = 1e-12):Bool {
		for (i in 0...16)
			if (!near(m.values[i], values[i], tolerance))
				return false;
		return true;
	}

	static final aspect = 16 / 9;

	// At (2, 3, 8) looking at (0, 1, 0), a field of view of 0.9, near 0.1 and far 1000, 12 high when orthographic.
	static function sample(orthographic = false):Camera3D {
		var camera = new Camera3D();
		camera.transform.position.set(2, 3, 8);
		camera.transform.lookAt(0, 1, 0);
		camera.fieldOfView = .9;
		camera.orthographicHeight = 12;
		camera.orthographic = orthographic;
		return camera;
	}

	// Runs a result into a new vector, into one given and into the camera's own position: the same each way.
	static function threeWays(orthographic:Bool, op:(Camera3D, Null<Vector3D>) -> Vector3D, message:String):Vector3D {
		var camera = sample(orthographic);
		var result = op(camera, null), given = new Vector3D();
		check(result != camera.transform.position && at(camera.transform.position, 2, 3, 8), '$message: into a new vector, the camera unchanged');
		check(op(sample(orthographic), given) == given && given.equals(result), '$message: into the one given');
		var own = sample(orthographic);
		check(op(own, own.transform.position) == own.transform.position
			&& own.transform.position.equals(result), '$message: into its own position');
		return result;
	}

	static function main():Void {
		var camera = new Camera3D();
		check(at(camera.transform.position, 0, 0, 0)
			&& !camera.orthographic
			&& camera.fieldOfView == Math.PI / 4
			&& camera.orthographicHeight == 10
			&& camera.near == .1
			&& camera.far == 1000,
			"made at the origin, perspective, its defaults");
		check(matrixIs(camera.computeViewMatrix(), [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]), "made: looking down -z, the view is the world");
		var s = sample(true);
		s.near = 2;
		s.far = 50;
		check(camera.copyFrom(s) == camera
			&& camera.orthographic
			&& camera.fieldOfView == .9
			&& camera.orthographicHeight == 12
			&& camera.near == 2
			&& camera.far == 50
			&& camera.transform.position.equals(s.transform.position)
			&& camera.transform.position != s.transform.position,
			"copied, returning itself");

		// Pinned: MatrixLookAt's algebra in Python, and raylib 5.5's MatrixLookAt, MatrixPerspective and MatrixOrtho in floats.
		var view = [
			0.9701425001453319,
			-0.05716619504750295,
			0.23570226039551587,
			0,
			0,
			0.9718253158075502,
			0.23570226039551587,
			0,
			-0.24253562503633297,
			-0.2286647801900118,
			0.9428090415820635,
			0,
			0,
			-0.9718253158075503,
			-8.720983634634088,
			1
		];
		check(matrixIs(sample().computeViewMatrix(), view), "its view matrix: pinned");
		check(matrixIs(sample().computeViewMatrix(), [
			0.970142424,
			-0.0571661927,
			0.235702276,
			0,
			0,
			0.971825302,
			0.235702276,
			0,
			-0.242535606,
			-0.228664771,
			0.942809105,
			0,
			-0,
			-0.971825242,
			-8.72098446,
			1
		], 2e-6), "and raylib's MatrixLookAt");
		var given = new Matrix3D();
		check(sample().computeViewMatrix(given) == given && matrixIs(given, view), "its view matrix, into the one given");
		var scaled = sample();
		scaled.transform.scale.set(3, -2, .5);
		scaled.transform.rotation.set(scaled.transform.rotation.x * 4, scaled.transform.rotation.y * 4, scaled.transform.rotation.z * 4,
			scaled.transform.rotation.w * 4);
		check(matrixIs(scaled.computeViewMatrix(), view, 1e-13), "its scale, and a rotation of another length, ignored");
		var perspective = [
			1.164463515731932,
			0,
			0,
			0,
			0,
			2.0701573613012125,
			0,
			0,
			0,
			0,
			-1.0002000200020003,
			-1,
			0,
			0,
			-0.20002000200020004,
			0
		];
		check(matrixIs(sample().computeProjectionMatrix(aspect), perspective), "its perspective projection: pinned");
		check(matrixIs(sample().computeProjectionMatrix(aspect), [
			1.16446352,
			0,
			0,
			0,
			0,
			2.07015729,
			0,
			0,
			0,
			0,
			-1.00019991,
			-1,
			0,
			0,
			-0.20002,
			0
		], 1e-6), "and raylib's MatrixPerspective");
		var orthographic = [
			0.09375,
			0,
			0,
			0,
			0,
			0.16666666666666666,
			0,
			0,
			0,
			0,
			-0.002000200020002,
			0,
			0,
			0,
			-1.0002000200020003,
			1
		];
		check(matrixIs(sample(true).computeProjectionMatrix(aspect), orthographic), "its orthographic projection: pinned");
		check(matrixIs(sample(true).computeProjectionMatrix(aspect), [
			0.09375,
			0,
			0,
			0,
			0,
			0.166666672,
			0,
			0,
			0,
			0,
			-0.00200019986,
			0,
			-0,
			-0,
			-1.00019991,
			1
		], 1e-6), "and raylib's MatrixOrtho");
		check(sample().computeProjectionMatrix(aspect, given) == given
			&& matrixIs(given, perspective), "its projection, into the one given");

		// A point projected, and the ray through a point in the view, each way.
		check(at(threeWays(false, (c, out) -> c.project(1.5, -.5, -2, aspect, out), "project"), 0.21785874043428863, -0.2168102563951898, 0.9809133609400974),
			"a point projected: pinned");
		check(at(threeWays(true, (c, out) -> c.project(1.5, -.5, -2, aspect, out), "project, orthographic"), 0.18190171877724973, -0.18102628431709267,
			-0.9794561466998646),
			"orthographic: pinned");
		check(at(sample().project(0, 1, 0, aspect), 0, 0, sample().project(0, 1, 0, aspect).z) && sample().project(0, 1, 0, aspect).z < 1,
			"what it looks at lands in the middle");
		check(sample().project(4, 5, 16, aspect).z > 1, "a point behind it: deeper than 1, outside");
		check(near(sample().project(2 - .1 * 2 / Math.sqrt(72), 3 - .1 * 2 / Math.sqrt(72), 8 - .1 * 8 / Math.sqrt(72), aspect).z, -1, 1e-9)
			&& near(sample().project(2 - 1000 * 2 / Math.sqrt(72), 3 - 1000 * 2 / Math.sqrt(72), 8 - 1000 * 8 / Math.sqrt(72), aspect).z, 1, 1e-9),
			"its near plane at depth -1, its far plane at 1");
		var ray = sample().computeRay(.25, -.6, aspect), given = new Ray3D();
		check(at(ray.direction, -0.010208844252822424, -0.48667957996079414, -0.8735209018381911), "the ray's direction: pinned");
		check(at(ray.origin, 2, 3, 8), "its start, the camera's position");
		check(sample().computeRay(.25, -.6, aspect, given) == given
			&& at(given.direction, ray.direction.x, ray.direction.y, ray.direction.z)
			&& at(given.origin, 2, 3, 8),
			"the ray, into the one given");
		var flat = sample(true).computeRay(.25, -.6, aspect);
		check(at(flat.direction, -0.23570226039551584, -0.23570226039551578, -0.9428090415820634), "orthographic: the way it faces, pinned");
		check(at(flat.origin, 4.769274743185662, -0.5221413629467406, 8.082150637762197), "orthographic: its start on the near plane, pinned");
		for (orthographic in [false, true])
			for (point in [[0., 0.], [.25, -.6], [-1., 1.], [.9, .99]]) {
				var c = sample(orthographic);
				var picked = c.computeRay(point[0], point[1], aspect);
				for (distance in [.5, 10., 300.]) {
					var onRay = picked.computePoint(distance);
					var shown = c.project(onRay.x, onRay.y, onRay.z, aspect);
					check(near(shown.x, point[0], 1e-9) && near(shown.y, point[1], 1e-9), 'a point on the ray lands where it was picked (${point})');
				}
				check(near(picked.direction.length, 1), "the direction of length 1");
			}

		// What it sees.
		var frustum = sample().computeFrustum(aspect), into = new Frustum3D();
		check(frustum.contains(0, 1, 0) && !frustum.contains(4, 5, 16) && !frustum.contains(200, 1, 0),
			"its frustum holds what it looks at, not what is behind or beside");
		var vp = Matrix3D.compose(sample().computeViewMatrix(), sample().computeProjectionMatrix(aspect));
		check(sample().computeFrustum(aspect, into) == into && into.planes.join(",") == Frustum3D.fromMatrix(vp).planes.join(","),
			"its frustum, into the one given: its view-projection's");
		// 1 ahead and 5 to the right: outside the perspective view, 0.86 wide each way there, inside the orthographic one, 10.67.
		var wide = sample(true).computeFrustum(aspect), t = sample().transform;
		var aside = t.position.addScaled(t.computeForward(), 1).addScaled(t.computeRight(), 5);
		check(wide.contains(0, 1, 0) && wide.contains(aside.x, aside.y, aside.z) && !frustum.contains(aside.x, aside.y, aside.z),
			"its orthographic frustum, as wide near as far");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
