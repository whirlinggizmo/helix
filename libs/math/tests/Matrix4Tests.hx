import helix.math.Matrix4;
import helix.math.Quaternion;
import helix.math.Vector3;

/** Checks Matrix4 with the library alone: made as each kind of transform (into a new matrix or one given), combined in order (compose, append, prepend), each operation into a
	new matrix, itself or its other argument alike, inverted (a singular one refused, unchanged) and transposed, added and subtracted, its trace and determinant, points and directions carried through it, a point through a
	projection, and a transform taken apart, whole and a part at a time. */
class Matrix4Tests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function at(p:Vector3, x:Float, y:Float, z:Float):Bool
		return near(p.x, x) && near(p.y, y) && near(p.z, z);

	static function same(a:Matrix4, b:Matrix4):Bool {
		var x = a.toArray(), y = b.toArray();
		for (i in 0...16)
			if (!near(x[i], y[i]))
				return false;
		return true;
	}

	static function identical(a:Matrix4, b:Matrix4):Bool {
		var x = a.toArray(), y = b.toArray();
		for (i in 0...16)
			if (x[i] != y[i])
				return false;
		return true;
	}

	// Runs an operation of a and b into a new matrix, into a and into b: the same result each way, its inputs untouched without an out.
	static function threeWays(a:Matrix4, b:Matrix4, op:(Matrix4, Matrix4, Null<Matrix4>) -> Matrix4, message:String):Void {
		var x = new Matrix4().copyFrom(a), y = new Matrix4().copyFrom(b);
		var result = op(x, y, null);
		check(result != x && result != y && same(x, a) && same(y, b), '$message: into a new matrix, its inputs unchanged');
		var source = new Matrix4().copyFrom(a);
		check(op(source, new Matrix4().copyFrom(b), source) == source && identical(source, result), '$message: into the matrix itself');
		var other = new Matrix4().copyFrom(b);
		check(op(new Matrix4().copyFrom(a), other, other) == other && identical(other, result), '$message: into the other argument');
	}

	static function main():Void {
		var m = new Matrix4(), p = new Vector3();
		check(same(m, new Matrix4().makeIdentity()) && m.m0 == 1 && m.m5 == 1 && m.m15 == 1 && m.m1 == 0, "made as the identity");
		check(at(m.transformPoint(1, 2, 3, p), 1, 2, 3)
			&& m.transformPoint(1, 2, 3, p) == p, "the identity leaves a point, into the one given");
		check(at(Matrix4.fromTranslation(1, 2, 3, m).transformPoint(0, 0, 0), 1, 2, 3) && m.m12 == 1 && m.m14 == 3,
			"a translation moves a point; it sits at 12 to 14");
		check(at(m.transformDirection(1, 0, 0, p), 1, 0, 0), "a direction isn't moved");
		check(at(Matrix4.fromScale(2, 3, 4, m).transformPoint(1, 1, 1, p), 2, 3, 4), "a scale");
		check(at(Matrix4.fromRotation(0, 1, 0, Math.PI / 2, m).transformPoint(1, 0, 0, p), 0, 0, -1), "a quarter turn about y takes x to -z");
		check(at(Matrix4.fromRotation(0, 0, 2, Math.PI / 2, m).transformPoint(1, 0, 0, p), 0, 1, 0), "an axis of any length: about z, x to y");
		var s = Math.sqrt(.5);
		check(same(Matrix4.fromQuaternion(0, 0, s, s, m), Matrix4.fromRotation(0, 0, 1, Math.PI / 2)), "a quaternion's rotation");
		check(same(Matrix4.fromQuaternion(0, 0, 0, 1, m), new Matrix4()), "the identity quaternion");
		var turns = Quaternion.fromEuler(.4, -1.1, 2.3);
		check(same(Matrix4.fromEuler(.4, -1.1, 2.3), Matrix4.fromQuaternion(turns.x, turns.y, turns.z, turns.w)), "three turns, as the quaternion's");
		check(at(Matrix4.fromEuler(Math.PI / 2, 0, Math.PI / 2).transformPoint(0, 1, 0, p), 0, 0, 1), "about x first: y to z, which z leaves");
		check(Matrix4.fromEuler(.4, -1.1, 2.3, m) == m && same(m, Matrix4.fromEuler(.4, -1.1, 2.3)), "three turns into the one given");

		Matrix4.fromScale(2, 2, 2, m).appendRotation(0, 1, 0, Math.PI / 2, m).appendTranslation(1, 0, -3, m);
		check(at(m.transformPoint(1, 0, 0, p), 1, 0, -5), "appended in order: scaled, then turned, then moved");
		var parts = Matrix4.compose(Matrix4.fromScale(2, 2, 2), Matrix4.fromRotation(0, 1, 0, Math.PI / 2)).append(Matrix4.fromTranslation(1, 0, -3));
		check(same(m, parts), "appending a translation, scale or rotation is appending that matrix");
		var appendedScale = Matrix4.fromTranslation(1, 2, 3).appendScale(2, 2, 2);
		check(at(appendedScale.transformPoint(0, 0, 0, p), 2, 4, 6), "a scale appended scales the translation too");
		var before = Matrix4.fromTranslation(1, 0, 0).prepend(Matrix4.fromScale(2, 2, 2));
		check(at(before.transformPoint(1, 0, 0, p), 3, 0, 0), "prepended: the scale first, then the translation");
		var twice = Matrix4.fromTranslation(1, 0, 0);
		check(Matrix4.compose(twice, twice, twice) == twice
			&& at(twice.transformPoint(0, 0, 0, p), 2, 0, 0), "compose with itself on both sides, into itself");
		var into = new Matrix4();
		check(Matrix4.fromScale(1, 2, 3, into) == into && into.m5 == 2, "a builder fills the matrix given and returns it");

		var inverse = m.invert();
		check(inverse != null
			&& inverse != m
			&& same(Matrix4.compose(m, inverse), new Matrix4()), "inverted: followed by its inverse, the identity");
		var flat = Matrix4.fromScale(1, 0, 1),
			kept = new Matrix4().copyFrom(flat),
			unchanged = Matrix4.fromTranslation(1, 2, 3),
			previous = new Matrix4().copyFrom(unchanged);
		check(flat.invert() == null && flat.invert(unchanged) == null && same(flat, kept) && same(unchanged, previous),
			"a matrix with no inverse refused: null, it and the out left as they were");
		var t = m.transpose();
		check(t != m && t.m1 == m.m4 && t.m12 == m.m3 && same(t.transpose(), m), "transposed, and back");

		// Each operation into a new matrix (its inputs unchanged), into this one and into the other argument: the same each way.
		var a = Matrix4.fromScale(2, 3, 4).appendRotation(1, 1, 0, .7).appendTranslation(5, -6, 7),
			b = Matrix4.fromPerspective(1, 1.5, .5, 50).appendRotation(0, 0, 1, -.3);
		threeWays(a, b, (x, y, out) -> x.append(y, out), "append");
		threeWays(a, b, (x, y, out) -> x.prepend(y, out), "prepend");
		threeWays(a, b, (x, y, out) -> Matrix4.compose(x, y, out), "compose");
		threeWays(a, b, (x, y, out) -> x.appendTranslation(1, 2, 3, out), "appendTranslation");
		threeWays(a, b, (x, y, out) -> x.appendScale(1, 2, 3, out), "appendScale");
		threeWays(a, b, (x, y, out) -> x.appendRotation(1, 2, 3, .5, out), "appendRotation");
		threeWays(a, b, (x, y, out) -> x.transpose(out), "transpose");
		threeWays(a, b, (x, y, out) -> x.invert(out), "invert");
		check(same(a.append(b), Matrix4.compose(a, b))
			&& same(a.prepend(b), Matrix4.compose(b, a)), "append and prepend compose in order");

		check(at(Matrix4.fromLookAt(0, 0, 5, 0, 0, 0, 0, 1, 0, m).transformPoint(0, 0, 0, p), 0, 0, -5), "a view: the target ahead, down -z");
		check(at(Matrix4.fromLookAt(3, 0, 0, 0, 0, 0, 0, 1, 0, m).transformPoint(0, 0, 0, p), 0, 0, -3), "from the side, the same");
		var fov = Math.PI / 3, aspect = 16 / 9;
		Matrix4.fromPerspective(fov, aspect, .1, 100, m);
		check(near(m.m5, 1 / Math.tan(fov / 2)) && near(m.m0, m.m5 / aspect) && m.m11 == -1 && m.m15 == 0, "a perspective: its focal lengths, w from -z");
		check(near((m.m10 * -.1 + m.m14) / .1, -1) && near((m.m10 * -100 + m.m14) / 100, 1), "the near plane to depth -1, the far to 1");
		Matrix4.fromOrthographic(-2, 2, -1, 1, 0, 10, m);
		check(at(m.transformPoint(-2, -1, 0, p), -1, -1, -1)
			&& at(m.transformPoint(2, 1, -10, p), 1, 1, 1), "an orthographic: its box to clip space");
		var frustum = Matrix4.fromFrustum(-.1 * Math.tan(fov / 2) * aspect, .1 * Math.tan(fov / 2) * aspect, -.1 * Math.tan(fov / 2), .1 * Math.tan(fov / 2),
			.1, 100);
		check(same(frustum, Matrix4.fromPerspective(fov, aspect, .1, 100, m)), "a centered frustum: the perspective of its field of view");
		Matrix4.fromFrustum(0, 2, 0, 1, 1, 10, m);
		var corner = Matrix4.fromFrustum(0, 2, 0, 1, 1, 10).transformPoint(2, 1, -1, p);
		check(near(m.m8, 1) && near(m.m9, 1) && near(corner.x / 1, 1) && near(corner.y / 1, 1),
			"an off-center frustum: its near plane's corner to clip space's (w 1 at the near plane)");
		var counted = Matrix4.fromArray([for (i in 0...16) i + 1.]),
			doubled = Matrix4.fromArray([for (i in 0...16) 2. * (i + 1)]);
		threeWays(counted, counted, (a, b, out) -> a.add(b, out), "add");
		threeWays(doubled, counted, (a, b, out) -> a.subtract(b, out), "subtract");
		check(identical(counted.add(counted), doubled)
			&& identical(doubled.subtract(counted), counted), "add and subtract: number by number");
		check(counted.trace == 1 + 6 + 11 + 16 && new Matrix4().trace == 4, "the trace: the diagonal's sum");
		check(new Matrix4().determinant == 1 && counted.determinant == 0, "the determinant: 1 for the identity, 0 for a matrix without an inverse");
		check(near(Matrix4.fromScale(2, 3, 4).determinant, 24) && near(Matrix4.fromScale(-2, 3, 4).determinant, -24),
			"a scale's determinant: its volume, less than 0 mirrored");
		var placed = Matrix4.compose(Matrix4.compose(Matrix4.fromScale(2, 3, 4), Matrix4.fromQuaternion(0, Math.sqrt(.5), 0, Math.sqrt(.5))),
			Matrix4.fromTranslation(1, 2, 3));
		check(near(placed.determinant, 24) && near(placed.determinant * placed.invert().determinant, 1),
			"a transform's determinant: its scale's, and its inverse's is 1 over it");
		Matrix4.fromPerspective(fov, aspect, .1, 100, m);
		check(at(m.projectPoint(0, 0, -.1, p), 0, 0, -1) && at(m.projectPoint(0, 0, -100, p), 0, 0, 1),
			"a point through a perspective: the near plane at depth -1, the far at 1");
		var edge = Math.tan(fov / 2) * 10;
		check(at(m.projectPoint(edge * aspect, edge, -10), 1, 1, m.projectPoint(0, 0, -10).z), "the view's corner at 1, 1");
		check(at(Matrix4.fromTranslation(1, 2, 3).projectPoint(1, 1, 1), 2, 3, 4), "a matrix that keeps w at 1: the point transformed");
		var translation = new Vector3(),
			rotation = new helix.math.Quaternion(),
			scale = new Vector3();
		placed.decompose(translation, rotation, scale);
		check(at(translation, 1, 2, 3) && at(scale, 2, 3, 4) && near(rotation.y, Math.sqrt(.5)) && near(rotation.w, Math.sqrt(.5)) && near(rotation.x, 0)
			&& near(rotation.z, 0),
			"decompose: the translation, rotation and scale a transform was made of");
		var part = new Vector3(), turn = new helix.math.Quaternion();
		check(placed.getTranslation(part) == part
			&& at(part, translation.x, translation.y, translation.z)
			&& at(placed.getTranslation(), 1, 2, 3),
			"getTranslation: decompose's translation, into the one given or a new one");
		check(placed.getRotation(turn) == turn
			&& turn.x == rotation.x
			&& turn.y == rotation.y
			&& turn.z == rotation.z
			&& turn.w == rotation.w
			&& near(Math.abs(placed.getRotation().y), Math.sqrt(.5)),
			"getRotation: decompose's rotation, into the one given or a new one");
		check(placed.getScale(part) == part && at(part, scale.x, scale.y, scale.z) && at(placed.getScale(), 2, 3, 4),
			"getScale: decompose's scale, into the one given or a new one");
		Matrix4.fromScale(-2, 3, 4).decompose(translation, rotation, scale);
		check(at(scale, -2, 3, 4) && near(Math.abs(rotation.w), 1), "a mirror: an x scale less than 0, the rotation none");
		check(at(Matrix4.fromScale(-2, 3, 4).getScale(), -2, 3, 4) && near(Math.abs(Matrix4.fromScale(-2, 3, 4).getRotation().w), 1),
			"a mirror's parts: the same");
		var sheared = new Matrix4();
		sheared.m4 = 1;
		check(at(sheared.getScale(), 1, Math.sqrt(2), 1), "a shear's scale: the lengths of its axes");
		check(at(new Matrix4().getScale(), 1, 1, 1)
			&& at(Matrix4.fromScale(0, 0, 0).getScale(), 0, 0, 0)
			&& near(Matrix4.fromScale(0, 0, 0).getRotation().w, 1),
			"the identity's scale 1, a matrix of no size's 0 and its rotation none");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
