import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;

/** Checks the structs' `copy`: a copy is separate from what it copies, a struct holding others copies them too, and a copy into an
	out fills that one and makes none; `Color` as a value, copied when assigned, and written in braces; and the calls returning a vector,
	rectangle, matrix, ray, box or collision: with an out, out is filled and returned, the same answer when out is an argument, and
	without one a new value. */
class StructTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var v = new Vector3(1, 2, 3), c = v.copy();
		c.x = 9;
		check(v.x == 1 && c.x == 9 && c.y == 2 && c.z == 3, "a copy is separate");

		var camera = new Camera3D(new Vector3(0, 2, 5), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 60, 0);
		var copied = camera.copy();
		copied.position.y = 7;
		check(camera.position.y == 2 && copied.fovy == 60 && copied.up.y == 1, "a camera's vectors are copied too");

		var out = new Camera3D(), target = out.target;
		check(camera.copy(out) == out && out.target == target && out.position.z == 5 && out.fovy == 60, "a copy into out fills it and makes none");

		var m = new Matrix(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16), n = m.copy();
		check(n != m && n.m0 == 1 && n.m4 == 2 && n.m12 == 4 && n.m1 == 5 && n.m15 == 16, "a matrix's sixteen values, in raylib's order");
		var zero = new Matrix(), bracedMatrix:Matrix = {
			m0: 1,
			m5: 1,
			m10: 1,
			m12: 7
		};
		check(zero.m0 == 0 && zero.m15 == 0, "a new matrix is all 0");
		check(bracedMatrix.m0 == 1 && bracedMatrix.m12 == 7 && bracedMatrix.m4 == 0 && bracedMatrix.m15 == 0, "a matrix in braces: a number left out is 0");
		var shared:helix.math.Matrix4 = m;
		shared.m12 = 40;
		check(m.m12 == 40 && n.m12 == 4 && m.copy(zero) == zero && zero.m12 == 40, "a matrix is helix-math's, the same one: m12 is its m12");

		var red = new Color(230, 41, 55, 255), faded = red;
		faded.a = 128;
		check(red.a == 255 && faded.a == 128 && faded.r == 230, "a color is a value: assigned, then changed alone");
		var braced:Color = {r: 230, g: 41, b: 55}, clear:Color = {
			r: 1,
			g: 2,
			b: 3,
			a: 0
		};
		check(braced == red && clear.r == 1 && clear.g == 2 && clear.b == 3 && clear.a == 0, "a color in braces, its alpha 255 when left out");
		var map = new MaterialMap(null, Raylib.RED);
		map.color.a = 9;
		check(Raylib.RED.a == 255 && map.color.a == 9 && map.color.r == 230, "a field's color changed in place, the constant untouched");
		var unset = new MaterialMap().color;
		check(unset.r == 0 && unset.a == 0, "a map's color left out is transparent black, as raylib's zeroed maps");

		outs();
		collisions();

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// The value-returning calls with an out: rectangles, vectors, matrices, rays and boxes.
	static function outs():Void {
		var a = new Rectangle(0, 0, 10, 10), b = new Rectangle(5, 5, 10, 10);
		var made = GetCollisionRec(a, b), out = new Rectangle(9, 9, 9, 9);
		check(GetCollisionRec(a, b, out) == out && made != out && isRectangle(out, 5, 5, 5, 5) && isRectangle(made, 5, 5, 5, 5),
			"GetCollisionRec fills out and returns it, and makes a new rectangle without one");
		var first = new Rectangle(0, 0, 10, 10);
		check(GetCollisionRec(first, b, first) == first && isRectangle(first, 5, 5, 5, 5), "GetCollisionRec into rec1: the same overlap");
		check(GetCollisionRec(a, new Rectangle(20, 20, 5, 5), out) == out
			&& isRectangle(out, 0, 0, 0, 0), "GetCollisionRec: no overlap zeroes out");
		check(isRectangle(GetCollisionRec(a, new Rectangle(10, 0, 5, 5)), 0, 0, 0, 0), "GetCollisionRec: rectangles that only touch don't overlap");

		var start = new Vector2(0, 0), end = new Vector2(10, 20);
		var point = GetSplinePointLinear(start, end, .25);
		check(GetSplinePointLinear(start, end, .25, start) == start
			&& point != start
			&& start.x == 2.5
			&& start.y == 5
			&& point.x == 2.5
			&& point.y == 5,
			"GetSplinePointLinear into its start: the same point");
		var p1 = new Vector2(0, 0),
			c2 = new Vector2(3, 9),
			c3 = new Vector2(7, -4),
			p4 = new Vector2(10, 2);
		var curve = GetSplinePointBezierCubic(p1, c2, c3, p4, .3);
		check(GetSplinePointBezierCubic(p1, c2, c3, p4, .3, c3) == c3 && c3.x == curve.x && c3.y == curve.y,
			"GetSplinePointBezierCubic into a control point: the same point");

		var hsv = new Vector3(7, 7, 7), red = ColorToHSV(RED);
		check(ColorToHSV(new Color(128, 128, 128, 255), hsv) == hsv && hsv.x == 0 && hsv.y == 0 && hsv.z > .5 && hsv.z < .51,
			"ColorToHSV into an out holding other numbers: a gray's hue and saturation 0");
		check(ColorToHSV(RED, hsv) == hsv && hsv != red && hsv.x == red.x && hsv.y == red.y && hsv.z == red.z, "ColorToHSV: the same with an out");
		var normalized = new Vector4();
		check(ColorNormalize(new Color(255, 0, 51, 255), normalized) == normalized
			&& normalized.x == 1
			&& normalized.y == 0
			&& normalized.z == .2
			&& normalized.w == 1,
			"ColorNormalize fills out");

		var camera = new Camera3D(new Vector3(0, 2, 5), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 60, 0);
		var view = GetCameraMatrix(camera), matrix = new Matrix();
		check(GetCameraMatrix(camera, matrix) == matrix
			&& matrix != view
			&& matrix.m5 == view.m5
			&& matrix.m6 == view.m6
			&& matrix.m13 == view.m13
			&& matrix.m14 == view.m14,
			"GetCameraMatrix fills out");
		var picked = GetScreenToWorldRayEx(new Vector2(100, 50), camera, 400, 300),
			ray = new Ray(),
			origin = ray.position;
		check(GetScreenToWorldRayEx(new Vector2(100, 50), camera, 400, 300, ray) == ray
			&& ray != picked
			&& ray.position == origin
			&& isVector3(ray.position, picked.position)
			&& isVector3(ray.direction, picked.direction),
			"GetScreenToWorldRayEx fills out's vectors");
		var screen = GetWorldToScreenEx(new Vector3(1, 0, 0), camera, 400, 300),
			placed = new Vector2();
		check(GetWorldToScreenEx(new Vector3(1, 0, 0), camera, 400, 300, placed) == placed && placed.x == screen.x && placed.y == screen.y,
			"GetWorldToScreenEx fills out");

		var camera2D = new Camera2D(new Vector2(200, 150), new Vector2(10, 20), 30, 2);
		var world = GetScreenToWorld2D(new Vector2(50, 60), camera2D),
			at = new Vector2(50, 60);
		check(GetScreenToWorld2D(at, camera2D, at) == at
			&& at.x == world.x
			&& at.y == world.y, "GetScreenToWorld2D into its position: the same point");
		var back = GetWorldToScreen2D(world, camera2D);
		check(GetWorldToScreen2D(at, camera2D, at) == at
			&& at.x == back.x
			&& at.y == back.y, "GetWorldToScreen2D into its position: the same point");
		var view2D = GetCameraMatrix2D(camera2D), matrix2D = new Matrix();
		check(GetCameraMatrix2D(camera2D, matrix2D) == matrix2D
			&& matrix2D.m0 == view2D.m0
			&& matrix2D.m12 == view2D.m12, "GetCameraMatrix2D fills out");

		var mesh = new Mesh();
		mesh.vertices = [1, 2, 3, -1, 5, 0, 4, -2, 1];
		mesh.vertexCount = 3;
		mesh.triangleCount = 1;
		var bounds = GetMeshBoundingBox(mesh),
			box = new BoundingBox(),
			least = box.min;
		check(GetMeshBoundingBox(mesh, box) == box
			&& box != bounds
			&& box.min == least
			&& isVector3(box.min, new Vector3(-1, -2, 0))
			&& isVector3(box.max, new Vector3(4, 5, 3))
			&& isVector3(bounds.min, box.min),
			"GetMeshBoundingBox fills out's corners");
		check(GetMeshBoundingBox(new Mesh(), box) == box && isVector3(box.min, new Vector3()) && isVector3(box.max, new Vector3()),
			"GetMeshBoundingBox: no positions zeroes out");
		var model = new Model([mesh], [], [0]);
		model.transform = MatrixTranslate(10, 0, 0);
		var moved = GetModelBoundingBox(model);
		check(GetModelBoundingBox(model, box) == box
			&& box.min == least
			&& isVector3(box.min, new Vector3(9, -2, 0))
			&& isVector3(box.max, moved.max),
			"GetModelBoundingBox fills out, moved by the transform");
	}

	// The ray collisions with an out: its point and normal filled in place, a hit and a miss.
	static function collisions():Void {
		var ray = new Ray(new Vector3(0, 0, -5), new Vector3(0, 0, 1));
		var made = GetRayCollisionSphere(ray, new Vector3(), 1);
		var out = new RayCollision(), point = out.point, normal = out.normal;
		check(GetRayCollisionSphere(ray, new Vector3(), 1, out) == out
			&& out.point == point
			&& out.normal == normal
			&& out.hit
			&& out.distance == 4
			&& point.z == -1
			&& normal.z == -1
			&& isCollision(out, made),
			"GetRayCollisionSphere: a hit fills out's point and normal");
		var away = new Ray(new Vector3(0, 0, -5), new Vector3(0, 0, -1));
		check(GetRayCollisionSphere(away, new Vector3(), 1, out) == out && out.point == point && isCollision(out, new RayCollision()),
			"GetRayCollisionSphere: a miss zeroes out");
		var bounce = new RayCollision();
		bounce.point.set(0, 0, -5);
		check(GetRayCollisionSphere(new Ray(bounce.point, new Vector3(0, 0, 1)), new Vector3(), 1, bounce) == bounce
			&& isCollision(bounce, made),
			"GetRayCollisionSphere: a ray from out's point, the same hit");

		var box = new BoundingBox(new Vector3(-1, -1, -1), new Vector3(1, 1, 1));
		check(GetRayCollisionBox(ray, box, out) == out
			&& out.point == point
			&& out.hit
			&& out.distance == 4
			&& normal.z == -1
			&& isCollision(out, GetRayCollisionBox(ray, box)),
			"GetRayCollisionBox: a hit");
		var past = new Ray(new Vector3(5, 0, -5), new Vector3(0, 0, 1));
		check(GetRayCollisionBox(past, box, out) == out && !out.hit && isCollision(out, GetRayCollisionBox(past, box)),
			"GetRayCollisionBox: a miss sets out as it sets a new collision");
		var inside = new Ray(new Vector3(0, 0, 0), new Vector3(0, 0, 1));
		check(GetRayCollisionBox(inside, box, out) == out
			&& out.hit
			&& isCollision(out, GetRayCollisionBox(inside, box)), "GetRayCollisionBox: from inside");
		var corner = new RayCollision();
		corner.point.set(-1, -1, -1);
		check(GetRayCollisionBox(ray, new BoundingBox(corner.point, new Vector3(1, 1, 1)), corner) == corner
			&& isCollision(corner, GetRayCollisionBox(ray, box)),
			"GetRayCollisionBox: out's point the box's corner, the same hit");

		var p1 = new Vector3(-1, -1, 0),
			p2 = new Vector3(1, -1, 0),
			p3 = new Vector3(1, 1, 0),
			p4 = new Vector3(-1, 1, 0);
		var upper = new Ray(new Vector3(.5, .25, -5), new Vector3(0, 0, 1));
		var quad = GetRayCollisionQuad(upper, p1, p2, p3, p4);
		check(quad.hit && quad.distance == 5 && quad.point.x == .5, "GetRayCollisionQuad: a hit on its second triangle");
		var shared = new RayCollision();
		shared.point.set(1, 1, 0);
		check(GetRayCollisionQuad(upper, p1, p2, shared.point, p4, shared) == shared && isCollision(shared, quad),
			"GetRayCollisionQuad: out's point a corner of the second triangle, the same hit");
		check(GetRayCollisionTriangle(upper, p2, p3, p4, out) == out && out.hit && out.point == point && isCollision(out, quad),
			"GetRayCollisionTriangle: a hit");
		check(GetRayCollisionTriangle(upper, p1, p2, p4, out) == out && out.point == point && isCollision(out, new RayCollision()),
			"GetRayCollisionTriangle: a miss zeroes out");

		var mesh = new Mesh();
		mesh.vertices = [-1, -1, 0, 1, -1, 0, -1, 1, 0, 1, -1, 0, 1, 1, 0, -1, 1, 0];
		mesh.vertexCount = 6;
		mesh.triangleCount = 2;
		check(GetRayCollisionMesh(upper, mesh, MatrixIdentity(), out) == out
			&& out.point == point
			&& isCollision(out, quad), "GetRayCollisionMesh: a hit");
		check(GetRayCollisionMesh(upper, mesh, MatrixTranslate(0, 0, -1), out) == out
			&& out.distance == 4
			&& isCollision(out, GetRayCollisionMesh(upper, mesh, MatrixTranslate(0, 0, -1))),
			"GetRayCollisionMesh: moved by its transform");
		check(GetRayCollisionMesh(upper, mesh, MatrixTranslate(5, 0, 0), out) == out && isCollision(out, new RayCollision()),
			"GetRayCollisionMesh: a miss zeroes out");

		var crossing = new Vector2(7, 7);
		check(CheckCollisionLines(new Vector2(0, 0), new Vector2(10, 10), new Vector2(0, 10), new Vector2(10, 0), crossing)
			&& crossing.x == 5
			&& crossing.y == 5,
			"CheckCollisionLines sets the point where the lines cross");
		crossing.set(7, 7);
		check(!CheckCollisionLines(new Vector2(0, 0), new Vector2(10, 0), new Vector2(0, 1), new Vector2(10, 1), crossing)
			&& crossing.x == 7
			&& crossing.y == 7,
			"CheckCollisionLines leaves the point on a miss");
		check(CheckCollisionLines(new Vector2(0, 0), new Vector2(10, 10), new Vector2(0, 10), new Vector2(10, 0), null), "CheckCollisionLines without a point");
		var square = [new Vector2(0, 0), new Vector2(10, 0), new Vector2(10, 10), new Vector2(0, 10)];
		var triangle = [new Vector2(0, 0), new Vector2(10, 0), new Vector2(0, 10)];
		check(CheckCollisionPointPoly(new Vector2(8, 8), square, 4)
			&& !CheckCollisionPointPoly(new Vector2(8, 8), triangle, 3)
			&& CheckCollisionPointPoly(new Vector2(2, 2), triangle, 3),
			"CheckCollisionPointPoly: a polygon of fewer corners after one of more");
	}

	static function isRectangle(r:Rectangle, x:Float, y:Float, width:Float, height:Float):Bool {
		return r.x == x && r.y == y && r.width == width && r.height == height;
	}

	static function isVector3(a:Vector3, b:Vector3):Bool {
		return a.x == b.x && a.y == b.y && a.z == b.z;
	}

	static function isCollision(a:RayCollision, b:RayCollision):Bool {
		return a.hit == b.hit && a.distance == b.distance && isVector3(a.point, b.point) && isVector3(a.normal, b.normal);
	}
}
