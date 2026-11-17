import helix.math.Trig;
import helix.math.Vector2;
import helix.math.Vector3;
import helix.math.Vector4;

/** Checks Vector2, Vector3 and Vector4 with the library alone: made, set and copied, each returning the vector; every operation run three
	ways (into a new vector, the source untouched; into the source; into the other argument) with the same result; lengths, dot and
	cross products and distances; equality within a tolerance; 2D angles, turns and vectors from angles through `Trig`; large whole
	numbers multiplied as floats on the interpreter; a copy, separate or into an out; a vector written in braces; coordinates multiplied,
	divided, least, greatest and clamped; a length clamped; a point moved toward another; a Hermite curve; a direction reflected and
	refracted; angles between vectors; a projection and what is left; a perpendicular; a turn around an axis; two vectors made square;
	a triangle's weights; and a tolerance that grows with the coordinates. */
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
	static function three2(a:Array<Float>, b:Array<Float>, op:(Vector2, Vector2, Null<Vector2>) -> Vector2, message:String):Vector2 {
		var fresh = new Vector2(a[0], a[1]), other = new Vector2(b[0], b[1]);
		var result = op(fresh, other, null);
		check(result != fresh && result != other && fresh.x == a[0] && fresh.y == a[1] && other.x == b[0] && other.y == b[1],
			'$message: into a new vector, the inputs unchanged');
		var source = new Vector2(a[0], a[1]);
		check(op(source, new Vector2(b[0], b[1]), source) == source && source.equals(result), '$message: into the source');
		var argument = new Vector2(b[0], b[1]);
		check(op(new Vector2(a[0], a[1]), argument, argument) == argument && argument.equals(result), '$message: into the other argument');
		return result;
	}

	// As three2, in 3D.
	static function three3(a:Array<Float>, b:Array<Float>, op:(Vector3, Vector3, Null<Vector3>) -> Vector3, message:String):Vector3 {
		var fresh = new Vector3(a[0], a[1], a[2]),
			other = new Vector3(b[0], b[1], b[2]);
		var result = op(fresh, other, null);
		check(result != fresh
			&& result != other
			&& fresh.equals(new Vector3(a[0], a[1], a[2]))
			&& other.equals(new Vector3(b[0], b[1], b[2])),
			'$message: into a new vector, the inputs unchanged');
		var source = new Vector3(a[0], a[1], a[2]);
		check(op(source, new Vector3(b[0], b[1], b[2]), source) == source && source.equals(result), '$message: into the source');
		var argument = new Vector3(b[0], b[1], b[2]);
		check(op(new Vector3(a[0], a[1], a[2]), argument, argument) == argument
			&& argument.equals(result), '$message: into the other argument');
		return result;
	}

	static function main():Void {
		// 2D.
		var a = new Vector2();
		check(a.x == 0 && a.y == 0, "2D made at the origin");
		check(a.set(3, 4) == a && a.x == 3 && a.y == 4, "2D set, returning itself");
		check(a.length == 5 && a.lengthSquared == 25, "2D length and its square");
		var b = new Vector2().copyFrom(a);
		check(b != a && b.x == 3 && b.y == 4 && new Vector2().copyFrom(a) != a, "2D copied, returning itself");
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
		var zero = new Vector2().normalize();
		check(zero.x == 0 && zero.y == 0, "2D: a vector of length 0 normalized stays 0");
		var turned = three2([1., 0], q, (a, b, out) -> a.rotate(Math.PI / 2, out), "2D rotate");
		check(near(turned.x, 0) && near(turned.y, 1), "2D a quarter turn takes +x to +y");
		check(turned.x == Trig.cos(Math.PI / 2) && turned.y == Trig.sin(Math.PI / 2), "2D turned through Trig");
		var mid = three2([0., 10], [10., 20], (a, b, out) -> Vector2.lerp(a, b, .25, out), "2D lerp");
		check(mid.x == 2.5 && mid.y == 12.5, "2D lerp");
		var past = Vector2.lerp(new Vector2(0, 10), new Vector2(10, 20), 2);
		check(past.x == 20 && past.y == 30, "2D lerp past its end");
		var c = new Vector2(1, 1), d = new Vector2(2, 3);
		check(c.add(d, c).scale(2, c) == c && c.x == 6 && c.y == 8, "2D calls chain through the out");
		check(new Vector2(1, 2).dot(new Vector2(3, 4)) == 11 && new Vector2(1, 0).dot(new Vector2(0, 5)) == 0, "2D dot product");
		check(new Vector2(1,
			0).cross(new Vector2(0, 1)) == 1
				&& new Vector2(0, 1).cross(new Vector2(1, 0)) == -1 && new Vector2(2, 2).cross(new Vector2(4, 4)) == 0,
			"2D cross product: positive toward +y, 0 when parallel");
		check(new Vector2(1, 1).distance(new Vector2(4, 5)) == 5
			&& new Vector2(1, 1).distanceSquared(new Vector2(4, 5)) == 25, "2D distance");
		check(new Vector2(1,
			2).equals(new Vector2(1, 2))
				&& !new Vector2(1, 2).equals(new Vector2(1, 2.001)) && new Vector2(1, 2).equals(new Vector2(1.0009, 1.9991), .001),
			"2D equal exactly, or within a tolerance");
		check(near(new Vector2(0, 1).angle, Math.PI / 2)
			&& near(new Vector2(-1, 0).angle, Math.PI)
			&& new Vector2().angle == 0, "2D angle");
		var aimed = Vector2.fromAngle(Math.PI, 2);
		check(near(aimed.x, -2) && near(aimed.y, 0), "2D from an angle and a length");
		var given = new Vector2();
		check(Vector2.fromAngle(0, given) == given
			&& given.x == 1
			&& given.y == 0, "2D from an angle, its length 1, into the vector given");

		// 3D.
		var e = new Vector3();
		check(e.x == 0 && e.y == 0 && e.z == 0, "3D made at the origin");
		check(e.set(2, 3, 6) == e && e.length == 7 && e.lengthSquared == 49, "3D set, returning itself; its length and square");
		var f = new Vector3();
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
		var zero3 = new Vector3().normalize();
		check(zero3.x == 0 && zero3.y == 0 && zero3.z == 0, "3D: a vector of length 0 normalized stays 0");
		var crossed = three3(r, s, (a, b, out) -> a.cross(b, out), "3D cross");
		check(crossed.x == 27 && crossed.y == 6 && crossed.z == -13, "3D cross product");
		var z = new Vector3(1, 0, 0).cross(new Vector3(0, 1, 0));
		check(z.x == 0
			&& z.y == 0
			&& z.z == 1
			&& new Vector3(0, 1, 0).cross(new Vector3(1, 0, 0)).z == -1, "3D: x cross y is z, y cross x -z");
		check(new Vector3(1, 2, 3).cross(new Vector3(2, 4, 6)).length == 0, "3D cross product of parallel vectors");
		var quarter = three3([0., 0, 0], [4., 8, -4], (a, b, out) -> Vector3.lerp(a, b, .25, out), "3D lerp");
		check(quarter.x == 1 && quarter.y == 2 && quarter.z == -1, "3D lerp");
		var g = new Vector3(1, 1, 1);
		check(g.add(new Vector3(1, 2, 3), g).scale(2, g).normalize(g) == g && near(g.length, 1), "3D calls chain through the out");
		check(new Vector3(1, 2, 3).dot(new Vector3(4, -5, 6)) == 12, "3D dot product");
		check(new Vector3(1, 2, 3).distance(new Vector3(3, 5, 9)) == 7
			&& new Vector3().distanceSquared(new Vector3(1, 2, 2)) == 9, "3D distance");
		check(new Vector3(1, 2,
			3).equals(new Vector3(1, 2, 3))
				&& !new Vector3(1, 2, 3).equals(new Vector3(1, 2, 3.5)) && new Vector3(1, 2, 3).equals(new Vector3(1, 2, 3.5), .5),
			"3D equal exactly, or within a tolerance");

		// Whole numbers past 32 bits when multiplied: the interpreter keeps an Int passed for a Float as an Int.
		var big = 100000;
		check(new Vector2(big, big).lengthSquared == 2e10, "2D: large whole numbers squared as floats");
		check(new Vector2(big, 0).dot(new Vector2(big, 0)) == 1e10 && new Vector2(big, 0).cross(new Vector2(0, big)) == 1e10,
			"2D: large whole numbers' dot and cross products");
		check(new Vector2(big, 0).scale(big).x == 1e10 && new Vector2().set(big, 0).distanceSquared(new Vector2()) == 1e10,
			"2D: large whole numbers scaled, and their distance");
		check(new Vector3(big, big, big).lengthSquared == 3e10 && new Vector3(0, 0, big).dot(new Vector3(0, 0, big)) == 1e10,
			"3D: large whole numbers squared as floats");
		var bigCross = new Vector3(big, 0, 0).cross(new Vector3(0, big, 0));
		check(bigCross.z == 1e10 && new Vector3(0, big, 0).scale(big).y == 1e10, "3D: large whole numbers' cross product, scaled");
		// Four numbers: made, set and copied, each operation into a new vector, into the source and into the other argument.
		var four = new Vector4();
		check(four.x == 0 && four.y == 0 && four.z == 0 && four.w == 0, "4D: zero by default");
		check(four.set(1, 2, 3, 4) == four
			&& four.w == 4
			&& new Vector4().copyFrom(four).equals(four), "4D: set and copied, each returning it");
		var ops:Array<{name:String, op:(Vector4, Vector4, Null<Vector4>) -> Vector4, want:Array<Float>}> = [
			{name: "sum", op: (a, b, out) -> a.add(b, out), want: [6, 8, 10, 12]},
			{name: "difference", op: (a, b, out) -> a.subtract(b, out), want: [-4, -4, -4, -4]},
			{name: "scaled", op: (a, b, out) -> a.scale(2, out), want: [2, 4, 6, 8]},
			{name: "sum of one scaled", op: (a, b, out) -> a.addScaled(b, 2, out), want: [11, 14, 17, 20]},
			{name: "negated", op: (a, b, out) -> a.negate(out), want: [-1, -2, -3, -4]},
			{name: "blend", op: (a, b, out) -> Vector4.lerp(a, b, .5, out), want: [3, 4, 5, 6]}
		];
		for (o in ops) {
			var want = new Vector4(o.want[0], o.want[1], o.want[2], o.want[3]);
			var a = new Vector4(1, 2, 3, 4), b = new Vector4(5, 6, 7, 8);
			var made = o.op(a, b, null);
			check(made != a && made != b && made.equals(want) && a.equals(new Vector4(1, 2, 3, 4)) && b.equals(new Vector4(5, 6, 7, 8)),
				'4D ${o.name}: into a new vector, the inputs unchanged');
			check(o.op(a, b, a) == a && a.equals(want), '4D ${o.name}: into the source');
			a.set(1, 2, 3, 4);
			check(o.op(a, b, b) == b && b.equals(want), '4D ${o.name}: into the other argument');
		}
		var unit = new Vector4(2, 0, 0, 0).normalize();
		check(unit.x == 1 && unit.length == 1 && new Vector4().normalize().length == 0, "4D: length 1, and length 0 kept");
		check(new Vector4(1, 2, 2, 4).lengthSquared == 25 && new Vector4(1, 2, 2, 4).length == 5, "4D lengths");
		check(new Vector4(1, 2, 3, 4).dot(new Vector4(5, 6, 7, 8)) == 70, "4D dot product");
		check(new Vector4().distance(new Vector4(1, 2, 2, 4)) == 5
			&& new Vector4().distanceSquared(new Vector4(1, 2, 2, 4)) == 25, "4D distance");
		check(!new Vector4(1, 2, 3, 4).equals(new Vector4(1, 2, 3, 4.5)) && new Vector4(1, 2, 3, 4).equals(new Vector4(1, 2, 3, 4.5), .5),
			"4D equal exactly, or within a tolerance");
		check(new Vector4(big, big, big, big).lengthSquared == 4e10 && new Vector4(0, 0, 0, big).scale(big).w == 1e10,
			"4D: large whole numbers squared and scaled as floats");

		// Coordinate by coordinate: times, over, least and greatest.
		check(three2([2, 3], [4, 5], (a, b, out) -> a.multiply(b, out), "2D multiply").equals(new Vector2(8, 15)), "2D multiply");
		check(three2([8, 3], [4, 6], (a, b, out) -> a.divide(b, out), "2D divide").equals(new Vector2(2, .5)), "2D divide");
		check(three2([2, 7], [4, 5], (a, b, out) -> a.min(b, out), "2D min").equals(new Vector2(2, 5)), "2D min");
		check(three2([2, 7], [4, 5], (a, b, out) -> a.max(b, out), "2D max").equals(new Vector2(4, 7)), "2D max");
		check(three3([2, 3, 4], [4, 5, 6], (a, b, out) -> a.multiply(b, out), "3D multiply").equals(new Vector3(8, 15, 24)), "3D multiply");
		check(three3([8, 3, 1], [4, 6, 8], (a, b, out) -> a.divide(b, out), "3D divide").equals(new Vector3(2, .5, .125)), "3D divide");
		check(three3([2, 7, 1], [4, 5, 1], (a, b, out) -> a.min(b, out), "3D min").equals(new Vector3(2, 5, 1)), "3D min");
		check(three3([2, 7, 1], [4, 5, 3], (a, b, out) -> a.max(b, out), "3D max").equals(new Vector3(4, 7, 3)), "3D max");
		var p4 = new Vector4(8, 3, 1, 6), q4 = new Vector4(4, 6, 8, 3);
		check(p4.multiply(q4).equals(new Vector4(32, 18, 8, 18))
			&& p4.divide(q4).equals(new Vector4(2, .5, .125, 2)), "4D multiply and divide");
		check(p4.min(q4).equals(new Vector4(4, 3, 1, 3)) && p4.max(q4).equals(new Vector4(8, 6, 8, 6)), "4D min and max");
		check(p4.multiply(q4, p4) == p4 && p4.equals(new Vector4(32, 18, 8, 18)) && q4.w == 3, "4D multiply into the source");
		check(new Vector2(big, big).multiply(new Vector2(big, 2)).x == 1e10, "large whole numbers multiplied coordinate by coordinate as floats");

		// Clamped: each coordinate between two vectors', or the length between two lengths.
		check(new Vector2(-1, 9).clamp(new Vector2(0, 0), new Vector2(5, 5)).equals(new Vector2(0, 5)), "2D clamp");
		check(new Vector3(-1, 9, 2).clamp(new Vector3(0, 0, 0), new Vector3(5, 5, 5)).equals(new Vector3(0, 5, 2)), "3D clamp");
		check(new Vector4(-1, 9, 2, 7).clamp(new Vector4(0, 0, 0, 0), new Vector4(5, 5, 5, 5)).equals(new Vector4(0, 5, 2, 5)), "4D clamp");
		check(new Vector2(-1,
			9).clamp(new Vector2(5, 0),
				new Vector2(0, 5)).equals(new Vector2(0, 5)) && new Vector2(3, 4).clampLength(2, 1).equals(new Vector2(3, 4).clampLength(1, 2)),
			"clamp: bounds in the wrong order swapped");
		var low3 = new Vector3(0, 0, 0), clamped3 = new Vector3(-1, 9, 2);
		check(clamped3.clamp(low3, new Vector3(5, 5, 5), low3) == low3 && low3.equals(new Vector3(0, 5, 2)), "3D clamp into a bound");
		var long2 = new Vector2(3, 4).clampLength(1, 2),
			short2 = new Vector2(.3, .4).clampLength(1, 2);
		check(near(long2.x, 1.2) && near(long2.y, 1.6) && near(short2.x, .6) && near(short2.y, .8), "2D length clamped down and up");
		check(new Vector2(3, 4).clampLength(1, 10).equals(new Vector2(3, 4)) && new Vector2().clampLength(1, 2).length == 0,
			"2D: a length within the bounds kept, and length 0 kept");
		check(near(new Vector3(0, 3, 4).clampLength(0, 1).length, 1) && new Vector3().clampLength(1, 2).length == 0, "3D length clamped");
		check(near(new Vector4(0, 3, 0, 4).clampLength(10, 20).length, 10)
			&& new Vector4().clampLength(1, 2).length == 0, "4D length clamped");

		// Moved toward a target: by the step, onto the target exactly, and not at all for a step of 0 or less.
		var start2 = new Vector2(0, 0), target2 = new Vector2(3, 4);
		var moved2 = start2.moveToward(target2, 1);
		check(near(moved2.x, .6) && near(moved2.y, .8) && start2.x == 0, "2D moved toward a target by a step");
		check(start2.moveToward(target2, 5).equals(target2)
			&& start2.moveToward(target2, 50).equals(target2), "2D: the target reached exactly");
		check(start2.moveToward(target2, 0).equals(start2)
			&& start2.moveToward(target2, -1).equals(start2), "2D: a step of 0 or less moves nothing");
		check(start2.moveToward(target2, 1, target2) == target2 && near(target2.x, .6), "2D moved into the target");
		var moved3 = new Vector3(1, 1, 1).moveToward(new Vector3(1, 1, 5), 3);
		check(moved3.equals(new Vector3(1, 1, 4))
			&& new Vector3(1, 1, 1).moveToward(new Vector3(1, 1, 5), 9).z == 5, "3D moved toward a target");
		check(new Vector3(1, 1, 1).moveToward(new Vector3(1, 1, 5), -2).z == 1, "3D: a step under 0 moves nothing");
		check(new Vector4(0, 0, 0, 1).moveToward(new Vector4(0, 0, 0, 5), 3).w == 4
			&& new Vector4(0, 0, 0, 1).moveToward(new Vector4(0, 0, 0, 5), 0).w == 1,
			"4D moved toward a target");

		// A Hermite curve: its ends, and its middle by the curve's four weights (1/2, 1/8, 1/2, -1/8).
		var h2 = Vector2.hermite(new Vector2(0, 0), new Vector2(8, 0), new Vector2(4, 4), new Vector2(0, 8), .5);
		check(near(h2.x, 3) && near(h2.y, 1), "2D Hermite halfway");
		check(Vector2.hermite(new Vector2(1, 2), new Vector2(8, 0), new Vector2(4, 4), new Vector2(0, 8), 0).equals(new Vector2(1, 2))
			&& Vector2.hermite(new Vector2(1, 2), new Vector2(8, 0), new Vector2(4, 4), new Vector2(0, 8), 1).equals(new Vector2(4, 4)),
			"2D Hermite at its ends");
		var from3h = new Vector3(0, 0, 0), to3h = new Vector3(4, 4, 4);
		var h3 = Vector3.hermite(from3h, new Vector3(8, 0, 0), to3h, new Vector3(0, 8, 0), .5);
		check(near(h3.x, 3) && near(h3.y, 1) && near(h3.z, 2), "3D Hermite halfway");
		check(Vector3.hermite(from3h, new Vector3(8, 0, 0), to3h, new Vector3(0, 8, 0), .5, to3h) == to3h && to3h.equals(h3, 1e-12),
			"3D Hermite into an argument");
		var h4 = Vector4.hermite(new Vector4(), new Vector4(8, 0, 0, 0), new Vector4(4, 4, 4, 4), new Vector4(0, 8, 0, 0), .5);
		check(near(h4.x, 3) && near(h4.y, 1) && near(h4.z, 2) && near(h4.w, 2), "4D Hermite halfway");

		// Bounced off a surface, and bent entering one.
		check(three2([1, -1], [0, 1], (a, b, out) -> a.reflect(b, out), "2D reflect").equals(new Vector2(1, 1)), "2D reflect");
		check(three3([1, -1, 2], [0, 1, 0], (a, b, out) -> a.reflect(b, out), "3D reflect").equals(new Vector3(1, 1, 2)), "3D reflect");
		var straight2 = new Vector2(.6, -.8).refract(new Vector2(0, 1), 1);
		check(near(straight2.x, .6) && near(straight2.y, -.8), "2D refract: a ratio of 1 bends nothing");
		var bent2 = new Vector2(.6, -.8).refract(new Vector2(0, 1), .5);
		check(near(bent2.x, .3) && near(bent2.y, -Math.sqrt(.91)) && near(bent2.length, 1), "2D refract: bent toward the normal, of length 1");
		check(new Vector2(.8, -.6).refract(new Vector2(0, 1), 2).length == 0, "2D refract: all 0 when wholly reflected");
		var bent3 = new Vector3(.6, -.8, 0).refract(new Vector3(0, 1, 0), .5);
		check(near(bent3.x, .3) && near(bent3.y, -Math.sqrt(.91)) && bent3.z == 0, "3D refract");
		check(new Vector3(.8, -.6, 0).refract(new Vector3(0, 1, 0), 2).length == 0, "3D refract: all 0 when wholly reflected");
		var normal3 = new Vector3(0, 1, 0);
		check(new Vector3(.6, -.8, 0).refract(normal3, .5, normal3) == normal3
			&& normal3.equals(bent3, 1e-12), "3D refract into the normal");

		// Angles: signed in 2D, toward +y positive; 0 to pi in 3D.
		check(near(new Vector2(1, 0).angleTo(new Vector2(0, 2)), Math.PI / 2)
			&& near(new Vector2(0, 2).angleTo(new Vector2(1, 0)), -Math.PI / 2),
			"2D angle to another, signed");
		check(new Vector2(1, 1).angleTo(new Vector2(3, 3)) == 0 && near(new Vector2(1, 0).angleTo(new Vector2(-1, 0)), Math.PI),
			"2D angle to the same direction and the opposite");
		check(near(new Vector3(1, 0, 0).angleTo(new Vector3(0, 0, 2)), Math.PI / 2)
			&& near(new Vector3(0, 0, 2).angleTo(new Vector3(1, 0, 0)), Math.PI / 2),
			"3D angle between two, the same either way");
		check(new Vector3(1, 2, 3).angleTo(new Vector3(2, 4, 6)) == 0
			&& near(new Vector3(1, 2, 3).angleTo(new Vector3(-1, -2, -3)), Math.PI),
			"3D angle to the same direction and the opposite");

		// The part along another vector, and the part square to it.
		check(three3([1, 2, 3], [0, 0, 5], (a, b, out) -> a.project(b, out), "project").equals(new Vector3(0, 0, 3)), "project");
		check(three3([1, 2, 3], [0, 0, 5], (a, b, out) -> a.reject(b, out), "reject").equals(new Vector3(1, 2, 0)), "reject");

		// A perpendicular: crossed with the axis the vector lies least along.
		for (v in ([[1, 0, 0], [0, 1, 0], [0, 0, 1], [3, -2, 5], [-4, 4, .5], [1, 1, 1]] : Array<Array<Float>>)) {
			var vector = new Vector3(v[0], v[1], v[2]);
			var square = vector.perpendicular();
			check(near(square.dot(vector), 0) && square.length > 0, 'a perpendicular of $v is square to it');
		}
		check(new Vector3(3, 2,
			1).perpendicular().equals(new Vector3(2, -3,
				0)) && new Vector3(3, 1, 2).perpendicular().equals(new Vector3(-2, 0, 3)) && new Vector3(1, 3, 2).perpendicular()
					.equals(new Vector3(0, 2, -3)),
			"a perpendicular: crossed with z, y or x");
		var itself = new Vector3(3, 2, 1);
		check(itself.perpendicular(itself) == itself && itself.equals(new Vector3(2, -3, 0)) && new Vector3().perpendicular().length == 0,
			"a perpendicular into the vector, and of length 0");

		// Turned around an axis of any length, by the right-hand rule.
		var turned = new Vector3(1, 0, 0).rotate(new Vector3(0, 0, 2), Math.PI / 2);
		check(near(turned.x, 0) && near(turned.y, 1) && near(turned.z, 0), "a point turned a quarter around z");
		var axis = new Vector3(1, -2, 3), point = new Vector3(4, 5, -6);
		var byQuaternion = helix.math.Quaternion.fromAxisAngle(1, -2, 3, 1.25).transformPoint(4, 5, -6);
		var around = point.rotate(axis, 1.25);
		check(Math.abs(around.x - byQuaternion.x) < 1e-12
			&& Math.abs(around.y - byQuaternion.y) < 1e-12
			&& Math.abs(around.z - byQuaternion.z) < 1e-12
			&& near(around.length, point.length),
			"a point turned around an axis, as a quaternion of the axis and angle turns the point");
		check(point.rotate(new Vector3(), 1).equals(point)
			&& point.rotate(axis, 0).equals(point, 1e-12), "an axis of length 0, or no angle, turns nothing");
		check(point.rotate(axis, 1.25, axis) == axis && axis.equals(around, 1e-12), "a point turned into the axis");

		// Two vectors made of length 1 and square, the first's direction kept.
		var first = new Vector3(2, 0, 0), second = new Vector3(3, 4, 0);
		Vector3.orthoNormalize(first, second);
		check(first.equals(new Vector3(1, 0, 0)) && second.equals(new Vector3(0, 1, 0), 1e-12), "two vectors made square and of length 1");
		first.set(1, 2, 3);
		second.set(-2, 0, 5);
		Vector3.orthoNormalize(first, second);
		check(near(first.length, 1) && near(second.length, 1) && near(first.dot(second), 0) && second.dot(new Vector3(-2, 0, 5)) > 0,
			"square and of length 1, the second on its own side");

		// A triangle's weights for a point: 1 at a corner, a third each at the middle, and the point made again from the weights.
		var ca = new Vector3(0, 0, 0),
			cb = new Vector3(4, 0, 0),
			cc = new Vector3(0, 4, 2);
		check(Vector3.barycentric(ca, ca, cb, cc).equals(new Vector3(1, 0, 0))
			&& Vector3.barycentric(cb, ca, cb, cc).equals(new Vector3(0, 1, 0))
			&& Vector3.barycentric(cc, ca, cb, cc).equals(new Vector3(0, 0, 1)),
			"barycentric: 1 at each corner");
		var middle = Vector3.barycentric(new Vector3(4 / 3, 4 / 3, 2 / 3), ca, cb, cc);
		check(middle.equals(new Vector3(1 / 3, 1 / 3, 1 / 3), 1e-12), "barycentric: a third each at the middle");
		var weights = Vector3.barycentric(new Vector3(1, 2, 1), ca, cb, cc);
		check(near(weights.x + weights.y + weights.z, 1)
			&& near(weights.y * 4, 1)
			&& near(weights.z * 4, 2), "barycentric: weights that add to 1");
		var inPlace = new Vector3(1, 2, 1);
		check(Vector3.barycentric(inPlace, ca, cb, cc, inPlace) == inPlace && inPlace.equals(weights), "barycentric into the point");

		// A tolerance is multiplied by the larger coordinate's size when that size is over 1.
		check(new Vector2(1000,
			0).equals(new Vector2(1000.5, 0), .001)
				&& !new Vector2(.1, 0).equals(new Vector2(.2, 0), .001) && !new Vector2(1000, 0).equals(new Vector2(1002, 0), .001),
			"2D: a tolerance grows with the coordinates over 1");
		check(new Vector3(0, 1000, 0).equals(new Vector3(0, 1000.5, 0), .001)
			&& !new Vector3(0, 0, .1).equals(new Vector3(0, 0, .2), .001),
			"3D: a tolerance grows with the coordinates over 1");
		check(new Vector4(0, 0, 0, 1000).equals(new Vector4(0, 0, 0, 1000.5), .001)
			&& !new Vector4(.1, 0, 0, 0).equals(new Vector4(.2, 0, 0, 0), .001),
			"4D: a tolerance grows with the coordinates over 1");

		// A copy is a separate vector, or the out filled.
		var from2 = new Vector2(1, 2),
			copy2 = from2.copy(),
			out2 = new Vector2();
		copy2.x = 9;
		check(from2.x == 1 && copy2.y == 2 && from2.copy(out2) == out2 && out2.equals(from2), "2D: a copy is separate, or the out filled");
		var from3 = new Vector3(1, 2, 3),
			copy3 = from3.copy(),
			out3 = new Vector3();
		copy3.x = 9;
		check(from3.x == 1 && copy3.z == 3 && from3.copy(out3) == out3 && out3.equals(from3), "3D: a copy is separate, or the out filled");
		var from4 = new Vector4(1, 2, 3, 4),
			copy4 = from4.copy(),
			out4 = new Vector4();
		copy4.x = 9;
		check(from4.x == 1 && copy4.w == 4 && from4.copy(out4) == out4 && out4.equals(from4), "4D: a copy is separate, or the out filled");

		// Written in braces, a coordinate left out is 0.
		var braced2:Vector2 = {x: 1, y: 2},
			braced3:Vector3 = {x: 1, z: 3},
			braced4:Vector4 = {w: 4};
		check(braced2.equals(new Vector2(1, 2)) && braced3.equals(new Vector3(1, 0, 3)) && braced4.equals(new Vector4(0, 0, 0, 4)),
			"a vector in braces, a coordinate left out 0");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
