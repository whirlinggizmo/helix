import helix.math.Matrix3D;
import helix.math.Quaternion3D;
import helix.math.Transform3D;
import helix.math.Vector3D;

/** Checks Transform3D with the library alone: made, copied and reset, each returning itself; its forward, right and up; moved along
	them, along the ground and toward a point (stopping short of it); turned around its own axes, the pitch locked short of straight up
	and down, turned to face a point and swung around one; points carried and its matrix, pinned to rotation matrices computed apart
	from Haxe; each result into a new value or the one given, alike, even when the one given is its own position; taken back from a
	matrix, one that mirrors, one that flattens and one that shears (its nearest rotation, as the SVD gives it); and whole numbers
	multiplied as floats on the interpreter. */
class Transform3DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) < tolerance;

	static function at(p:Vector3D, x:Float, y:Float, z:Float, tolerance = 1e-12):Bool
		return near(p.x, x, tolerance) && near(p.y, y, tolerance) && near(p.z, z, tolerance);

	static function turnsAs(q:Quaternion3D, v:Array<Float>, tolerance = 1e-12):Bool {
		var sign = q.x * v[0] + q.y * v[1] + q.z * v[2] + q.w * v[3] < 0 ? -1 : 1;
		return near(q.x, sign * v[0], tolerance) && near(q.y, sign * v[1], tolerance) && near(q.z, sign * v[2], tolerance) && near(q.w, sign * v[3], tolerance);
	}

	static function matrixIs(m:Matrix3D, values:Array<Float>, tolerance = 1e-12):Bool {
		for (i in 0...16)
			if (!near(m.values[i], values[i], tolerance))
				return false;
		return true;
	}

	// At (3, -4, 2), turned by fromEuler(.3, -1.1, .5), scaled (2, .5, 1.5).
	static function sample():Transform3D {
		var t = new Transform3D();
		t.position.set(3, -4, 2);
		Quaternion3D.fromEuler(.3, -1.1, .5, t.rotation);
		t.scale.set(2, .5, 1.5);
		return t;
	}

	// Runs a result into a new vector, into one given and into the transform's own position: the same each way.
	static function threeWays(op:(Transform3D, Null<Vector3D>) -> Vector3D, message:String):Vector3D {
		var t = sample();
		var result = op(t, null), given = new Vector3D();
		check(result != t.position && t.position.equals(sample().position), '$message: into a new vector, the transform unchanged');
		check(op(sample(), given) == given && given.equals(result), '$message: into the one given');
		var own = sample();
		check(op(own, own.position) == own.position && own.position.equals(result), '$message: into its own position');
		return result;
	}

	// The angle between a direction and the world's up.
	static function fromUp(v:Vector3D):Float
		return Math.acos(v.y / v.length);

	static function main():Void {
		var t = new Transform3D();
		check(at(t.position, 0, 0, 0) && turnsAs(t.rotation, [0, 0, 0, 1]) && at(t.scale, 1, 1, 1), "made at the origin, unturned, at scale 1");
		check(at(t.computeForward(), 0, 0, -1) && at(t.computeRight(), 1, 0, 0) && at(t.computeUp(), 0, 1, 0), "facing -z, its right +x, its up +y");
		var s = sample();
		check(t.copyFrom(s) == t && t.position.equals(s.position) && t.position != s.position && t.rotation != s.rotation && t.rotation.x == s.rotation.x
			&& t.scale.equals(s.scale),
			"copied, returning itself");
		check(t.makeIdentity() == t && at(t.position, 0, 0, 0) && t.rotation.w == 1 && at(t.scale, 1, 1, 1), "reset, returning itself");

		// Pinned: rotation matrices in Python (Rz Ry Rx and Rodrigues' formula), apart from Haxe, Trig and quaternions.
		var matrix = [
			 0.7961360926083894, 0.4349311296464697, 1.7824147201228708, 0, -0.344570719966525, 0.3560602217101115, 0.06702340977223432, 0,
			-0.9082446196519794, -1.001291518441541, 0.6500053891855546, 0,                  3,                 -4,                   2, 1
		];
		check(matrixIs(sample().toMatrix(), matrix), "its matrix scales, turns and moves: pinned");
		var m = new Matrix3D();
		check(sample().toMatrix(m) == m && matrixIs(m, matrix), "its matrix, into the one given");
		var point = threeWays((t, out) -> t.transformPoint(1.5, 2, -.5, out), "transformPoint");
		check(at(point, 3.959185008805524, -2.134837102889302, 4.482666205135998), "a point carried: pinned");
		check(point.equals(sample().toMatrix().transformPoint(1.5, 2, -.5), 1e-14), "a point carried as its matrix carries it");
		check(at(threeWays((t, out) -> t.computeForward(out), "computeForward"), 0.6054964131013196, 0.6675276789610274, -0.43333692612370306),
			"its forward: pinned");
		check(at(threeWays((t, out) -> t.computeRight(out), "computeRight"), 0.3980680463041947, 0.21746556482323484, 0.8912073600614354), "its right: pinned");
		check(at(threeWays((t, out) -> t.computeUp(out), "computeUp"), -0.68914143993305, 0.712120443420223, 0.13404681954446865), "its up: pinned");

		s = sample();
		check(s.moveForward(2) == s
			&& s.moveRight(-1) == s
			&& s.moveUp(.5) == s
			&& at(s.position, 3.46835405993192, -2.5263499851910685, 0.3091421974633929),
			"moved forward 2, left 1 and up a half: pinned");
		s = sample();
		check(s.moveForward(2, true) == s && s.moveRight(-1, true) == s && at(s.position, 4.218571550049526, -4, -0.07702770446787821),
			"moved along the ground: its height kept, pinned");
		var level = new Transform3D();
		level.pitch(Math.PI / 3);
		check(level.moveRight(2, true).moveForward(3, true) == level
			&& at(level.position, 2, 0, -3), "pitched up: along the ground, as far");

		var walker = new Transform3D();
		walker.position.set(3, 4, 12);
		check(walker.moveToward(0, 0, 0, 6.5) == walker && at(walker.position, 1.5, 2, 6), "moved toward a point");
		walker.moveToward(0, 0, 0, 100);
		check(near(walker.position.length, .001), "stopped short of the point, the nearest distance away");
		walker.moveToward(0, 0, 0, 1);
		check(near(walker.position.length, .001), "no nearer once there");
		walker.moveToward(0, 0, 0, -1, 0);
		check(near(walker.position.length, 1.001), "moved away");
		walker.position.set(0, 0, 0);
		check(walker.moveToward(0, 0, 0, 1) == walker && at(walker.position, 0, 0, 0), "at the point, it stays");

		// Turned around its own axes.
		var turner = new Transform3D();
		check(turner.yaw(Math.PI / 2) == turner && at(turner.computeForward(), -1, 0, 0), "yawed more than 0: turned left");
		turner.makeIdentity();
		check(turner.pitch(.5) == turner
			&& at(turner.computeForward(), 0, Math.sin(.5), -Math.cos(.5)), "pitched more than 0: facing higher");
		turner.makeIdentity();
		check(turner.roll(Math.PI / 2) == turner && at(turner.computeUp(), 1, 0, 0) && at(turner.computeForward(), 0, 0, -1),
			"rolled more than 0: tilted to the right, facing as it was");
		s = sample();
		s.yaw(.4).pitch(-.3).roll(.2);
		check(turnsAs(s.rotation, [0.0913459253135741, -0.33973753515511973, 0.18917538176914578, 0.916758967268839]),
			"yawed, pitched and rolled, each around its own axis: pinned");
		check(near(s.rotation.x * s.rotation.x + s.rotation.y * s.rotation.y + s.rotation.z * s.rotation.z + s.rotation.w * s.rotation.w, 1, 1e-15),
			"still of length 1");

		// The pitch locked 0.001 radians short of straight up and down.
		turner.makeIdentity();
		turner.pitch(2, true);
		check(near(fromUp(turner.computeForward()), .001, 1e-12), "locked: no higher than 0.001 radians short of straight up");
		turner.pitch(.5, true);
		check(near(fromUp(turner.computeForward()), .001, 1e-12), "and no further when pitched up again");
		turner.pitch(-.2, true);
		check(near(fromUp(turner.computeForward()), .201, 1e-12), "but back down freely");
		turner.pitch(-10, true);
		check(near(fromUp(turner.computeForward()), Math.PI - .001, 1e-12), "and no lower than 0.001 radians short of straight down");
		turner.makeIdentity().yaw(1.2).pitch(.7);
		turner.pitch(1, true);
		check(near(fromUp(turner.computeForward()), .001, 1e-12)
			&& near(turner.computeRight().y, 0, 1e-15), "locked when yawed: its right still level");
		turner.makeIdentity().pitch(Math.PI / 2 - .0005);
		var past = turner.computeForward();
		turner.pitch(.0002, true);
		check(turner.computeForward().equals(past, 1e-15), "already nearer straight up than the lock: no further");
		turner.pitch(-.1, true);
		check(near(fromUp(turner.computeForward()), .1005, 1e-12), "but back toward level");
		var rolled = new Transform3D().roll(.7),
			free = new Transform3D().roll(.7);
		rolled.pitch(3, true);
		free.pitch(3);
		check(rolled.computeForward().equals(free.computeForward(), 1e-15), "rolled, it never comes near straight up: the lock leaves it");
		var tilted = new Transform3D().roll(.0005), most = 0.;
		for (_ in 0...40) {
			tilted.pitch(.1, true);
			most = Math.max(most, tilted.computeForward().y);
		}
		check(most <= Math.cos(.001) + 1e-15 && near(most, Math.cos(.001), 1e-12), "rolled a little, stopped as it reaches the limit");

		// Turned to face a point.
		s = sample();
		check(s.lookAt(10, 7, -3) == s
			&& turnsAs(s.rotation, [0.389600901306046, -0.41131790526508594, 0.2004955958339072, 0.7992685622249036]),
			"turned to face a point: pinned");
		var toward = new Vector3D(10 - 3, 7 + 4, -3 - 2).normalize();
		check(s.computeForward().equals(toward, 1e-12)
			&& near(s.computeRight().y, 0)
			&& s.computeUp().y > 0, "facing it, its right level");
		var before = new Quaternion3D().copyFrom(s.rotation);
		check(s.lookAt(3, -4, 2) == s && s.rotation.x == before.x && s.rotation.w == before.w, "a point at its position leaves it as it is");
		s.lookAt(3, -10, 2, 0, 0, -1);
		check(s.computeForward().equals(new Vector3D(0, -1, 0), 1e-15)
			&& s.computeUp().equals(new Vector3D(0, 0, -1), 1e-15), "an up given");

		// Swung around a point.
		s = sample();
		s.lookAt(10, 7, -3);
		check(s.orbit(1, 1, 1, .6, .25) == s
			&& at(s.position, 2.779337588937457, -4.103403243266118, 1.8883879114526014)
			&& turnsAs(s.rotation, [
				0.31773164129846737,
				-0.16504987584998843,
				0.05626728656673865,
				0.9320081196331401
			]), "swung around a point: pinned");
		var orbiter = new Transform3D();
		orbiter.position.set(0, 0, 5);
		orbiter.lookAt(0, 0, 0);
		orbiter.orbit(0, 0, 0, Math.PI / 2, 0);
		check(at(orbiter.position, 5, 0, 0) && at(orbiter.computeForward(), -1, 0, 0), "yawed a quarter turn: turned left, to its right of the point");
		orbiter.orbit(0, 0, 0, 0, .5);
		check(at(orbiter.position, 5 * Math.cos(.5), 5 * Math.sin(.5), 0)
			&& orbiter.computeForward().equals(orbiter.position.negate().normalize(), 1e-12),
			"pitched more than 0: swung upward, still facing the point");
		orbiter.orbit(0, 0, 0, .3, 5, true);
		check(near(fromUp(orbiter.position), .001, 1e-12)
			&& near(orbiter.position.length, 5, 1e-12)
			&& orbiter.computeForward().equals(orbiter.position.negate().normalize(), 1e-12),
			"locked: no higher than 0.001 radians short of straight above, still facing it");
		orbiter.orbit(0, 0, 0, 0, -20, true);
		check(near(fromUp(orbiter.position), Math.PI - .001, 1e-12), "and no lower than short of straight below");
		var around = new Transform3D();
		around.position.set(2, 1, -3);
		around.orbit(2, 1, -3, .4, .2);
		check(at(around.position, 2, 1, -3), "around its own position: it only turns");

		// Back from a matrix: what made it, or the matrix again.
		for (made in [
			sample(),
			{
				var u = sample();
				u.scale.set(-.5, 3, 2);
				u;
			},
			{
				var u = sample();
				u.scale.set(0, 2, 1);
				u;
			},
			{
				var u = sample();
				u.scale.set(1, 0, 0);
				u;
			}
		]) {
			var original = made.toMatrix(),
				back = Transform3D.fromMatrix(original);
			check(matrixIs(back.toMatrix(), original.values, 1e-12), 'back from its matrix, the same matrix (${original.values})');
		}
		var back = Transform3D.fromMatrix(sample().toMatrix(), t);
		var sampled = sample().rotation;
		check(back == t
			&& at(t.position, 3, -4, 2)
			&& turnsAs(t.rotation, [sampled.x, sampled.y, sampled.z, sampled.w])
			&& at(t.scale, 2, .5, 1.5),
			"back from its matrix into the one given: what made it");
		var mirrored = Transform3D.fromMatrix(Matrix3D.fromScale(1, 1, -1));
		check(at(mirrored.scale, -1, 1, 1) && near(Math.abs(mirrored.rotation.y), 1) && at(mirrored.computeForward(), 0, 0, 1),
			"a matrix that mirrors z: x's scale less than 0, its rotation a half turn, facing the way the matrix does");
		var sheared = new Matrix3D();
		var shear = [
			2.0,
			0.0,
			0.2,
			0,
			0.6143077933232609,
			1.46020150441682,
			0.3835404308833624,
			0,
			-0.3355978770229421,
			-0.4558635393391927,
			0.7020660495122982,
			0,
			1,
			2,
			3,
			1
		];
		for (i in 0...16)
			sheared.values[i] = shear[i];
		var nearest = Transform3D.fromMatrix(sheared);
		check(turnsAs(nearest.rotation,
			[
				0.17260614668505206,
				-0.07292856507395817,
				-0.08645041320117793,
				0.9784757884486139
			]) && at(nearest.scale, 1.971405786818069, 1.5742197977634664, 0.8589104391495211) && at(nearest.position, 1, 2, 3),
			"a matrix that shears: the nearest rotation, as the SVD gives it, and the scale along its axes, pinned");
		var empty = Transform3D.fromMatrix(Matrix3D.fromScale(0, 0, 0));
		check(turnsAs(empty.rotation, [0, 0, 0, 1]) && at(empty.scale, 0, 0, 0), "a matrix that flattens everything: unturned, scale 0");

		// The interpreter multiplies Ints passed for Floats as Ints; whole numbers this large must still multiply as floats.
		var large = new Transform3D();
		large.scale.set(100000, 1, 1);
		check(large.transformPoint(100000, 0, 0).x == 1e10 && large.toMatrix().transformPoint(100000, 0, 0).x == 1e10,
			"large whole numbers multiplied as floats");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
