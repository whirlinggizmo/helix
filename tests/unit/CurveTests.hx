import helix.math.Curve;
import helix.math.Interpolate;

/** Interpolation (helix.math.Interpolate) and curves (Curve): lerps, angles the short way round, damping the same at any frame rate; a
	polyline's points and length, a Bézier's known middle, a Catmull-Rom through its points, closed curves around, tangents, and a steady
	speed by distance. */
class CurveTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, e = 1e-6):Bool
		return Math.abs(a - b) < e;

	static function main():Void {
		// Interpolate.
		check(Interpolate.lerp(10, 20, .25) == 12.5 && Interpolate.lerp(10, 20, 1.5) == 25, "lerp, past the ends too");
		check(Interpolate.inverseLerp(10, 20, 15) == .5 && Interpolate.inverseLerp(5, 5, 7) == 0, "inverseLerp, and 0 for an empty range");
		check(Interpolate.remap(5, 0, 10, 100, 200) == 150, "remap");
		check(Interpolate.clamp(5, 0, 3) == 3 && Interpolate.clamp(-1, 0, 3) == 0 && Interpolate.clamp(2, 3, 0) == 2, "clamp, with swapped bounds");
		check(Interpolate.smoothStep(.5) == .5 && Interpolate.smoothStep(2) == 1 && Interpolate.smoothStep(.25) < .25, "smoothStep is slow at the ends");
		check(near(Interpolate.wrapAngle(3 * Math.PI), -Math.PI)
			&& near(Interpolate.wrapAngle(-3.5 * Math.PI), .5 * Math.PI), "wrapAngle to -π up to π");
		check(near(Interpolate.lerpAngle(.1, 2 * Math.PI - .1, .5), 0), "lerpAngle goes the short way round");
		check(Interpolate.moveToward(0, 10, 3) == 3
			&& Interpolate.moveToward(9, 10, 3) == 10
			&& Interpolate.moveToward(0, -10, 3) == -3
			&& Interpolate.moveToward(0, 10, 0) == 0,
			"moveToward by at most the step, reaching the target exactly");
		var once = Interpolate.damp(0, 100, 2, .1),
			twice = Interpolate.damp(Interpolate.damp(0, 100, 2, .05), 100, 2, .05);
		check(near(once, twice) && once > 0 && once < 100 && Interpolate.damp(5, 100, 0, .1) == 5,
			"damp is the same over two half steps as one; a rate of 0 stays");
		check(near(Interpolate.dampAngle(.1, 2 * Math.PI - .1, 1000, 1), 2 * Math.PI - .1 - 2 * Math.PI, 1e-3), "dampAngle the short way round");

		// A polyline: on its points, straight between, its length the sum.
		var line = Curve.polyline([0, 0, 10, 0, 10, 5]);
		check(line.getPointCount() == 3 && line.getDimensions() == 2 && !line.isClosed() && line.getKind() == Polyline, "A polyline of three points");
		check(line.getX(0) == 0 && line.getX(.5) == 10 && line.getY(.5) == 0 && line.getX(1) == 10 && line.getY(1) == 5, "At its points at the segments' ends");
		check(line.getX(.25) == 5 && near(line.getY(.75), 2.5), "Straight between them");
		check(near(line.getLength(), 15), "Its length is the sum of its pieces");
		check(line.getX(-1) == 0 && line.getY(2) == 5 && line.getZ(.5) == 0, "Held to its ends; z is 0 in 2D");
		// A steady speed: by distance, 2.5 units a step, three steps along the long piece.
		var atFive = line.getParameterAtDistance(5),
			atTen = line.getParameterAtDistance(10);
		check(near(line.getX(atFive), 5)
			&& near(line.getX(atTen), 10)
			&& near(line.getY(atTen), 0, 1e-3)
			&& near(line.getY(line.getParameterAtDistance(12.5)), 2.5, 1e-3),
			"A distance along it is where it says, though t isn't even");
		check(line.getParameterAtDistance(-1) == 0 && line.getParameterAtDistance(99) == 1, "Distance held to the length when open");
		var tan = line.tangent(.25, []);
		check(near(tan[0], 1) && near(tan[1], 0) && near(line.tangent(.75, [])[1], 1), "The tangent heads along each piece");

		// Closed: around a square, 40 long, back to the start.
		var square = Curve.polyline([0, 0, 10, 0, 10, 10, 0, 10], 2, true);
		check(square.isClosed() && near(square.getLength(), 40) && near(square.getX(1), 0) && near(square.getY(1), 0), "A closed polyline comes back");
		check(near(square.getX(1.125), 5) && near(square.getY(-.125), 5), "and goes around past 1 and under 0");
		check(near(square.getX(square.getParameterAtDistance(45)), 5), "Distance goes around too");

		// A cubic Bézier: the known middle.
		var arc = Curve.bezier([0, 0, 0, 10, 10, 10, 10, 0]);
		check(near(arc.getX(.5), 5) && near(arc.getY(.5), 7.5) && arc.getX(0) == 0 && arc.getX(1) == 10, "A Bézier's middle is (p0 + 3p1 + 3p2 + p3) / 8");
		var two = Curve.bezier([0, 0, 1, 1, 2, 1, 3, 0, 4, -1, 5, -1, 6, 0]);
		check(near(two.getX(.5), 3) && near(two.getY(.5), 0) && near(two.getX(1), 6), "Pieces join at their shared point");

		// Through: on its points at the segments' ends, between them in between, smooth.
		var through = Curve.through([0, 0, 1, 2, 3, 2, 4, 0]);
		check(near(through.getX(0), 0) && near(through.getX(1 / 3), 1) && near(through.getY(1 / 3), 2) && near(through.getX(2 / 3), 3)
			&& near(through.getY(1), 0),
			"A Catmull-Rom passes through its points");
		var mid = through.getY(.5);
		check(mid > 2 && mid < 2.5, "and rises a little between two level points");
		var loop = Curve.through([0, 0, 10, 0, 10, 10, 0, 10], 2, true);
		check(near(loop.getX(1), 0) && near(loop.getY(1), 0) && loop.getLength() > 40 && loop.getLength() < 50,
			"A closed one comes back, bulging a little outside the square");
		// Points on top of each other don't break it.
		var doubled = Curve.through([0, 0, 0, 0, 5, 5, 5, 5]);
		check(near(doubled.getX(1), 5) && Math.isFinite(doubled.getX(.5)), "Repeated points are taken");

		// 3D.
		var rise = Curve.polyline([0, 0, 0, 0, 0, 10], 3);
		check(rise.getDimensions() == 3 && near(rise.getZ(.5), 5) && near(rise.getLength(), 10) && rise.tangent(.5, [])[2] == 1, "A 3D curve has z");
		var out = rise.evaluate(.3, []);
		check(out.length == 3 && near(out[2], 3), "evaluate fills every axis");
		check(rise.getPoint(1, 2) == 10 && rise.getPoint(5, 0) == 0, "Points read back");

		// Refusals.
		var threw = 0;
		for (f in [
			() -> Curve.through([0, 0]),
			() -> Curve.bezier([0, 0, 1, 1, 2, 2]),
			() -> Curve.polyline([0, 0, 1], 2),
			() -> Curve.through([0, 0, 1, 1], 4)
		])
			try
				f()
			catch (e:Dynamic)
				threw++;
		check(threw == 4, "Too few points, a wrong Bézier count, an odd number and a wrong dimension are refused");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
