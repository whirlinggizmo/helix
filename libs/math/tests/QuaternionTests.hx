import helix.math.EulerOrder;
import helix.math.Matrix4;
import helix.math.Quaternion;
import helix.math.Vector3;

/** Checks Quaternion with the library alone: made, set, copied and reset, each returning itself; made from an axis and an angle, from
	three turns, facing a direction, between two directions and from a matrix; blended (slerp and nlerp, the shorter way round, slerp at an
	even speed and past its ends), composed in order, inverted and normalized; points turned, its angle, its matrix and its turns back;
	values pinned to rotation matrices and Hamilton products computed apart from Haxe, and to raylib 5.5's raymath for the same inputs (to
	its float precision); every operation into a new rotation, itself and each other argument, the same each way; whole numbers multiplied
	as floats on the interpreter; its length; the same rotation as its negative; its axis, which with `angle` makes the rotation again; a
	Hermite curve; a copy; a rotation written in braces; its dot product with another, the angle to another and turned toward another by a
	step; and three turns made in each of the six orders and read back, at the lock too. */
class QuaternionTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) < tolerance;

	static function is(q:Quaternion, values:Array<Float>, tolerance = 1e-12):Bool
		return near(q.x, values[0], tolerance) && near(q.y, values[1], tolerance) && near(q.z, values[2], tolerance) && near(q.w, values[3], tolerance);

	// The same rotation: q or -q.
	static function turnsAs(q:Quaternion, values:Array<Float>, tolerance = 1e-12):Bool
		return is(q, values, tolerance) || is(q, [-values[0], -values[1], -values[2], -values[3]], tolerance);

	static function at(p:Vector3, x:Float, y:Float, z:Float, tolerance = 1e-12):Bool
		return near(p.x, x, tolerance) && near(p.y, y, tolerance) && near(p.z, z, tolerance);

	static function identical(a:Quaternion, b:Quaternion):Bool
		return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;

	static function copy(q:Quaternion):Quaternion
		return new Quaternion().copyFrom(q);

	// Runs an operation of a and b into a new rotation, into a and into b: the same result each way, its inputs untouched without an out.
	static function threeWays(a:Quaternion, b:Quaternion, op:(Quaternion, Quaternion, Null<Quaternion>) -> Quaternion, message:String):Quaternion {
		var x = copy(a), y = copy(b);
		var result = op(x, y, null);
		check(result != x && result != y && identical(x, a) && identical(y, b), '$message: into a new rotation, its inputs unchanged');
		var given = new Quaternion(9, 9, 9, 9);
		check(op(copy(a), copy(b), given) == given && identical(given, result), '$message: into the one provided');
		var source = copy(a);
		check(op(source, copy(b), source) == source && identical(source, result), '$message: into the first');
		var other = copy(b);
		check(op(copy(a), other, other) == other && identical(other, result), '$message: into the second');
		return result;
	}

	static function main():Void {
		var q = new Quaternion();
		check(is(q, [0, 0, 0, 1]), "made as the identity");
		check(is(new Quaternion(1, 2, 3, 4), [1, 2, 3, 4]), "made from four numbers, as they are");
		check(q.set(1, 2, 3, 4) == q && is(q, [1, 2, 3, 4]) && q.makeIdentity() == q && is(q, [0, 0, 0, 1]), "set and reset, returning itself");
		var b = new Quaternion().set(0, 0.6133608449762378, 0.6133608449762378, 0.49757104789172696);
		check(q.copyFrom(b) == q && identical(q, b) && q != b, "copied, returning itself");

		// Pinned: rotation matrices and Hamilton products in Python, apart from Haxe and Trig; and raymath's floats for the same inputs.
		var axis = Quaternion.fromAxisAngle(1, 2, 3, .7);
		check(is(axis, [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789]), "from an axis and an angle: pinned");
		check(is(axis, [0.0916432962, 0.183286592, 0.274929881, 0.939372838], 1e-6), "and raylib's QuaternionFromAxisAngle");
		check(is(Quaternion.fromAxisAngle(0, 0, 0, 2), [0, 0, 0, 1]), "an axis of length 0: the identity");
		var into = new Quaternion();
		check(Quaternion.fromAxisAngle(0, 1, 0, Math.PI, into) == into && is(into, [0, 1, 0, 0], 1e-15), "into the one provided");
		check(at(Quaternion.fromAxisAngle(0, 0, 1, Math.PI / 2).transformPoint(1, 0, 0), 0, 1, 0, 1e-15),
			"a quarter turn around +z turns +x to +y, counterclockwise looking down the axis");

		var euler = Quaternion.fromEuler(.3, -1.1, 2);
		check(turnsAs(euler, [0.5037217006570683, -0.17203483724321522, 0.7515219958692853, 0.3897218915925781]), "from three turns: pinned");
		check(is(euler, [0.503721714, -0.17203483, 0.751522005, 0.38972187], 1e-6), "and raylib's QuaternionFromEuler");
		var steps = Quaternion.fromAxisAngle(1, 0, 0, .3).append(Quaternion.fromAxisAngle(0, 1, 0, -1.1)).append(Quaternion.fromAxisAngle(0, 0, 1, 2));
		check(is(euler, [steps.x, steps.y, steps.z, steps.w]), "around x, then y, then z, each the world's");
		check(Quaternion.fromEuler(.3, -1.1, 2, ZYX, into) == into && identical(into, euler), "into the one provided");
		var angles = euler.toEuler();
		check(at(angles, .3, -1.1, 2), "its turns back");
		check(at(angles, 0.300000012, -1.0999999, 1.99999988, 1e-6), "and raylib's QuaternionToEuler");
		for (turns in [[0., 0., 0.], [1.2, .4, -2.9], [-3, 1.5, .1], [2.5, -1.2, 3]]) {
			var back = Quaternion.fromEuler(turns[0], turns[1], turns[2]).toEuler();
			check(at(back, turns[0], turns[1], turns[2], 1e-12), 'its turns back: ${turns}');
		}
		var given = new Vector3();
		check(euler.toEuler(ZYX, given) == given && given.equals(angles), "its turns, into the vector provided");
		for (yaw in [Math.PI / 2, -Math.PI / 2]) {
			var locked = Quaternion.fromEuler(.4, yaw, .3),
				back = locked.toEuler();
			var again = Quaternion.fromEuler(back.x, back.y, back.z);
			check(back.z == 0 && near(back.y, yaw, 1e-7) && turnsAs(again, [locked.x, locked.y, locked.z, locked.w], 1e-9),
				'yawed a quarter turn ($yaw): roll 0, the pitch the whole turn, the same rotation');
		}

		var look = Quaternion.fromLookRotation(1, 2, -3);
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
		var lookUp = Quaternion.fromLookRotation(1, 2, -3, 0, 0, 5);
		check(near(lookUp.transformPoint(1, 0, 0).z, 0) && lookUp.transformPoint(0, 1, 0).z > 0, "an up provided");
		var down = Quaternion.fromLookRotation(0, -2, 0);
		check(at(down.transformPoint(0, 0, -1), 0, -1, 0) && at(down.transformPoint(0, 1, 0), 0, 0, -1),
			"facing straight down, up along it: its up -z, as a turn down from level produces");
		var upward = Quaternion.fromLookRotation(0, 3, 0, 0, -1, 0);
		check(at(upward.transformPoint(0, 0, -1), 0, 1, 0)
			&& at(upward.transformPoint(0, 1, 0), 0, 0, 1), "facing straight up: its up +z");
		var sideways = Quaternion.fromLookRotation(2, 0, 0, 4, 0, 0);
		check(at(sideways.transformPoint(0, 0, -1), 1, 0, 0)
			&& at(sideways.transformPoint(0, 1, 0), 0, 1, 0), "an up along the direction: +y");
		check(is(Quaternion.fromLookRotation(0, 0, 0, 1, 0, 0), [0, 0, 0, 1]), "a direction of length 0: the identity");
		check(Quaternion.fromLookRotation(1, 2, -3, 0, 1, 0, into) == into && identical(into, look), "into the one provided");

		var from = new Vector3(1, 2, 3), to = new Vector3(-2, .5, 1);
		var between = Quaternion.fromBetween(from, to);
		check(is(between, [0.037134677664382006, -0.519885487301348, 0.334212098979438, 0.7852657949407709]), "between two directions: pinned");
		check(is(between, [0.0371346883, -0.51988548, 0.334212124, 0.785265863], 1e-6), "and raylib's QuaternionFromVector3ToVector3");
		var turned = between.transformPoint(from.x, from.y, from.z).normalize(),
			toward = to.normalize();
		check(turned.equals(toward, 1e-12), "the first turned onto the second");
		var opposite = Quaternion.fromBetween(new Vector3(0, 0, -1), new Vector3(0, 0, 2));
		check(turnsAs(opposite, [0, 1, 0, 0]), "opposite: a half turn around +y");
		var alongY = Quaternion.fromBetween(new Vector3(0, 1, 0), new Vector3(0, -1, 0));
		check(turnsAs(alongY, [1, 0, 0, 0]), "opposite along y: a half turn around +x");
		var slant = new Vector3(1, -2, .5), back = slant.negate();
		check(Quaternion.fromBetween(slant, back).transformPoint(slant.x, slant.y, slant.z).equals(back, 1e-12), "opposite and slanted");
		check(is(Quaternion.fromBetween(from, from), [0, 0, 0, 1], 1e-15), "the same direction: the identity");
		check(is(Quaternion.fromBetween(new Vector3(), to), [0, 0, 0, 1]), "a direction of length 0: the identity");
		check(Quaternion.fromBetween(from, to, into) == into && identical(into, between), "into the one provided");

		var a = Quaternion.fromAxisAngle(1, 0, 0, .4);
		b = Quaternion.fromAxisAngle(0, 1, 1, 2.1);
		check(is(b, [0, 0.6133608449762378, 0.6133608449762378, 0.49757104789172696]), "the second sample: pinned");
		var rotation = Matrix4.fromRotation(1, 2, 3, .7);
		check(turnsAs(Quaternion.fromRotationMatrix(rotation), [0.0916432887, 0.183286577, 0.274929851, 0.939372718], 1e-6),
			"from a rotation matrix: raylib's QuaternionFromMatrix");
		check(is(Quaternion.fromRotationMatrix(rotation), [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789], 1e-15),
			"from a rotation matrix: pinned");
		check(Quaternion.fromRotationMatrix(rotation, into) == into
			&& identical(into, Quaternion.fromRotationMatrix(rotation)), "into the one provided");
		for (turn in [
			Matrix4.fromRotation(1, 0, 0, 3),
			Matrix4.fromRotation(0, 1, 0, 3),
			Matrix4.fromRotation(0, 0, 1, 3)
		]) {
			var scaled = turn.getRotation();
			check(turnsAs(Quaternion.fromRotationMatrix(turn), [scaled.x, scaled.y, scaled.z, scaled.w], 1e-15),
				"a turn near half about each axis: as the matrix's getRotation");
		}
		var placed = Matrix4.fromScale(2, .5, 3).append(rotation).appendTranslation(4, -5, 6);
		check(turnsAs(placed.getRotation(), [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789]),
			"the rotation of a matrix that scales and moves: its scale and translation left out");
		var mirrored = Matrix4.fromScale(-1, 1, 1).append(rotation);
		check(turnsAs(mirrored.getRotation(), [0.0916432938695913, 0.1832865877391826, 0.2749298816087739, 0.9393727128473789]),
			"the rotation of one that mirrors: the mirror read as its x's scale");
		for (made in [
			a,
			b,
			Quaternion.fromEuler(2.9, -.2, 1.4),
			Quaternion.fromAxisAngle(1, 1, -1, 3.1),
			new Quaternion(0, 0, 1, 0)
		])
			check(turnsAs(Quaternion.fromRotationMatrix(made.toMatrix()), [made.x, made.y, made.z, made.w], 1e-14)
				&& turnsAs(made.toMatrix().getRotation(), [made.x, made.y, made.z, made.w], 1e-14),
				"its matrix and back");
		check(rotation.getRotation(into) == into
			&& turnsAs(into, [axis.x, axis.y, axis.z, axis.w]), "a matrix's rotation into the one provided");

		// Blends, the shorter way round.
		check(is(Quaternion.slerp(a, b, .3), [
			0.15394140185900607,
			0.21994717005755543,
			0.21994717005755543,
			0.9378424865407994
		]), "slerp: pinned");
		check(is(Quaternion.slerp(a, b, .3), [0.153941393, 0.219947159, 0.219947159, 0.937842488], 1e-6), "and raylib's QuaternionSlerp");
		check(is(Quaternion.slerp(a, b, 1.5), [
			-0.11517680995889118,
			0.7024000603238816,
			0.7024000603238814,
			0.001616465808111072
		]), "slerp past its end: pinned");
		check(is(Quaternion.slerp(a, b, 0), [a.x, a.y, a.z, a.w])
			&& is(Quaternion.slerp(a, b, 1), [b.x, b.y, b.z, b.w]), "slerp at 0 and 1: its ends");
		var negated = new Quaternion(-b.x, -b.y, -b.z, -b.w);
		check(identical(Quaternion.slerp(a, negated, .3), Quaternion.slerp(a, b, .3)), "slerp to the same rotation's other sign: the same arc");
		var whole = Quaternion.compose(a.invert(), b).angle;
		for (amount in [.1, .25, .5, .8])
			check(near(Quaternion.compose(a.invert(), Quaternion.slerp(a, b, amount)).angle, whole * amount),
				'slerp at an even speed: $amount of the way, that much of the angle');
		var close = Quaternion.fromAxisAngle(1, 0, 0, .4 + 1e-10);
		var mid = Quaternion.slerp(a, close, .5);
		check(near(mid.angle, .4 + 5e-11, 1e-15) && near(mid.x * mid.x + mid.y * mid.y + mid.z * mid.z + mid.w * mid.w, 1, 1e-15),
			"slerp between rotations nearly the same: halfway, of length 1");
		check(is(Quaternion.nlerp(a, b, .3), [0.15698040843580244, 0.2077083180901007, 0.2077083180901007, 0.9429059659158445]), "nlerp: pinned");
		check(is(Quaternion.nlerp(a, b, .3), [0.156980395, 0.207708299, 0.207708299, 0.942905962], 1e-6), "and raylib's QuaternionNlerp");
		check(identical(Quaternion.nlerp(a, negated, .3), Quaternion.nlerp(a, b, .3)), "nlerp to the other sign: the same arc");

		// Composition and order.
		var composed = Quaternion.compose(a, b);
		check(turnsAs(composed, [0.09885210710764675, 0.722990452924996, 0.4792784757103512, 0.48765275414012527]), "composed: pinned");
		check(is(composed, [0.0988521129, 0.722990453, 0.479278505, 0.487652808], 1e-6), "and raylib's QuaternionMultiply, second times first");
		var p = new Vector3(1.5, -2, .25);
		var stepwise = a.transformPoint(p.x, p.y, p.z);
		stepwise = b.transformPoint(stepwise.x, stepwise.y, stepwise.z);
		check(composed.transformPoint(p.x, p.y, p.z).equals(stepwise, 1e-14), "composed: the first turn, then the second");
		check(identical(a.append(b), composed) && identical(b.prepend(a), composed), "append and prepend compose in order");
		check(is(Quaternion.compose(b, b.invert()), [0, 0, 0, 1], 1e-15), "followed by its inverse, the identity");
		check(is(b.invert(), [0, -0.613360822, -0.613360822, 0.497571081], 1e-6), "inverted: raylib's QuaternionInvert");
		check(is(new Quaternion(1, 2, 3, 4).normalize(), [0.18257418583505536, 0.3651483716701107, 0.5477225575051661, 0.7302967433402214]),
			"normalized: pinned");
		check(is(new Quaternion(0, 0, 0, 0).normalize(), [0, 0, 0, 1]), "normalized from length 0: the identity");

		check(at(b.transformPoint(1.5, -2, .25), 0.6160885357678314, 0.6085236627865849, -2.3585236627865847), "a point turned: pinned");
		check(at(b.transformPoint(1.5, -2, .25), 0.616088688, 0.608523607, -2.35852361, 1e-6), "and raylib's Vector3RotateByQuaternion");
		check(b.transformPoint(1.5, -2, .25, given) == given && at(given, 0.6160885357678314, 0.6085236627865849, -2.3585236627865847),
			"a point turned, into the vector provided");
		var m = b.toMatrix().toArray();
		var pinned = [
			-0.5048461045998576, 0.6103811967411634, -0.6103811967411634, 0, -0.6103811967411634, 0.24757694770007121, 0.7524230522999288, 0,
			 0.6103811967411634, 0.7524230522999288, 0.24757694770007121, 0,                   0,                   0,                  0, 1
		];
		check([for (i in 0...16) near(m[i], pinned[i])].indexOf(false) < 0, "its matrix: pinned, and raylib's QuaternionToMatrix");
		var matrix = new Matrix4();
		check(b.toMatrix(matrix) == matrix && matrix.transformPoint(1.5, -2, .25).equals(b.transformPoint(1.5, -2, .25), 1e-15),
			"its matrix, into the one provided, turning as it does");
		check(near(Quaternion.fromAxisAngle(3, -1, 2, 2.5).angle, 2.5)
			&& near(Quaternion.fromAxisAngle(3, -1, 2, 4).angle, Math.PI * 2 - 4)
			&& near(negated.angle, b.angle)
			&& new Quaternion().angle == 0,
			"its angle, 0 to pi, either sign alike");

		// Each operation into a new rotation (its inputs unchanged), into the one provided, and into each argument: the same each way.
		threeWays(a, b, (x, y, out) -> Quaternion.slerp(x, y, .3, out), "slerp");
		threeWays(a, b, (x, y, out) -> Quaternion.slerp(x, y, -.4, out), "slerp before its start");
		threeWays(a, close, (x, y, out) -> Quaternion.slerp(x, y, .3, out), "slerp, nearly the same");
		threeWays(a, b, (x, y, out) -> Quaternion.nlerp(x, y, .3, out), "nlerp");
		threeWays(a, b, (x, y, out) -> Quaternion.compose(x, y, out), "compose");
		threeWays(a, b, (x, y, out) -> x.append(y, out), "append");
		threeWays(a, b, (x, y, out) -> x.prepend(y, out), "prepend");
		threeWays(b, a, (x, y, out) -> x.invert(out), "invert");
		threeWays(new Quaternion(1, 2, 3, 4), a, (x, y, out) -> x.normalize(out), "normalize");
		var twice = copy(b);
		check(Quaternion.compose(twice, twice, twice) == twice
			&& is(twice, [composedSelf(b).x, composedSelf(b).y, composedSelf(b).z, composedSelf(b).w]),
			"composed with itself on both sides, into itself");

		// The interpreter multiplies Ints passed for Floats as Ints; whole numbers this large must still multiply as floats.
		var large = new Quaternion(100000, 0, 0, 100000);
		check(Quaternion.compose(large, large).w == 0
			&& Quaternion.compose(large, large).x == 2e10, "large whole numbers multiplied as floats");
		check(new Quaternion(0, 0, 0, 1).transformPoint(100000, 100000, 0).x == 100000, "and turned as floats");

		// Its length, and the same rotation as its negative, within a tolerance.
		check(new Quaternion().length == 1
			&& new Quaternion(1, 2, 2, 4).length == 5 && near(Quaternion.fromAxisAngle(3, -1, 2, 2.5).length, 1), "its length");
		var turn = Quaternion.fromAxisAngle(3, -1, 2, 2.5);
		var opposite = new Quaternion(-turn.x, -turn.y, -turn.z, -turn.w);
		check(turn.equals(turn) && turn.equals(opposite) && !turn.equals(new Quaternion()) && !turn.equals(turn.invert()), "equal to itself and its negative");
		check(!turn.equals(new Quaternion(turn.x + 1e-7, turn.y, turn.z, turn.w))
			&& turn.equals(new Quaternion(turn.x + 1e-7, turn.y, turn.z, turn.w), 1e-6)
			&& turn.equals(new Quaternion(-turn.x - 1e-7, -turn.y, -turn.z, -turn.w), 1e-6)
			&& !turn.equals(new Quaternion(-turn.x, turn.y, turn.z, turn.w), 1e-6),
			"equal within a tolerance, negated or not, and not when one number alone is negated");

		// Its axis: of length 1, the x axis for no turn, and with `angle` the rotation again, whichever of the two quaternions holds it.
		var axisOut = new Vector3();
		check(at(new Quaternion().getAxis(), 1, 0, 0)
			&& at(Quaternion.fromAxisAngle(0, 0, 2, 1).getAxis(), 0, 0, 1)
			&& turn.getAxis(axisOut) == axisOut
			&& near(axisOut.length, 1),
			"its axis: of length 1, the x axis for no turn, into an out");
		for (angle in [.3, 2.5, 3.5, 4, 6]) {
			for (q in [
				Quaternion.fromAxisAngle(3, -1, 2, angle),
				Quaternion.fromAxisAngle(-3, 1, -2, -angle)
			]) {
				var negated = new Quaternion(-q.x, -q.y, -q.z, -q.w);
				for (held in [q, negated]) {
					var axis = held.getAxis();
					var again = Quaternion.fromAxisAngle(axis.x, axis.y, axis.z, held.angle);
					check(near(axis.length, 1) && turnsAs(again, [q.x, q.y, q.z, q.w], 1e-9) && held.angle <= Math.PI,
						'its axis and angle make the rotation of $angle again, the angle at most half a turn');
				}
			}
		}

		// A Hermite curve: its ends, of length 1 between, and into any argument.
		var hFrom = Quaternion.fromAxisAngle(0, 1, 0, .4),
			hTo = Quaternion.fromAxisAngle(1, 0, 0, 1.2);
		var leaving = new Quaternion(.1, .3, 0, -.2),
			arriving = new Quaternion(0, -.4, .2, .1);
		check(is(Quaternion.hermite(hFrom, leaving, hTo, arriving, 0), [hFrom.x, hFrom.y, hFrom.z, hFrom.w])
			&& is(Quaternion.hermite(hFrom, leaving, hTo, arriving, 1), [hTo.x, hTo.y, hTo.z, hTo.w]),
			"Hermite: its ends");
		var between = Quaternion.hermite(hFrom, leaving, hTo, arriving, .5);
		var plainX = .5 * hFrom.x + .125 * leaving.x + .5 * hTo.x - .125 * arriving.x,
			plainW = .5 * hFrom.w + .125 * leaving.w + .5 * hTo.w - .125 * arriving.w;
		check(near(between.length, 1)
			&& near(between.x / between.w, plainX / plainW), "Hermite halfway: the curve's four weights, made of length 1");
		for (into in 0...4) {
			var args = [copy(hFrom), copy(leaving), copy(hTo), copy(arriving)];
			check(Quaternion.hermite(args[0], args[1], args[2], args[3], .5, args[into]) == args[into] && identical(args[into], between),
				'Hermite into argument $into');
		}

		// A copy is a separate rotation, or the out filled; and a rotation written in braces, a number left out 0.
		var copied = turn.copy(), copyOut = new Quaternion();
		copied.x = 9;
		check(turn.x != 9 && copied.w == turn.w && turn.copy(copyOut) == copyOut && identical(copyOut, turn), "a copy is separate, or the out filled");
		var braced:Quaternion = {
			x: 0,
			y: 0,
			z: 0,
			w: 1
		}, partly:Quaternion = {y: 1};
		check(is(braced, [0, 0, 0, 1]) && partly.y == 1 && partly.x == 0, "a rotation in braces");

		// The dot product, the angle between two rotations, and a turn toward one by a step.
		var yawA = Quaternion.fromAxisAngle(0, 1, 0, .3),
			yawB = Quaternion.fromAxisAngle(0, 1, 0, 1.5);
		check(near(yawA.dot(yawA), 1) && near(yawA.dot(yawB), Math.cos(.6)), "the dot product: the cosine of half the angle between");
		check(near(new Quaternion(1, 0, 0, 0).dot(new Quaternion(0, 0, 0, 1)), 0), "rotations half a turn apart: a dot product of 0");
		check(near(yawA.angleTo(yawB), 1.2) && near(yawB.angleTo(yawA), 1.2), "the angle between two turns around one axis, either way round");
		check(yawA.angleTo(yawA) == 0, "no angle to itself");
		check(near(yawA.angleTo(new Quaternion(-yawB.x, -yawB.y, -yawB.z, -yawB.w)), 1.2), "a quaternion's negative is the same rotation");
		check(near(new Quaternion().angleTo(Quaternion.fromAxisAngle(1, 0, 0, Math.PI)), Math.PI), "half a turn apart: pi");
		check(near(new Quaternion().angleTo(Quaternion.fromAxisAngle(0, 0, 1, 1e-9)), 1e-9, 1e-21), "the smallest angles kept");
		check(near(Quaternion.fromAxisAngle(1, 0, 0, .4).angleTo(Quaternion.fromAxisAngle(0, 1, 0, .9)), 0.9792975059130261),
			"turns around two axes: pinned, worked in Python from the dot product");
		var turned = threeWays(yawA, yawB, (a, b, out) -> a.rotateToward(b, .5, out), "turned toward");
		check(turnsAs(turned, [0, Math.sin(.4), 0, Math.cos(.4)]), "turned toward a target by a step");
		check(near(turned.angleTo(yawA), .5) && near(turned.angleTo(yawB), .7), "a step nearer the target and no more");
		check(identical(yawA.rotateToward(yawB, 1.2000001), yawB)
			&& identical(yawA.rotateToward(yawB, 9), yawB), "a step past the target: the target exactly");
		check(identical(yawA.rotateToward(yawB, 0), yawA)
			&& identical(yawA.rotateToward(yawB, -1), yawA)
			&& identical(yawA.rotateToward(yawB, Math.NaN), yawA),
			"a step of 0 or less: left as it is");
		var far = Quaternion.fromAxisAngle(0, 1, 0, .3 + 4);
		check(near(yawA.rotateToward(far, .5).angleTo(far), 2 * Math.PI - 4 - .5), "the short way round");
		var chase = copy(yawA), steps = 0;
		while (!identical(chase, yawB) && steps < 100) {
			chase.rotateToward(yawB, .25, chase);
			steps++;
		}
		check(steps == 5, "stepped to the target in as many steps as the angle holds");

		// Three turns in each order, and the turns read back.
		var orders:Array<EulerOrder> = [ZYX, XYZ, YXZ, ZXY, YZX, XZY];
		// Which of pitch, yaw and roll is made second in each order, and which last.
		var seconds = [1, 1, 0, 0, 2, 2], lasts = [2, 0, 1, 2, 1, 0];
		var names = ["ZYX", "XYZ", "YXZ", "ZXY", "YZX", "XZY"];
		for (index => order in orders) {
			var name = names[index];
			for (turns in [[.3, -.7, 1.1], [-2.9, 1.2, 3], [1.4, -1.5, -.4], [0., 0., 0.]]) {
				// The second turn is read back from -pi / 2 to pi / 2: the sample's is within that already.
				var made = Quaternion.fromEuler(turns[0], turns[1], turns[2], order);
				var back = made.toEuler(order);
				check(turnsAs(Quaternion.fromEuler(back.x, back.y, back.z, order), [made.x, made.y, made.z, made.w]),
					'the order $name: the turns read back make the rotation again');
			}
			var back = Quaternion.fromEuler(.3, -.7, 1.1, order).toEuler(order);
			check(at(back, .3, -.7, 1.1), 'the order $name: turns within the ranges read back as provided');
			for (quarter in [Math.PI / 2, -Math.PI / 2]) {
				var turns = [.4, .9, .3];
				turns[seconds[index]] = quarter;
				var locked = Quaternion.fromEuler(turns[0], turns[1], turns[2], order);
				var back = locked.toEuler(order),
					read = [back.x, back.y, back.z];
				check(read[lasts[index]] == 0
					&& near(read[seconds[index]], quarter, 1e-7)
					&& turnsAs(Quaternion.fromEuler(back.x, back.y, back.z, order), [locked.x, locked.y, locked.z, locked.w], 1e-7),
					'the order $name, its second turn a quarter turn: the last turn 0, the first carrying the whole turn');
			}
		}
		check(identical(Quaternion.fromEuler(.3, -1.1, 2), Quaternion.fromEuler(.3, -1.1, 2, ZYX)), "no order provided: x, then y, then z");
		var first = Quaternion.fromAxisAngle(0, 0, 1, 1.1),
			then = Quaternion.fromAxisAngle(0, 1, 0, -.7),
			last = Quaternion.fromAxisAngle(1, 0, 0, .3);
		check(turnsAs(Quaternion.fromEuler(.3, -.7, 1.1, XYZ), {
			var q = Quaternion.compose(Quaternion.compose(first, then), last);
			[q.x, q.y, q.z, q.w];
		}), "XYZ: around z first, then y, then x");
		var ordered = new Quaternion(9, 9, 9, 9);
		check(Quaternion.fromEuler(.3, -.7, 1.1, YXZ, ordered) == ordered && identical(ordered, Quaternion.fromEuler(.3, -.7, 1.1, YXZ)),
			"an order, into the one provided");
		var readInto = new Vector3();
		check(ordered.toEuler(YXZ, readInto) == readInto && at(readInto, .3, -.7, 1.1), "an order's turns, into the vector provided");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}

	// b composed with itself, worked by the product's formula apart from compose.
	static function composedSelf(b:Quaternion):Quaternion
		return new Quaternion(2 * b.w * b.x, 2 * b.w * b.y, 2 * b.w * b.z, b.w * b.w - b.x * b.x - b.y * b.y - b.z * b.z);
}
