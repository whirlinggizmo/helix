import helix.math.Matrix3D;
import helix.math.Quaternion3D;
import helix.math.Vector3D;

/** Checks Quaternion3D with the library alone: made, set, copied and reset, each returning itself; made from an axis and an angle, from
	three turns, facing a direction, between two directions and from a matrix; blended (slerp and nlerp, the shorter way round, slerp at
	an even speed and past its ends), composed in order, inverted and normalized; points turned, its angle, its matrix and its turns
	back; values pinned to rotation matrices and Hamilton products computed apart from Haxe, and to raylib 5.5's raymath for the same
	inputs (to its float precision); every operation into a new rotation, itself and each other argument, the same each way; and whole
	numbers multiplied as floats on the interpreter. */
class Quaternion3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) < tolerance;

	static function is(q:Quaternion3D, values:Array<Float>, tolerance = 1e-12):Bool
		return near(q.x, values[0], tolerance) && near(q.y, values[1], tolerance) && near(q.z, values[2], tolerance) && near(q.w, values[3], tolerance);

	// The same rotation: q or -q.
	static function turnsAs(q:Quaternion3D, values:Array<Float>, tolerance = 1e-12):Bool
		return is(q, values, tolerance) || is(q, [-values[0], -values[1], -values[2], -values[3]], tolerance);

	static function at(p:Vector3D, x:Float, y:Float, z:Float, tolerance = 1e-12):Bool
		return near(p.x, x, tolerance) && near(p.y, y, tolerance) && near(p.z, z, tolerance);

	static function identical(a:Quaternion3D, b:Quaternion3D):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;

	static function copy(q:Quaternion3D):Quaternion3D
		return new Quaternion3D().copyFrom(q);

	// Runs an operation of a and b into a new rotation, into a and into b: the same result each way, its inputs untouched without an out.
	static function threeWays(a:Quaternion3D, b:Quaternion3D, op:(Quaternion3D, Quaternion3D, Null<Quaternion3D>) -> Quaternion3D,
			message:String):Quaternion3D {
		var x = copy(a), y = copy(b);
		var result = op(x, y, null);
		check(result != x && result != y && identical(x, a) && identical(y, b), '$message: into a new rotation, its inputs unchanged');
		var given = new Quaternion3D(9, 9, 9, 9);
		check(op(copy(a), copy(b), given) == given && identical(given, result), '$message: into the one given');
		var source = copy(a);
		check(op(source, copy(b), source) == source && identical(source, result), '$message: into the first');
		var other = copy(b);
		check(op(copy(a), other, other) == other && identical(other, result), '$message: into the second');
		return result;
	}

	static function main():Void {
		var q = new Quaternion3D();
		check(is(q, [0, 0, 0, 1]), "made as the identity");
		check(is(new Quaternion3D(1, 2, 3, 4), [1, 2, 3, 4]), "made from four numbers, as they are");
		check(q.set(1, 2, 3, 4) == q && is(q, [1, 2, 3, 4]) && q.makeIdentity() == q && is(q, [0, 0, 0, 1]), "set and reset, returning itself");
		var b = new Quaternion3D().set(0, 0.6133608449762378, 0.6133608449762378, 0.49757104789172696);
		check(q.copyFrom(b) == q && identical(q, b) && q != b, "copied, returning itself");

		// Pinned: rotation matrices and Hamilton products in Python, apart from Haxe and Trig; and raymath's floats for the same inputs.
		var axis = Quaternion3D.fromAxisAngle(1, 2, 3, .7);
		check(is(axis, [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789]), "from an axis and an angle: pinned");
		check(is(axis, [0.0916432962, 0.183286592, 0.274929881, 0.939372838], 1e-6), "and raylib's QuaternionFromAxisAngle");
		check(is(Quaternion3D.fromAxisAngle(0, 0, 0, 2), [0, 0, 0, 1]), "an axis of length 0: the identity");
		var into = new Quaternion3D();
		check(Quaternion3D.fromAxisAngle(0, 1, 0, Math.PI, into) == into && is(into, [0, 1, 0, 0], 1e-15), "into the one given");
		check(at(Quaternion3D.fromAxisAngle(0, 0, 1, Math.PI / 2).transformPoint(1, 0, 0), 0, 1, 0, 1e-15),
			"a quarter turn around +z takes +x to +y, counterclockwise looking down the axis");

		var euler = Quaternion3D.fromEuler(.3, -1.1, 2);
		check(turnsAs(euler, [0.5037217006570683, -0.17203483724321522, 0.7515219958692853, 0.3897218915925781]), "from three turns: pinned");
		check(is(euler, [0.503721714, -0.17203483, 0.751522005, 0.38972187], 1e-6), "and raylib's QuaternionFromEuler");
		var steps = Quaternion3D.fromAxisAngle(1, 0, 0, .3).append(Quaternion3D.fromAxisAngle(0, 1, 0, -1.1)).append(Quaternion3D.fromAxisAngle(0, 0, 1, 2));
		check(is(euler, [steps.x, steps.y, steps.z, steps.w]), "around x, then y, then z, each the world's");
		check(Quaternion3D.fromEuler(.3, -1.1, 2, into) == into && identical(into, euler), "into the one given");
		var angles = euler.toEuler();
		check(at(angles, .3, -1.1, 2), "its turns back");
		check(at(angles, 0.300000012, -1.0999999, 1.99999988, 1e-6), "and raylib's QuaternionToEuler");
		for (turns in [[0., 0., 0.], [1.2, .4, -2.9], [-3, 1.5, .1], [2.5, -1.2, 3]]) {
			var back = Quaternion3D.fromEuler(turns[0], turns[1], turns[2]).toEuler();
			check(at(back, turns[0], turns[1], turns[2], 1e-12), 'its turns back: ${turns}');
		}
		var given = new Vector3D();
		check(euler.toEuler(given) == given && given.equals(angles), "its turns, into the vector given");
		for (yaw in [Math.PI / 2, -Math.PI / 2]) {
			var locked = Quaternion3D.fromEuler(.4, yaw, .3),
				back = locked.toEuler();
			var again = Quaternion3D.fromEuler(back.x, back.y, back.z);
			check(back.z == 0 && near(back.y, yaw, 1e-7) && turnsAs(again, [locked.x, locked.y, locked.z, locked.w], 1e-9),
				'yawed a quarter turn ($yaw): roll 0, the pitch the whole turn, the same rotation');
		}

		var look = Quaternion3D.fromLookRotation(1, 2, -3);
		check(turnsAs(look, [
			0.2746567483172059,
			-0.15385645171777007,
			0.044570654466371595,
			0.9481061752931875
		]), "facing a direction: pinned");
		var length = Math.sqrt(14);
		check(at(look.transformPoint(0, 0, -1), 1 / length, 2 / length, -3 / length), "-z turned to face it");
		check(near(look.transformPoint(1, 0, 0).y, 0)
			&& look.transformPoint(0, 1, 0).y > 0, "its right level, its up as near +y as it can be");
		var lookUp = Quaternion3D.fromLookRotation(1, 2, -3, 0, 0, 5);
		check(near(lookUp.transformPoint(1, 0, 0).z, 0) && lookUp.transformPoint(0, 1, 0).z > 0, "an up given");
		var down = Quaternion3D.fromLookRotation(0, -2, 0);
		check(at(down.transformPoint(0, 0, -1), 0, -1, 0) && at(down.transformPoint(0, 1, 0), 0, 0, -1),
			"facing straight down, up along it: its up -z, as a turn down from level gives");
		var upward = Quaternion3D.fromLookRotation(0, 3, 0, 0, -1, 0);
		check(at(upward.transformPoint(0, 0, -1), 0, 1, 0)
			&& at(upward.transformPoint(0, 1, 0), 0, 0, 1), "facing straight up: its up +z");
		var sideways = Quaternion3D.fromLookRotation(2, 0, 0, 4, 0, 0);
		check(at(sideways.transformPoint(0, 0, -1), 1, 0, 0)
			&& at(sideways.transformPoint(0, 1, 0), 0, 1, 0), "an up along the direction: +y");
		check(is(Quaternion3D.fromLookRotation(0, 0, 0, 1, 0, 0), [0, 0, 0, 1]), "a direction of length 0: the identity");
		check(Quaternion3D.fromLookRotation(1, 2, -3, 0, 1, 0, into) == into && identical(into, look), "into the one given");

		var from = new Vector3D(1, 2, 3), to = new Vector3D(-2, .5, 1);
		var between = Quaternion3D.fromBetween(from, to);
		check(is(between, [0.037134677664382006, -0.519885487301348, 0.334212098979438, 0.7852657949407709]), "between two directions: pinned");
		check(is(between, [0.0371346883, -0.51988548, 0.334212124, 0.785265863], 1e-6), "and raylib's QuaternionFromVector3ToVector3");
		var turned = between.transformPoint(from.x, from.y, from.z).normalize(),
			toward = to.normalize();
		check(turned.equals(toward, 1e-12), "the first turned onto the second");
		var opposite = Quaternion3D.fromBetween(new Vector3D(0, 0, -1), new Vector3D(0, 0, 2));
		check(turnsAs(opposite, [0, 1, 0, 0]), "opposite: a half turn around +y");
		var alongY = Quaternion3D.fromBetween(new Vector3D(0, 1, 0), new Vector3D(0, -1, 0));
		check(turnsAs(alongY, [1, 0, 0, 0]), "opposite along y: a half turn around +x");
		var slant = new Vector3D(1, -2, .5), back = slant.negate();
		check(Quaternion3D.fromBetween(slant, back).transformPoint(slant.x, slant.y, slant.z).equals(back, 1e-12), "opposite and slanted");
		check(is(Quaternion3D.fromBetween(from, from), [0, 0, 0, 1], 1e-15), "the same direction: the identity");
		check(is(Quaternion3D.fromBetween(new Vector3D(), to), [0, 0, 0, 1]), "a direction of length 0: the identity");
		check(Quaternion3D.fromBetween(from, to, into) == into && identical(into, between), "into the one given");

		var a = Quaternion3D.fromAxisAngle(1, 0, 0, .4);
		b = Quaternion3D.fromAxisAngle(0, 1, 1, 2.1);
		check(is(b, [0, 0.6133608449762378, 0.6133608449762378, 0.49757104789172696]), "the second sample: pinned");
		var rotation = Matrix3D.fromRotation(1, 2, 3, .7);
		check(turnsAs(Quaternion3D.fromMatrix(rotation), [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789]),
			"from a matrix: pinned");
		check(turnsAs(Quaternion3D.fromMatrix(rotation), [0.0916432887, 0.183286577, 0.274929851, 0.939372718], 1e-6), "and raylib's QuaternionFromMatrix");
		var placed = Matrix3D.fromScale(2, .5, 3).append(rotation).appendTranslation(4, -5, 6);
		check(turnsAs(Quaternion3D.fromMatrix(placed), [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789]),
			"from a matrix that scales and moves: its scale and translation ignored");
		var mirrored = Matrix3D.fromScale(-1, 1, 1).append(rotation);
		check(turnsAs(Quaternion3D.fromMatrix(mirrored), [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789]),
			"from one that mirrors: the mirror taken as its x's scale");
		for (made in [
			a,
			b,
			Quaternion3D.fromEuler(2.9, -.2, 1.4),
			Quaternion3D.fromAxisAngle(1, 1, -1, 3.1),
			new Quaternion3D(0, 0, 1, 0)
		])
			check(turnsAs(Quaternion3D.fromMatrix(made.toMatrix()), [made.x, made.y, made.z, made.w], 1e-14), "its matrix and back");
		check(Quaternion3D.fromMatrix(rotation, into) == into && turnsAs(into, [axis.x, axis.y, axis.z, axis.w]), "into the one given");

		// Blends, the shorter way round.
		check(is(Quaternion3D.slerp(a, b, .3), [
			0.15394140185900607,
			0.21994717005755543,
			0.21994717005755543,
			0.9378424865407994
		]), "slerp: pinned");
		check(is(Quaternion3D.slerp(a, b, .3), [0.153941393, 0.219947159, 0.219947159, 0.937842488], 1e-6), "and raylib's QuaternionSlerp");
		check(is(Quaternion3D.slerp(a, b, 1.5), [
			-0.11517680995889118,
			0.7024000603238816,
			0.7024000603238814,
			0.001616465808111072
		]), "slerp past its end: pinned");
		check(is(Quaternion3D.slerp(a, b, 0), [a.x, a.y, a.z, a.w])
			&& is(Quaternion3D.slerp(a, b, 1), [b.x, b.y, b.z, b.w]), "slerp at 0 and 1: its ends");
		var negated = new Quaternion3D(-b.x, -b.y, -b.z, -b.w);
		check(identical(Quaternion3D.slerp(a, negated, .3), Quaternion3D.slerp(a, b, .3)), "slerp to the same rotation's other sign: the same arc");
		var whole = Quaternion3D.compose(a.invert(), b).angle;
		for (amount in [.1, .25, .5, .8])
			check(near(Quaternion3D.compose(a.invert(), Quaternion3D.slerp(a, b, amount)).angle, whole * amount),
				'slerp at an even speed: $amount of the way, that much of the angle');
		var close = Quaternion3D.fromAxisAngle(1, 0, 0, .4 + 1e-10);
		var mid = Quaternion3D.slerp(a, close, .5);
		check(near(mid.angle, .4 + 5e-11, 1e-15) && near(mid.x * mid.x + mid.y * mid.y + mid.z * mid.z + mid.w * mid.w, 1, 1e-15),
			"slerp between rotations nearly the same: halfway, of length 1");
		check(is(Quaternion3D.nlerp(a, b, .3), [0.15698040843580244, 0.2077083180901007, 0.2077083180901007, 0.9429059659158445]), "nlerp: pinned");
		check(is(Quaternion3D.nlerp(a, b, .3), [0.156980395, 0.207708299, 0.207708299, 0.942905962], 1e-6), "and raylib's QuaternionNlerp");
		check(identical(Quaternion3D.nlerp(a, negated, .3), Quaternion3D.nlerp(a, b, .3)), "nlerp to the other sign: the same arc");

		// Composition and order.
		var composed = Quaternion3D.compose(a, b);
		check(turnsAs(composed, [0.09885210710764675, 0.722990452924996, 0.4792784757103512, 0.48765275414012527]), "composed: pinned");
		check(is(composed, [0.0988521129, 0.722990453, 0.479278505, 0.487652808], 1e-6), "and raylib's QuaternionMultiply, second times first");
		var p = new Vector3D(1.5, -2, .25);
		var stepwise = a.transformPoint(p.x, p.y, p.z);
		stepwise = b.transformPoint(stepwise.x, stepwise.y, stepwise.z);
		check(composed.transformPoint(p.x, p.y, p.z).equals(stepwise, 1e-14), "composed: the first turn, then the second");
		check(identical(a.append(b), composed) && identical(b.prepend(a), composed), "append and prepend compose in order");
		check(is(Quaternion3D.compose(b, b.invert()), [0, 0, 0, 1], 1e-15), "followed by its inverse, the identity");
		check(is(b.invert(), [0, -0.613360822, -0.613360822, 0.497571081], 1e-6), "inverted: raylib's QuaternionInvert");
		check(is(new Quaternion3D(1, 2, 3, 4).normalize(), [0.18257418583505536, 0.3651483716701107, 0.5477225575051661, 0.7302967433402214]),
			"normalized: pinned");
		check(is(new Quaternion3D(0, 0, 0, 0).normalize(), [0, 0, 0, 1]), "normalized from length 0: the identity");

		check(at(b.transformPoint(1.5, -2, .25), 0.6160885357678314, 0.6085236627865849, -2.3585236627865847), "a point turned: pinned");
		check(at(b.transformPoint(1.5, -2, .25), 0.616088688, 0.608523607, -2.35852361, 1e-6), "and raylib's Vector3RotateByQuaternion");
		check(b.transformPoint(1.5, -2, .25, given) == given && at(given, 0.6160885357678314, 0.6085236627865849, -2.3585236627865847),
			"a point turned, into the vector given");
		var m = b.toMatrix().values;
		var pinned = [
			-0.5048461045998576, 0.6103811967411634, -0.6103811967411634, 0, -0.6103811967411634, 0.24757694770007121, 0.7524230522999288, 0,
			 0.6103811967411634, 0.7524230522999288, 0.24757694770007121, 0,                   0,                   0,                  0, 1
		];
		check([for (i in 0...16) near(m[i], pinned[i])].indexOf(false) < 0, "its matrix: pinned, and raylib's QuaternionToMatrix");
		var matrix = new Matrix3D();
		check(b.toMatrix(matrix) == matrix && matrix.transformPoint(1.5, -2, .25).equals(b.transformPoint(1.5, -2, .25), 1e-15),
			"its matrix, into the one given, turning as it does");
		check(near(Quaternion3D.fromAxisAngle(3, -1, 2, 2.5).angle, 2.5)
			&& near(Quaternion3D.fromAxisAngle(3, -1, 2, 4).angle, Math.PI * 2 - 4)
			&& near(negated.angle, b.angle)
			&& new Quaternion3D().angle == 0,
			"its angle, 0 to pi, either sign alike");

		// Each operation into a new rotation (its inputs unchanged), into the one given, and into each argument: the same each way.
		threeWays(a, b, (x, y, out) -> Quaternion3D.slerp(x, y, .3, out), "slerp");
		threeWays(a, b, (x, y, out) -> Quaternion3D.slerp(x, y, -.4, out), "slerp before its start");
		threeWays(a, close, (x, y, out) -> Quaternion3D.slerp(x, y, .3, out), "slerp, nearly the same");
		threeWays(a, b, (x, y, out) -> Quaternion3D.nlerp(x, y, .3, out), "nlerp");
		threeWays(a, b, (x, y, out) -> Quaternion3D.compose(x, y, out), "compose");
		threeWays(a, b, (x, y, out) -> x.append(y, out), "append");
		threeWays(a, b, (x, y, out) -> x.prepend(y, out), "prepend");
		threeWays(b, a, (x, y, out) -> x.invert(out), "invert");
		threeWays(new Quaternion3D(1, 2, 3, 4), a, (x, y, out) -> x.normalize(out), "normalize");
		var twice = copy(b);
		check(Quaternion3D.compose(twice, twice, twice) == twice
			&& is(twice, [composedSelf(b).x, composedSelf(b).y, composedSelf(b).z, composedSelf(b).w]),
			"composed with itself on both sides, into itself");

		// The interpreter multiplies Ints passed for Floats as Ints; whole numbers this large must still multiply as floats.
		var large = new Quaternion3D(100000, 0, 0, 100000);
		check(Quaternion3D.compose(large, large).w == 0
			&& Quaternion3D.compose(large, large).x == 2e10, "large whole numbers multiplied as floats");
		check(new Quaternion3D(0, 0, 0, 1).transformPoint(100000, 100000, 0).x == 100000, "and turned as floats");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// b composed with itself, worked by the product's formula apart from compose.
	static function composedSelf(b:Quaternion3D):Quaternion3D
		return new Quaternion3D(2 * b.w * b.x, 2 * b.w * b.y, 2 * b.w * b.z, b.w * b.w - b.x * b.x - b.y * b.y - b.z * b.z);
}
