import helix.math.Matrix3D;
import helix.math.Vector3D;

/** Checks Matrix3D with the library alone: made as each kind of transform (into a new matrix or one given), combined in order (compose, append, prepend), each operation into a
	new matrix, itself or its other argument alike, inverted (a singular one refused, unchanged) and transposed, and points and directions carried through it. */
class MatrixTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function at(p:Vector3D, x:Float, y:Float, z:Float):Bool
		return near(p.x, x) && near(p.y, y) && near(p.z, z);

	static function same(a:Matrix3D, b:Matrix3D):Bool {
		for (i in 0...16)
			if (!near(a.values[i], b.values[i]))
				return false;
		return true;
	}

	static function identical(a:Matrix3D, b:Matrix3D):Bool {
		for (i in 0...16)
			if (a.values[i] != b.values[i])
				return false;
		return true;
	}

	// Runs an operation of a and b into a new matrix, into a and into b: the same result each way, its inputs untouched without an out.
	static function threeWays(a:Matrix3D, b:Matrix3D, op:(Matrix3D, Matrix3D, Null<Matrix3D>) -> Matrix3D, message:String):Void {
		var x = new Matrix3D().copyFrom(a), y = new Matrix3D().copyFrom(b);
		var result = op(x, y, null);
		check(result != x && result != y && same(x, a) && same(y, b), '$message: into a new matrix, its inputs unchanged');
		var source = new Matrix3D().copyFrom(a);
		check(op(source, new Matrix3D().copyFrom(b), source) == source && identical(source, result), '$message: into the matrix itself');
		var other = new Matrix3D().copyFrom(b);
		check(op(new Matrix3D().copyFrom(a), other, other) == other && identical(other, result), '$message: into the other argument');
	}

	static function main():Void {
		var m = new Matrix3D(), p = new Vector3D();
		check(same(m, new Matrix3D().makeIdentity())
			&& m.values[0] == 1
			&& m.values[5] == 1
			&& m.values[15] == 1
			&& m.values[1] == 0, "made as the identity");
		check(at(m.transformPoint(1, 2, 3, p), 1, 2, 3)
			&& m.transformPoint(1, 2, 3, p) == p, "the identity leaves a point, into the one given");
		check(at(Matrix3D.fromTranslation(1, 2, 3, m).transformPoint(0, 0, 0), 1, 2, 3) && m.values[12] == 1 && m.values[14] == 3,
			"a translation moves a point; it sits at 12 to 14");
		check(at(m.transformDirection(1, 0, 0, p), 1, 0, 0), "a direction isn't moved");
		check(at(Matrix3D.fromScale(2, 3, 4, m).transformPoint(1, 1, 1, p), 2, 3, 4), "a scale");
		check(at(Matrix3D.fromRotation(0, 1, 0, Math.PI / 2, m).transformPoint(1, 0, 0, p), 0, 0, -1), "a quarter turn about y takes x to -z");
		check(at(Matrix3D.fromRotation(0, 0, 2, Math.PI / 2, m).transformPoint(1, 0, 0, p), 0, 1, 0), "an axis of any length: about z, x to y");
		var s = Math.sqrt(.5);
		check(same(Matrix3D.fromQuaternion(0, 0, s, s, m), Matrix3D.fromRotation(0, 0, 1, Math.PI / 2)), "a quaternion's rotation");
		check(same(Matrix3D.fromQuaternion(0, 0, 0, 1, m), new Matrix3D()), "the identity quaternion");

		Matrix3D.fromScale(2, 2, 2, m).appendRotation(0, 1, 0, Math.PI / 2, m).appendTranslation(1, 0, -3, m);
		check(at(m.transformPoint(1, 0, 0, p), 1, 0, -5), "appended in order: scaled, then turned, then moved");
		var parts = Matrix3D.compose(Matrix3D.fromScale(2, 2, 2), Matrix3D.fromRotation(0, 1, 0, Math.PI / 2)).append(Matrix3D.fromTranslation(1, 0, -3));
		check(same(m, parts), "appending a translation, scale or rotation is appending that matrix");
		var appendedScale = Matrix3D.fromTranslation(1, 2, 3).appendScale(2, 2, 2);
		check(at(appendedScale.transformPoint(0, 0, 0, p), 2, 4, 6), "a scale appended scales the translation too");
		var before = Matrix3D.fromTranslation(1, 0, 0).prepend(Matrix3D.fromScale(2, 2, 2));
		check(at(before.transformPoint(1, 0, 0, p), 3, 0, 0), "prepended: the scale first, then the translation");
		var twice = Matrix3D.fromTranslation(1, 0, 0);
		check(Matrix3D.compose(twice, twice, twice) == twice && at(twice.transformPoint(0, 0, 0, p), 2, 0, 0),
			"compose with itself on both sides, into itself");
		var into = new Matrix3D();
		check(Matrix3D.fromScale(1, 2, 3, into) == into && into.values[5] == 2, "a builder fills the matrix given and returns it");

		var inverse = m.invert();
		check(inverse != null
			&& inverse != m
			&& same(Matrix3D.compose(m, inverse), new Matrix3D()), "inverted: followed by its inverse, the identity");
		var flat = Matrix3D.fromScale(1, 0, 1),
			kept = new Matrix3D().copyFrom(flat),
			unchanged = Matrix3D.fromTranslation(1, 2, 3),
			previous = new Matrix3D().copyFrom(unchanged);
		check(flat.invert() == null && flat.invert(unchanged) == null && same(flat, kept) && same(unchanged, previous),
			"a matrix with no inverse refused: null, it and the out left as they were");
		var t = m.transpose();
		check(t != m && t.values[1] == m.values[4] && t.values[12] == m.values[3] && same(t.transpose(), m), "transposed, and back");

		// Each operation into a new matrix (its inputs unchanged), into this one and into the other argument: the same each way.
		var a = Matrix3D.fromScale(2, 3, 4).appendRotation(1, 1, 0, .7).appendTranslation(5, -6, 7),
			b = Matrix3D.fromPerspective(1, 1.5, .5, 50).appendRotation(0, 0, 1, -.3);
		threeWays(a, b, (x, y, out) -> x.append(y, out), "append");
		threeWays(a, b, (x, y, out) -> x.prepend(y, out), "prepend");
		threeWays(a, b, (x, y, out) -> Matrix3D.compose(x, y, out), "compose");
		threeWays(a, b, (x, y, out) -> x.appendTranslation(1, 2, 3, out), "appendTranslation");
		threeWays(a, b, (x, y, out) -> x.appendScale(1, 2, 3, out), "appendScale");
		threeWays(a, b, (x, y, out) -> x.appendRotation(1, 2, 3, .5, out), "appendRotation");
		threeWays(a, b, (x, y, out) -> x.transpose(out), "transpose");
		threeWays(a, b, (x, y, out) -> x.invert(out), "invert");
		check(same(a.append(b), Matrix3D.compose(a, b))
			&& same(a.prepend(b), Matrix3D.compose(b, a)), "append and prepend compose in order");

		check(at(Matrix3D.fromLookAt(0, 0, 5, 0, 0, 0, 0, 1, 0, m).transformPoint(0, 0, 0, p), 0, 0, -5), "a view: the target ahead, down -z");
		check(at(Matrix3D.fromLookAt(3, 0, 0, 0, 0, 0, 0, 1, 0, m).transformPoint(0, 0, 0, p), 0, 0, -3), "from the side, the same");
		var fov = Math.PI / 3, aspect = 16 / 9;
		Matrix3D.fromPerspective(fov, aspect, .1, 100, m);
		check(near(m.values[5], 1 / Math.tan(fov / 2))
			&& near(m.values[0], m.values[5] / aspect)
			&& m.values[11] == -1
			&& m.values[15] == 0,
			"a perspective: its focal lengths, w from -z");
		check(near((m.values[10] * -.1 + m.values[14]) / .1, -1) && near((m.values[10] * -100 + m.values[14]) / 100, 1),
			"the near plane to depth -1, the far to 1");
		Matrix3D.fromOrthographic(-2, 2, -1, 1, 0, 10, m);
		check(at(m.transformPoint(-2, -1, 0, p), -1, -1, -1)
			&& at(m.transformPoint(2, 1, -10, p), 1, 1, 1), "an orthographic: its box to clip space");
		var frustum = Matrix3D.fromFrustum(-.1 * Math.tan(fov / 2) * aspect, .1 * Math.tan(fov / 2) * aspect, -.1 * Math.tan(fov / 2), .1 * Math.tan(fov / 2),
			.1, 100);
		check(same(frustum, Matrix3D.fromPerspective(fov, aspect, .1, 100, m)), "a centered frustum: the perspective of its field of view");
		Matrix3D.fromFrustum(0, 2, 0, 1, 1, 10, m);
		var corner = Matrix3D.fromFrustum(0, 2, 0, 1, 1, 10).transformPoint(2, 1, -1, p);
		check(near(m.values[8], 1) && near(m.values[9], 1) && near(corner.x / 1, 1) && near(corner.y / 1, 1),
			"an off-center frustum: its near plane's corner to clip space's (w 1 at the near plane)");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
