import helix.math.Matrix2D;
import helix.math.Matrix3D;
import helix.math.Vector2D;

/** Checks Matrix2D with the library alone: made as each kind of transform, combined in order, inverted (one that flattens refused,
	unchanged), points and directions carried through it, and its 4 x 4 form; every operation into a new matrix, itself and its other
	argument, the same each way; values pinned to plain 3 x 3 algebra computed apart from Haxe; and whole numbers multiplied as floats on
	the interpreter. */
class Matrix2DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function is(m:Matrix2D, values:Array<Float>):Bool
		return near(m.a, values[0]) && near(m.b, values[1]) && near(m.c, values[2]) && near(m.d, values[3]) && near(m.tx, values[4]) && near(m.ty, values[5]);

	static function at(p:Vector2D, x:Float, y:Float):Bool
		return near(p.x, x) && near(p.y, y);

	static function identical(m:Matrix2D, n:Matrix2D):Bool
		return m.a == n.a && m.b == n.b && m.c == n.c && m.d == n.d && m.tx == n.tx && m.ty == n.ty;

	static function copy(m:Matrix2D):Matrix2D
		return new Matrix2D().copyFrom(m);

	// Runs an operation of a and b into a new matrix, into a and into b: the same result each way, its inputs untouched without an out.
	static function threeWays(a:Matrix2D, b:Matrix2D, op:(Matrix2D, Matrix2D, Null<Matrix2D>) -> Matrix2D, message:String):Matrix2D {
		var x = copy(a), y = copy(b);
		var result = op(x, y, null);
		check(result != x && result != y && identical(x, a) && identical(y, b), '$message: into a new matrix, its inputs unchanged');
		var source = copy(a);
		check(op(source, copy(b), source) == source && identical(source, result), '$message: into the matrix itself');
		var other = copy(b);
		check(op(copy(a), other, other) == other && identical(other, result), '$message: into the other argument');
		return result;
	}

	static function main():Void {
		var m = new Matrix2D(), p = new Vector2D();
		check(is(m, [1, 0, 0, 1, 0, 0]), "made as the identity");
		check(m.set(1, 2, 3, 4, 5, 6) == m && is(m, [1, 2, 3, 4, 5, 6]) && m.makeIdentity() == m && is(m, [1, 0, 0, 1, 0, 0]),
			"set and made the identity, returning itself");
		check(at(Matrix2D.fromTranslation(3, -4).transformPoint(1, 2, p), 4, -2)
			&& Matrix2D.fromTranslation(3, -4).transformPoint(1, 2, p) == p,
			"a translation moves a point, into the vector given");
		check(at(Matrix2D.fromTranslation(3, -4).transformDirection(1, 2), 1, 2), "a direction isn't moved");
		check(at(Matrix2D.fromScale(2, 3).transformPoint(1, 1), 2, 3), "a scale");
		check(at(Matrix2D.fromRotation(Math.PI / 2).transformPoint(1, 0), 0, 1), "a quarter turn takes +x to +y");
		var into = new Matrix2D();
		check(Matrix2D.fromScale(1, 2, into) == into
			&& into.d == 2
			&& Matrix2D.fromRotation(1, into) == into
			&& Matrix2D.fromTranslation(1, 2, into) == into
			&& into.a == 1
			&& into.ty == 2,
			"a builder fills the matrix given and returns it");

		// Pinned: plain 3 x 3 algebra in Python (math.sin and math.cos), apart from Haxe and Trig.
		var m1 = Matrix2D.fromScale(2, 3).appendRotation(.7).appendTranslation(5, -6),
			m2 = Matrix2D.fromRotation(-1.2).appendScale(.5, -4).appendTranslation(1.5, 2.25);
		check(is(m1, [
			1.529684374568977,
			1.288435374475382,
			-1.932653061713073,
			2.2945265618534654,
			5,
			-6
		]), "scaled, turned and moved, in order: pinned");
		check(is(m2, [
			0.1811788772383368,
			3.728156343868905,
			0.46601954298361314,
			-1.4494310179066945,
			1.5,
			2.25
		]), "turned, scaled and moved: pinned");
		check(is(Matrix2D.compose(m1, m2), [
			0.8775825618903728,
			3.835404308833624,
			0.7191383079063045,
			-10.530990742684471,
			-0.3902228717099948,
			29.587367826784693
		]), "one followed by the other: pinned");
		check(is(m1.invert(), [
			0.38242109364224425,
			-0.21473922907923035,
			0.3221088436188455,
			0.25494739576149617,
			0.020547593501851757,
			2.6033805199651288
		]), "inverted: pinned");
		check(at(m1.transformPoint(1.25, -2.5), 11.743738122493903, -10.125772186539436), "a point carried: pinned");
		check(at(m1.transformDirection(1.25, -2.5), 6.7437381224939035, -4.125772186539436), "a direction carried: pinned");

		// Order: append is this then the other, prepend the other then this, and the appends are appending those matrices.
		check(identical(m1.append(m2), Matrix2D.compose(m1, m2))
			&& identical(m1.prepend(m2), Matrix2D.compose(m2, m1)), "append and prepend compose in order");
		check(is(m1.appendTranslation(1, 2), [m1.a, m1.b, m1.c, m1.d, m1.tx + 1, m1.ty + 2]), "a translation appended moves the result");
		var parts = Matrix2D.compose(m1, Matrix2D.fromScale(2, -1)),
			appended = m1.appendScale(2, -1);
		check(is(appended, [parts.a, parts.b, parts.c, parts.d, parts.tx, parts.ty]), "appending a scale is appending that matrix");
		parts = Matrix2D.compose(m1, Matrix2D.fromRotation(.3));
		appended = m1.appendRotation(.3);
		check(is(appended, [parts.a, parts.b, parts.c, parts.d, parts.tx, parts.ty]), "appending a rotation is appending that matrix");
		var twice = Matrix2D.fromTranslation(1, 0);
		check(Matrix2D.compose(twice, twice, twice) == twice
			&& at(twice.transformPoint(0, 0), 2, 0), "composed with itself on both sides, into itself");

		// Each operation into a new matrix (its inputs unchanged), into this one and into the other argument: the same each way.
		threeWays(m1, m2, (x, y, out) -> x.append(y, out), "append");
		threeWays(m1, m2, (x, y, out) -> x.prepend(y, out), "prepend");
		threeWays(m1, m2, (x, y, out) -> Matrix2D.compose(x, y, out), "compose");
		threeWays(m1, m2, (x, y, out) -> x.appendTranslation(1, 2, out), "appendTranslation");
		threeWays(m1, m2, (x, y, out) -> x.appendScale(-2, 3, out), "appendScale");
		threeWays(m1, m2, (x, y, out) -> x.appendRotation(.5, out), "appendRotation");
		threeWays(m1, m2, (x, y, out) -> x.invert(out), "invert");

		// Inverses: either way round the identity; a flattening matrix refused.
		for (matrix in [
			m1,
			m2,
			Matrix2D.compose(m1, m2),
			Matrix2D.fromScale(-1, 1e-3).appendRotation(-2.5).appendTranslation(1e4, -3e4)
		]) {
			var inverse = matrix.invert();
			check(inverse != null && is(matrix.append(inverse), [1, 0, 0, 1, 0, 0]) && is(inverse.append(matrix), [1, 0, 0, 1, 0, 0]),
				"followed by its inverse, or after it, the identity");
			matrix.transformPoint(12.5, -7, p);
			var back = inverse.transformPoint(p.x, p.y);
			check(at(back, 12.5, -7), "a point there and back");
		}
		var flat = Matrix2D.fromScale(1, 0).appendRotation(.4),
			kept = copy(flat),
			unchanged = Matrix2D.fromTranslation(1, 2),
			previous = copy(unchanged);
		check(flat.invert() == null && flat.invert(unchanged) == null && flat.invert(flat) == null && identical(flat, kept) && identical(unchanged, previous),
			"a matrix that flattens has no inverse: null, it and the out left as they were");

		// As a 4 x 4 matrix, acting on x and y alone.
		var big = m1.toMatrix3D(), given = new Matrix3D();
		var q = big.transformPoint(1.25, -2.5, 7);
		check(at(new Vector2D(q.x, q.y), 11.743738122493903, -10.125772186539436)
			&& q.z == 7, "as a 4 x 4 matrix: the same point, z kept");
		check(m1.toMatrix3D(given) == given && given.values[12] == m1.tx && given.values[4] == m1.c && given.values[15] == 1, "into the one given");

		// The interpreter multiplies Ints passed for Floats as Ints; whole numbers this large must still multiply as floats.
		var large = new Matrix2D().set(100000, 0, 0, 100000, 0, 0);
		check(large.transformPoint(100000, 0).x == 1e10
			&& large.appendScale(100000, 1).a == 1e10, "large whole numbers multiplied as floats");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
