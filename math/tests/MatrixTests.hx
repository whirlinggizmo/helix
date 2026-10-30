import helix.math.Matrix3D;
import helix.math.Point3D;

/** Checks Matrix3D with the library alone: made as each kind of transform, combined in order (compose, append, prepend, either matrix
	this one), inverted (a singular one refused, unchanged) and transposed, and points and directions carried through it. */
class MatrixTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function at(p:Point3D, x:Float, y:Float, z:Float):Bool
		return near(p.x, x) && near(p.y, y) && near(p.z, z);

	static function same(a:Matrix3D, b:Matrix3D):Bool {
		for (i in 0...16)
			if (!near(a.values[i], b.values[i]))
				return false;
		return true;
	}

	static function main():Void {
		var m = new Matrix3D(), p = new Point3D();
		check(same(m, new Matrix3D().makeIdentity())
			&& m.values[0] == 1
			&& m.values[5] == 1
			&& m.values[15] == 1
			&& m.values[1] == 0, "made as the identity");
		check(at(m.transformPoint(1, 2, 3, p), 1, 2, 3)
			&& m.transformPoint(1, 2, 3, p) == p, "the identity leaves a point, into the one given");
		check(at(m.makeTranslation(1, 2, 3).transformPoint(0, 0, 0), 1, 2, 3) && m.values[12] == 1 && m.values[14] == 3,
			"a translation moves a point; it sits at 12 to 14");
		check(at(m.transformDirection(1, 0, 0, p), 1, 0, 0), "a direction isn't moved");
		check(at(m.makeScale(2, 3, 4).transformPoint(1, 1, 1, p), 2, 3, 4), "a scale");
		check(at(m.makeRotation(0, 1, 0, Math.PI / 2).transformPoint(1, 0, 0, p), 0, 0, -1), "a quarter turn about y takes x to -z");
		check(at(m.makeRotation(0, 0, 2, Math.PI / 2).transformPoint(1, 0, 0, p), 0, 1, 0), "an axis of any length: about z, x to y");
		var s = Math.sqrt(.5);
		check(same(m.makeQuaternionRotation(0, 0, s, s), new Matrix3D().makeRotation(0, 0, 1, Math.PI / 2)), "a quaternion's rotation");
		check(same(m.makeQuaternionRotation(0, 0, 0, 1), new Matrix3D()), "the identity quaternion");

		m.makeScale(2, 2, 2).appendRotation(0, 1, 0, Math.PI / 2).appendTranslation(1, 0, -3);
		check(at(m.transformPoint(1, 0, 0, p), 1, 0, -5), "appended in order: scaled, then turned, then moved");
		var parts = new Matrix3D().compose(new Matrix3D().makeScale(2, 2, 2), new Matrix3D().makeRotation(0, 1, 0, Math.PI / 2))
			.append(new Matrix3D().makeTranslation(1, 0, -3));
		check(same(m, parts), "appending a translation, scale or rotation is appending that matrix");
		var appendedScale = new Matrix3D().makeTranslation(1, 2, 3).appendScale(2, 2, 2);
		check(at(appendedScale.transformPoint(0, 0, 0, p), 2, 4, 6), "a scale appended scales the translation too");
		var before = new Matrix3D().makeTranslation(1, 0, 0).prepend(new Matrix3D().makeScale(2, 2, 2));
		check(at(before.transformPoint(1, 0, 0, p), 3, 0, 0), "prepended: the scale first, then the translation");
		var twice = new Matrix3D().makeTranslation(1, 0, 0);
		check(at(twice.compose(twice, twice).transformPoint(0, 0, 0, p), 2, 0, 0), "compose with itself on both sides");

		var inverse = new Matrix3D().copyFrom(m);
		check(inverse.invert()
			&& same(new Matrix3D().compose(m, inverse), new Matrix3D()), "inverted: followed by its inverse, the identity");
		var flat = new Matrix3D().makeScale(1, 0, 1),
			kept = new Matrix3D().copyFrom(flat);
		check(!flat.invert() && same(flat, kept), "a matrix with no inverse refused, left as it was");
		var t = new Matrix3D().copyFrom(m).transpose();
		check(t.values[1] == m.values[4] && t.values[12] == m.values[3] && same(t.transpose(), m), "transposed, and back");

		check(at(m.makeLookAt(0, 0, 5, 0, 0, 0, 0, 1, 0).transformPoint(0, 0, 0, p), 0, 0, -5), "a view: the target ahead, down -z");
		check(at(m.makeLookAt(3, 0, 0, 0, 0, 0, 0, 1, 0).transformPoint(0, 0, 0, p), 0, 0, -3), "from the side, the same");
		var fov = Math.PI / 3, aspect = 16 / 9;
		m.makePerspective(fov, aspect, .1, 100);
		check(near(m.values[5], 1 / Math.tan(fov / 2))
			&& near(m.values[0], m.values[5] / aspect)
			&& m.values[11] == -1
			&& m.values[15] == 0,
			"a perspective: its focal lengths, w from -z");
		check(near((m.values[10] * -.1 + m.values[14]) / .1, -1) && near((m.values[10] * -100 + m.values[14]) / 100, 1),
			"the near plane to depth -1, the far to 1");
		m.makeOrthographic(-2, 2, -1, 1, 0, 10);
		check(at(m.transformPoint(-2, -1, 0, p), -1, -1, -1)
			&& at(m.transformPoint(2, 1, -10, p), 1, 1, 1), "an orthographic: its box to clip space");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
