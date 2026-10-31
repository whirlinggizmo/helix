import helix.math.Trig;
import helix.math.Vector2D;
import helix.math.Vector3D;

/** Checks Vector2D and Vector3D with the library alone: made, set and copied, each returning the vector; every operation run three
	ways (into a new vector, the source untouched; into the source; into the other argument) with the same result; lengths, dot and
	cross products and distances; equality within a tolerance; 2D angles, turns and vectors from angles through `Trig`; and large whole
	numbers multiplied as floats on the interpreter. */
class VectorTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-12;

	// Runs a 2D operation of a and b into a new vector, into a and into b: the same result each way, the inputs untouched without an out.
	static function three2(a:Array<Float>, b:Array<Float>, op:(Vector2D, Vector2D, Null<Vector2D>) -> Vector2D, message:String):Vector2D {
		var fresh = new Vector2D(a[0], a[1]), other = new Vector2D(b[0], b[1]);
		var result = op(fresh, other, null);
		check(result != fresh && result != other && fresh.x == a[0] && fresh.y == a[1] && other.x == b[0] && other.y == b[1],
			'$message: into a new vector, the inputs unchanged');
		var source = new Vector2D(a[0], a[1]);
		check(op(source, new Vector2D(b[0], b[1]), source) == source && source.equals(result), '$message: into the source');
		var argument = new Vector2D(b[0], b[1]);
		check(op(new Vector2D(a[0], a[1]), argument, argument) == argument
			&& argument.equals(result), '$message: into the other argument');
		return result;
	}

	// As three2, in 3D.
	static function three3(a:Array<Float>, b:Array<Float>, op:(Vector3D, Vector3D, Null<Vector3D>) -> Vector3D, message:String):Vector3D {
		var fresh = new Vector3D(a[0], a[1], a[2]),
			other = new Vector3D(b[0], b[1], b[2]);
		var result = op(fresh, other, null);
		check(result != fresh
			&& result != other
			&& fresh.equals(new Vector3D(a[0], a[1], a[2]))
			&& other.equals(new Vector3D(b[0], b[1], b[2])),
			'$message: into a new vector, the inputs unchanged');
		var source = new Vector3D(a[0], a[1], a[2]);
		check(op(source, new Vector3D(b[0], b[1], b[2]), source) == source && source.equals(result), '$message: into the source');
		var argument = new Vector3D(b[0], b[1], b[2]);
		check(op(new Vector3D(a[0], a[1], a[2]), argument, argument) == argument
			&& argument.equals(result), '$message: into the other argument');
		return result;
	}

	static function main():Void {
		// 2D.
		var a = new Vector2D();
		check(a.x == 0 && a.y == 0, "2D made at the origin");
		check(a.set(3, 4) == a && a.x == 3 && a.y == 4, "2D set, returning itself");
		check(a.length == 5 && a.lengthSquared == 25, "2D length and its square");
		var b = new Vector2D().copyFrom(a);
		check(b != a && b.x == 3 && b.y == 4 && new Vector2D().copyFrom(a) != a, "2D copied, returning itself");
		var p = [3., 4], q = [1., -2];
		var sum = three2(p, q, (a, b, out) -> a.add(b, out), "2D add");
		check(sum.x == 4 && sum.y == 2, "2D added");
		var difference = three2(p, q, (a, b, out) -> a.subtract(b, out), "2D subtract");
		check(difference.x == 2 && difference.y == 6, "2D subtracted");
		var scaled = three2(p, q, (a, b, out) -> a.scale(.5, out), "2D scale");
		check(scaled.x == 1.5 && scaled.y == 2, "2D scaled");
		var moved = three2(p, q, (a, b, out) -> a.addScaled(b, 2, out), "2D addScaled");
		check(moved.x == 5 && moved.y == 0, "2D added scaled");
		var negated = three2(p, q, (a, b, out) -> a.negate(out), "2D negate");
		check(negated.x == -3 && negated.y == -4, "2D negated");
		var unit = three2(p, q, (a, b, out) -> a.normalize(out), "2D normalize");
		check(near(unit.x, .6) && near(unit.y, .8) && near(unit.length, 1), "2D normalized");
		var zero = new Vector2D().normalize();
		check(zero.x == 0 && zero.y == 0, "2D: a vector of length 0 normalized stays 0");
		var turned = three2([1., 0], q, (a, b, out) -> a.rotate(Math.PI / 2, out), "2D rotate");
		check(near(turned.x, 0) && near(turned.y, 1), "2D a quarter turn takes +x to +y");
		check(turned.x == Trig.cos(Math.PI / 2) && turned.y == Trig.sin(Math.PI / 2), "2D turned through Trig");
		var mid = three2([0., 10], [10., 20], (a, b, out) -> Vector2D.lerp(a, b, .25, out), "2D lerp");
		check(mid.x == 2.5 && mid.y == 12.5, "2D lerp");
		var past = Vector2D.lerp(new Vector2D(0, 10), new Vector2D(10, 20), 2);
		check(past.x == 20 && past.y == 30, "2D lerp past its end");
		var c = new Vector2D(1, 1), d = new Vector2D(2, 3);
		check(c.add(d, c).scale(2, c) == c && c.x == 6 && c.y == 8, "2D calls chain through the out");
		check(new Vector2D(1, 2).dot(new Vector2D(3, 4)) == 11 && new Vector2D(1, 0).dot(new Vector2D(0, 5)) == 0, "2D dot product");
		check(new Vector2D(1,
			0).cross(new Vector2D(0, 1)) == 1
				&& new Vector2D(0, 1).cross(new Vector2D(1, 0)) == -1 && new Vector2D(2, 2).cross(new Vector2D(4, 4)) == 0,
			"2D cross product: positive toward +y, 0 when parallel");
		check(new Vector2D(1, 1).distance(new Vector2D(4, 5)) == 5
			&& new Vector2D(1, 1).distanceSquared(new Vector2D(4, 5)) == 25, "2D distance");
		check(new Vector2D(1,
			2).equals(new Vector2D(1, 2))
				&& !new Vector2D(1, 2).equals(new Vector2D(1, 2.001)) && new Vector2D(1, 2).equals(new Vector2D(1.0009, 1.9991), .001),
			"2D equal exactly, or within a tolerance");
		check(near(new Vector2D(0, 1).angle, Math.PI / 2)
			&& near(new Vector2D(-1, 0).angle, Math.PI)
			&& new Vector2D().angle == 0, "2D angle");
		var aimed = Vector2D.fromAngle(Math.PI, 2);
		check(near(aimed.x, -2) && near(aimed.y, 0), "2D from an angle and a length");
		var given = new Vector2D();
		check(Vector2D.fromAngle(0, given) == given
			&& given.x == 1
			&& given.y == 0, "2D from an angle, its length 1, into the vector given");

		// 3D.
		var e = new Vector3D();
		check(e.x == 0 && e.y == 0 && e.z == 0, "3D made at the origin");
		check(e.set(2, 3, 6) == e && e.length == 7 && e.lengthSquared == 49, "3D set, returning itself; its length and square");
		var f = new Vector3D();
		check(f.copyFrom(e) == f && f != e && f.x == 2 && f.y == 3 && f.z == 6, "3D copied, returning itself");
		var r = [1., 2, 3], s = [4., -5, 6];
		var sum3 = three3(r, s, (a, b, out) -> a.add(b, out), "3D add");
		check(sum3.x == 5 && sum3.y == -3 && sum3.z == 9, "3D added");
		var difference3 = three3(r, s, (a, b, out) -> a.subtract(b, out), "3D subtract");
		check(difference3.x == -3 && difference3.y == 7 && difference3.z == -3, "3D subtracted");
		var scaled3 = three3(r, s, (a, b, out) -> a.scale(2, out), "3D scale");
		check(scaled3.x == 2 && scaled3.y == 4 && scaled3.z == 6, "3D scaled");
		var moved3 = three3(r, s, (a, b, out) -> a.addScaled(b, .5, out), "3D addScaled");
		check(moved3.x == 3 && moved3.y == -.5 && moved3.z == 6, "3D added scaled");
		var negated3 = three3(r, s, (a, b, out) -> a.negate(out), "3D negate");
		check(negated3.x == -1 && negated3.y == -2 && negated3.z == -3, "3D negated");
		var unit3 = three3([0., 3, 4], s, (a, b, out) -> a.normalize(out), "3D normalize");
		check(unit3.x == 0 && near(unit3.y, .6) && near(unit3.z, .8), "3D normalized");
		var zero3 = new Vector3D().normalize();
		check(zero3.x == 0 && zero3.y == 0 && zero3.z == 0, "3D: a vector of length 0 normalized stays 0");
		var crossed = three3(r, s, (a, b, out) -> a.cross(b, out), "3D cross");
		check(crossed.x == 27 && crossed.y == 6 && crossed.z == -13, "3D cross product");
		var z = new Vector3D(1, 0, 0).cross(new Vector3D(0, 1, 0));
		check(z.x == 0
			&& z.y == 0
			&& z.z == 1
			&& new Vector3D(0, 1, 0).cross(new Vector3D(1, 0, 0)).z == -1, "3D: x cross y is z, y cross x -z");
		check(new Vector3D(1, 2, 3).cross(new Vector3D(2, 4, 6)).length == 0, "3D cross product of parallel vectors");
		var quarter = three3([0., 0, 0], [4., 8, -4], (a, b, out) -> Vector3D.lerp(a, b, .25, out), "3D lerp");
		check(quarter.x == 1 && quarter.y == 2 && quarter.z == -1, "3D lerp");
		var g = new Vector3D(1, 1, 1);
		check(g.add(new Vector3D(1, 2, 3), g).scale(2, g).normalize(g) == g && near(g.length, 1), "3D calls chain through the out");
		check(new Vector3D(1, 2, 3).dot(new Vector3D(4, -5, 6)) == 12, "3D dot product");
		check(new Vector3D(1, 2, 3).distance(new Vector3D(3, 5, 9)) == 7
			&& new Vector3D().distanceSquared(new Vector3D(1, 2, 2)) == 9, "3D distance");
		check(new Vector3D(1, 2,
			3).equals(new Vector3D(1, 2, 3))
				&& !new Vector3D(1, 2, 3).equals(new Vector3D(1, 2, 3.5)) && new Vector3D(1, 2, 3).equals(new Vector3D(1, 2, 3.5), .5),
			"3D equal exactly, or within a tolerance");

		// Whole numbers past 32 bits when multiplied: the interpreter keeps an Int passed for a Float as an Int.
		var big = 100000;
		check(new Vector2D(big, big).lengthSquared == 2e10, "2D: large whole numbers squared as floats");
		check(new Vector2D(big, 0).dot(new Vector2D(big, 0)) == 1e10 && new Vector2D(big, 0).cross(new Vector2D(0, big)) == 1e10,
			"2D: large whole numbers' dot and cross products");
		check(new Vector2D(big, 0).scale(big).x == 1e10 && new Vector2D().set(big, 0).distanceSquared(new Vector2D()) == 1e10,
			"2D: large whole numbers scaled, and their distance");
		check(new Vector3D(big, big, big).lengthSquared == 3e10 && new Vector3D(0, 0, big).dot(new Vector3D(0, 0, big)) == 1e10,
			"3D: large whole numbers squared as floats");
		var bigCross = new Vector3D(big, 0, 0).cross(new Vector3D(0, big, 0));
		check(bigCross.z == 1e10 && new Vector3D(0, big, 0).scale(big).y == 1e10, "3D: large whole numbers' cross product, scaled");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
