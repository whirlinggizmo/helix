import helix.math.Bounds2D;
import helix.geometry.Camera2D;
import helix.math.Matrix2D;
import helix.math.Vector2D;

/** Checks Camera2D with the library alone: made and copied; its view matrix, conversions and bounds pinned to values computed apart
	from Haxe, the matrix also to raylib 5.5's own 4 x 4 path for the same camera; each result into a new value or one given, alike, even
	when the one given is its own offset or position; worldToView and viewToWorld undoing each other over turned, zoomed and mirrored
	cameras; the bounds of a turned, zoomed view holding exactly its corners; and zoom 0, where a point in the view has no place. */
class Camera2DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-9):Bool
		return Math.abs(a - b) < tolerance;

	static function at(p:Vector2D, x:Float, y:Float, tolerance = 1e-9):Bool
		return near(p.x, x, tolerance) && near(p.y, y, tolerance);

	static function is(m:Matrix2D, values:Array<Float>):Bool
		return near(m.a, values[0]) && near(m.b, values[1]) && near(m.c, values[2]) && near(m.d, values[3]) && near(m.tx, values[4]) && near(m.ty, values[5]);

	// At (120.5, -33.25), turned -0.4, zoom 2.5, its position at (400, 225): raylib's Camera2D with that target and offset, a rotation
	// of 0.4 radians in degrees, and that zoom.
	static function sample():Camera2D {
		var camera = new Camera2D();
		camera.transform.position.set(120.5, -33.25);
		camera.transform.rotation = -.4;
		camera.zoom = 2.5;
		camera.offset.set(400, 225);
		return camera;
	}

	// Runs a conversion into a new vector, into one given, into the camera's own offset and its own position: the same each way.
	static function fourWays(op:(Camera2D, Null<Vector2D>) -> Vector2D, message:String):Vector2D {
		var camera = sample();
		var result = op(camera, null), given = new Vector2D();
		check(result != camera.offset && result != camera.transform.position && camera.offset.x == 400 && camera.transform.position.x == 120.5,
			'$message: into a new vector, the camera unchanged');
		check(op(sample(), given) == given && given.equals(result), '$message: into the one given');
		var own = sample();
		check(op(own, own.offset) == own.offset && own.offset.equals(result), '$message: into its own offset');
		own = sample();
		check(op(own, own.transform.position) == own.transform.position
			&& own.transform.position.equals(result), '$message: into its own position');
		return result;
	}

	static function main():Void {
		var camera = new Camera2D();
		check(camera.zoom == 1 && camera.offset.x == 0 && camera.offset.y == 0 && camera.transform.rotation == 0, "made at zoom 1, its offset the top left");
		check(is(camera.computeViewMatrix(), [1, 0, 0, 1, 0, 0]), "made: the view is the world");
		var s = sample();
		check(camera.copyFrom(s) == camera
			&& camera.zoom == 2.5
			&& camera.offset.equals(s.offset)
			&& camera.offset != s.offset
			&& camera.transform.position.equals(s.transform.position)
			&& camera.transform.rotation == -.4,
			"copied, returning itself");

		// Pinned: plain 3 x 3 algebra in Python, and raylib 5.5's GetCameraMatrix2D as 4 x 4 matrices (both the same to the last digit).
		var view = [
			2.3026524850072128,
			0.9735458557716263,
			-0.9735458557716263,
			2.3026524850072128,
			90.1599758522243,
			184.25091950600887
		];
		check(is(sample().computeViewMatrix(), view), "the view matrix: pinned, and raylib's");
		var m = new Matrix2D();
		check(sample().computeViewMatrix(m) == m && is(m, view), "the view matrix, into the one given");
		check(at(sample().worldToView(120.5, -33.25), 400, 225), "its position shows at its offset");
		check(at(fourWays((c, out) -> c.worldToView(100, 50, out), "worldToView"), 271.74793156436425, 396.73812933353213), "worldToView: pinned");
		check(at(fourWays((c, out) -> c.viewToWorld(13, 517, out), "viewToWorld"), 23.40382051000376, 134.61188348891605), "viewToWorld: pinned");
		check(sample().worldToView(100, 50).equals(sample().computeViewMatrix().transformPoint(100, 50)), "worldToView is the view matrix's");

		// There and back, over turned, zoomed and mirrored cameras and points far apart.
		var c = new Camera2D(), p = new Vector2D();
		for (rotation in [0., .3, -1.7, Math.PI, 5.5])
			for (zoom in [1., 2.5, .125, -3.])
				for (point in [[0., 0.], [123.25, -987.5], [-1e5, 3e4]]) {
					c.transform.position.set(-40, 75.5);
					c.transform.rotation = rotation;
					c.zoom = zoom;
					c.offset.set(640, 360);
					var shown = c.worldToView(point[0], point[1], p),
						back = c.viewToWorld(shown.x, shown.y);
					check(at(back, point[0], point[1], 1e-6), 'world to view and back (rotation $rotation, zoom $zoom)');
					var world = c.viewToWorld(point[0], point[1]),
						again = c.worldToView(world.x, world.y);
					check(at(again, point[0], point[1], 1e-6), 'view to world and back (rotation $rotation, zoom $zoom)');
				}
		c.zoom = 2;
		c.transform.rotation = 0;
		check(near(c.viewToWorld(642, 360).x - c.viewToWorld(640, 360).x, 1), "zoom 2: two view units a world unit");
		c.transform.rotation = Math.PI / 2;
		var right = c.viewToWorld(641, 360);
		check(at(right, -40, 75.5 + .5), "turned a quarter toward +y: the view's +x is the way it faces, the world's +y");

		// The bounds of a turned, zoomed view: pinned, and exactly the box of its corners.
		var bounds = sample().computeBounds(800, 450);
		check(near(bounds.minX, -61.91740984824016)
			&& near(bounds.minY, -178.45242422964373)
			&& near(bounds.maxX, 302.91740984824014)
			&& near(bounds.maxY, 111.9524242296437),
			"the bounds of a turned, zoomed view: pinned");
		var corners = new Bounds2D();
		for (corner in [[0., 0.], [800., 0.], [0., 450.], [800., 450.]]) {
			var world = sample().viewToWorld(corner[0], corner[1]);
			check(bounds.contains(world.x, world.y), "holds each corner of the view");
			corners.expand(world.x, world.y);
		}
		check(near(corners.minX, bounds.minX) && near(corners.maxX, bounds.maxX) && near(corners.minY, bounds.minY) && near(corners.maxY, bounds.maxY),
			"and no more than its corners");
		var given = new Bounds2D();
		check(sample().computeBounds(800, 450, given) == given
			&& given.minX == bounds.minX
			&& given.maxY == bounds.maxY, "the bounds, into the box given");
		var plain = new Camera2D();
		plain.transform.position.set(10, 20);
		plain.zoom = 2;
		plain.offset.set(200, 100);
		var box = plain.computeBounds(400, 200);
		check(box.minX == -90 && box.minY == -30 && box.maxX == 110 && box.maxY == 70, "unturned: the view's size over the zoom, around its position");

		// At zoom 0 nothing shows: no place in the world for a point in the view.
		var flat = sample(), kept = new Vector2D(7, 8);
		flat.zoom = 0;
		check(flat.viewToWorld(1, 2) == null && flat.viewToWorld(1, 2, kept) == null && kept.x == 7 && kept.y == 8,
			"zoom 0: viewToWorld null, the out unchanged");
		check(flat.computeBounds(800, 450, given) == given && given.isEmpty, "zoom 0: the bounds empty");
		check(at(flat.worldToView(-500, 900), 400, 225), "zoom 0: every point at the offset");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
