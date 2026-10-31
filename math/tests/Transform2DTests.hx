import helix.math.Matrix2D;
import helix.math.Transform2D;
import helix.math.Vector2D;

/** Checks Transform2D with the library alone: made, copied and reset, each returning itself; its forward and right; moved along them
	and toward a point (stopping short of it); turned, turned to face a point and swung around one; points carried and its matrix, pinned
	to plain 3 x 3 algebra computed apart from Haxe; each result into a new value or the one given, alike, even when the one given is its
	own position; and taken back from a matrix. */
class Transform2DTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function at(p:Vector2D, x:Float, y:Float):Bool
		return near(p.x, x) && near(p.y, y);

	static function is(m:Matrix2D, values:Array<Float>):Bool
		return near(m.a, values[0]) && near(m.b, values[1]) && near(m.c, values[2]) && near(m.d, values[3]) && near(m.tx, values[4]) && near(m.ty, values[5]);

	static function sample():Transform2D {
		var t = new Transform2D();
		t.position.set(3, -4);
		t.rotation = .9;
		t.scale.set(2, .5);
		return t;
	}

	// Runs a result into a new vector and into one given, and into the transform's own position: the same each way.
	static function twoWays(op:(Transform2D, Null<Vector2D>) -> Vector2D, message:String):Vector2D {
		var t = sample();
		var result = op(t, null), given = new Vector2D();
		check(op(sample(), given) == given && given.equals(result) && t.position.equals(sample().position), '$message: into a new vector or the one given');
		var own = sample();
		check(op(own, own.position) == own.position && own.position.equals(result), '$message: into its own position');
		return result;
	}

	static function main():Void {
		var t = new Transform2D();
		check(t.position.x == 0 && t.position.y == 0 && t.rotation == 0 && t.scale.x == 1 && t.scale.y == 1, "made at the origin, facing +x, at scale 1");
		check(at(t.computeForward(), 1, 0) && at(t.computeRight(), 0, 1), "facing +x, its right +y");
		var s = sample();
		check(t.copyFrom(s) == t && t.position.equals(s.position) && t.rotation == .9 && t.scale.equals(s.scale) && t.position != s.position,
			"copied, returning itself");
		check(t.makeIdentity() == t && t.position.x == 0 && t.rotation == 0 && t.scale.y == 1, "reset, returning itself");

		// Pinned: plain 3 x 3 algebra in Python, apart from Haxe and Trig.
		check(is(sample().toMatrix(), [
			1.2432199365413288,
			1.5666538192549668,
			-0.3916634548137417,
			0.3108049841353322,
			3,
			-4
		]), "its matrix scales, turns and moves: pinned");
		var m = new Matrix2D();
		check(sample().toMatrix(m) == m && is(m, [
			1.2432199365413288,
			1.5666538192549668,
			-0.3916634548137417,
			0.3108049841353322,
			3,
			-4
		]), "its matrix, into the one given");
		var point = twoWays((t, out) -> t.transformPoint(1.5, 2, out), "transformPoint");
		check(at(point, 4.081502995184509, -1.0284093028468853), "a point carried: pinned");
		check(point.equals(sample().toMatrix().transformPoint(1.5, 2)), "a point carried as its matrix carries it");
		check(at(twoWays((t, out) -> t.computeForward(out), "computeForward"), 0.6216099682706644, 0.7833269096274834), "its forward: pinned");
		check(at(twoWays((t, out) -> t.computeRight(out), "computeRight"), -0.7833269096274834, 0.6216099682706644), "its right: pinned");

		s = sample();
		check(s.moveForward(2) == s
			&& s.moveRight(-1) == s
			&& at(s.position, 5.026546846168812, -3.054956149015698), "moved forward 2 and left 1: pinned");
		check(s.lookAt(10, 7) == s && near(s.rotation, 1.1114563205061627), "turned to face a point: pinned");
		check(s.lookAt(s.position.x, s.position.y) == s
			&& near(s.rotation, 1.1114563205061627), "a point at its position leaves it facing as it was");
		check(s.orbit(1, 1, .6) == s && at(s.position, 6.612852986733994, -0.07314035621791559) && near(s.rotation, 1.7114563205061626),
			"swung around a point, still facing the same way past it: pinned");
		check(s.rotate(-.6) == s && near(s.rotation, 1.1114563205061627), "turned back");

		var walker = new Transform2D();
		walker.position.set(3, 4);
		check(walker.moveToward(0, 0, 2) == walker && at(walker.position, 1.8, 2.4), "moved toward a point");
		walker.moveToward(0, 0, 100);
		check(near(walker.position.length, .001), "stopped short of the point, the nearest distance away");
		walker.moveToward(0, 0, 1);
		check(near(walker.position.length, .001), "no nearer once there");
		walker.moveToward(0, 0, -1, 0);
		check(near(walker.position.length, 1.001), "moved away");
		walker.position.set(0, 0);
		check(walker.moveToward(0, 0, 1) == walker && walker.position.x == 0 && walker.position.y == 0, "at the point, it stays");

		// Back from a matrix: what made it, or the matrix again.
		for (made in [
			sample(),
			{
				var u = sample();
				u.rotation = -2.8;
				u.scale.set(-.5, 3);
				u;
			},
			{var u = sample(); u.scale.set(0, 2); u;}
		]) {
			var matrix = made.toMatrix(),
				back = Transform2D.fromMatrix(matrix);
			check(is(back.toMatrix(), [matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty]), "back from its matrix, the same matrix");
		}
		var back = Transform2D.fromMatrix(sample().toMatrix(), t);
		check(back == t && at(t.position, 3, -4) && near(t.rotation, .9) && at(t.scale, 2, .5), "back from its matrix into the one given: what made it");
		var mirrored = Transform2D.fromMatrix(Matrix2D.fromScale(1, -1));
		check(mirrored.rotation == 0 && at(mirrored.scale, 1, -1), "a mirroring matrix: y's scale less than 0");
		var sheared = Transform2D.fromMatrix(new Matrix2D().set(2, 0, 1, 3, 0, 0));
		check(sheared.rotation == 0 && at(sheared.scale, 2, 3), "a shearing matrix: its x axis kept, the shear lost");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
