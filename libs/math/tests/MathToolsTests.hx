import helix.math.MathTools;

using helix.math.MathTools;

/** Checks MathTools with the library alone: a number clamped, wrapped and snapped, as an Int for Ints and a Float for any other
	numbers, called on the number itself too; an angle wrapped; a value bounced between two walls; a sign; two values equal but for
	rounding; the least, greatest and size of whole numbers as Ints; powers of two; and degrees and radians. */
class MathToolsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	// Whether a value is typed as an Int: an Int divided by 2 is a Float, so this tells the forms apart by what the compiler picked.
	static function isInt(value:Int):Bool
		return true;

	static function main():Void {
		check(MathTools.clamp(5., 0, 3) == 3 && MathTools.clamp(-1., 0, 3) == 0 && MathTools.clamp(2.5, 0, 3) == 2.5, "clamp: over, under and within");
		check(MathTools.clamp(2., 3, 0) == 2 && MathTools.clamp(7., 3, 0) == 3, "clamp: bounds in the wrong order are swapped");
		check(isInt(MathTools.clamp(9, 0, 7)) && MathTools.clamp(9, 0, 7) == 7 && MathTools.clamp(-2, 0, 7) == 0 && MathTools.clamp(4, 7, 0) == 4,
			"clamp: whole numbers return an Int");
		check(MathTools.clamp(3, 0, 2.5) == 2.5, "clamp: a whole number between a Float's bounds returns a Float");
		check(Math.isNaN(MathTools.clamp(Math.NaN, 0, 1)), "clamp: NaN stays NaN");
		check(MathTools.clamp01(1.5) == 1 && MathTools.clamp01(-.5) == 0 && MathTools.clamp01(.25) == .25, "clamp01");

		check(MathTools.wrap(370., 0, 360) == 10 && MathTools.wrap(-10., 0, 360) == 350 && MathTools.wrap(360., 0, 360) == 0
			&& MathTools.wrap(45., 0, 360) == 45,
			"wrap: over, under, at the end and within");
		check(near(MathTools.wrap(4, -Math.PI, Math.PI), 4 - 2 * Math.PI) && MathTools.wrap(7., 2, 5) == 4, "wrap: a range not from 0");
		check(MathTools.wrap(370., 360, 0) == 10 && MathTools.wrap(0., 360, 0) == 0, "wrap: bounds in the wrong order are swapped");
		check(MathTools.wrap(9., 4, 4) == 4, "wrap: a range of no size returns its start");
		check(isInt(MathTools.wrap(8, 0, 8)) && MathTools.wrap(8, 0, 8) == 0 && MathTools.wrap(-1, 0, 8) == 7 && MathTools.wrap(-17, 0, 8) == 7
			&& MathTools.wrap(5, 0, 8) == 5 && MathTools.wrap(7, 2, 5) == 4 && MathTools.wrap(1, 2, 5) == 4,
			"wrap: whole numbers return an Int");
		check(MathTools.wrap(9, 8, 0) == 1 && MathTools.wrap(9, 4, 4) == 4, "wrap: whole numbers, with swapped bounds and a range of no size");
		check(near(MathTools.wrapAngle(3 * Math.PI), -Math.PI)
			&& near(MathTools.wrapAngle(-3.5 * Math.PI), .5 * Math.PI)
			&& MathTools.wrapAngle(1) == 1,
			"wrapAngle to -π up to π");

		check(MathTools.snap(7.4, 2) == 8 && MathTools.snap(6.9, 2) == 6 && MathTools.snap(-7.4, 2) == -8 && near(MathTools.snap(.37, .25), .25)
			&& MathTools.snap(5., 2) == 6 && MathTools.snap(-5., 2) == -4,
			"snap: to the nearest multiple, a half to the greater");
		check(MathTools.snap(7.4, 0) == 7.4 && MathTools.snap(7.4, -2) == 7.4, "snap: a step of 0 or less leaves the value");
		check(isInt(MathTools.snap(37, 16)) && MathTools.snap(37, 16) == 32 && MathTools.snap(40, 16) == 48 && MathTools.snap(41, 16) == 48
			&& MathTools.snap(-37, 16) == -32 && MathTools.snap(-40, 16) == -32 && MathTools.snap(-41, 16) == -48 && MathTools.snap(48, 16) == 48
			&& MathTools.snap(5, 0) == 5,
			"snap: whole numbers return an Int");

		check(MathTools.pingPong(1, 4) == 1 && MathTools.pingPong(4, 4) == 4 && MathTools.pingPong(5, 4) == 3 && MathTools.pingPong(8, 4) == 0
			&& MathTools.pingPong(9, 4) == 1 && MathTools.pingPong(-1, 4) == 1 && MathTools.pingPong(-5, 4) == 3,
			"pingPong: out, back and out again, below 0 too");
		check(MathTools.pingPong(3, 0) == 0 && MathTools.pingPong(3, -2) == 0, "pingPong: a length of 0 or less returns 0");

		check(MathTools.sign(2.5) == 1 && MathTools.sign(-.001) == -1 && MathTools.sign(0) == 0 && MathTools.sign(Math.NaN) == 0, "sign");
		check(isInt(MathTools.sign(-3.5)) && MathTools.sign(-7) == -1, "sign: an Int, of a whole number too");

		check(MathTools.equals(1, 1, 0)
			&& !MathTools.equals(1, 1.0000001, 0)
			&& MathTools.equals(.5, .5000001, 1e-6)
			&& !MathTools.equals(.5, .50001, 1e-6),
			"equals: exactly, or within a tolerance");
		check(MathTools.equals(1e6, 1e6 + .5, 1e-6) && !MathTools.equals(1e6, 1e6 + 2, 1e-6) && MathTools.equals(-1e6, -1e6 - .5, 1e-6),
			"equals: the tolerance multiplied by the larger value's size over 1");

		check(isInt(MathTools.min(3, 7)) && MathTools.min(3, 7) == 3 && MathTools.min(-3, -7) == -7, "min of whole numbers is an Int");
		check(isInt(MathTools.max(3, 7)) && MathTools.max(3, 7) == 7 && MathTools.max(-3, -7) == -3, "max of whole numbers is an Int");
		check(isInt(MathTools.abs(-5)) && MathTools.abs(-5) == 5 && MathTools.abs(5) == 5 && MathTools.abs(0) == 0, "abs of a whole number is an Int");

		check(MathTools.isPowerOfTwo(1) && MathTools.isPowerOfTwo(2) && MathTools.isPowerOfTwo(1024) && MathTools.isPowerOfTwo(0x40000000)
			&& !MathTools.isPowerOfTwo(0) && !MathTools.isPowerOfTwo(3) && !MathTools.isPowerOfTwo(1023) && !MathTools.isPowerOfTwo(-8),
			"isPowerOfTwo");
		check(MathTools.nextPowerOfTwo(1) == 1
			&& MathTools.nextPowerOfTwo(2) == 2
			&& MathTools.nextPowerOfTwo(3) == 4
			&& MathTools.nextPowerOfTwo(300) == 512
			&& MathTools.nextPowerOfTwo(512) == 512
			&& MathTools.nextPowerOfTwo(513) == 1024
			&& MathTools.nextPowerOfTwo(0) == 1
			&& MathTools.nextPowerOfTwo(-9) == 1
			&& MathTools.nextPowerOfTwo(0x7fffffff) == 0x40000000,
			"nextPowerOfTwo: the number itself, the next above, 1 below 1, and 1,073,741,824 at most");

		check(MathTools.toRadians(180) == Math.PI
			&& near(MathTools.toRadians(-90), -Math.PI / 2)
			&& MathTools.toRadians(0) == 0, "toRadians");
		check(MathTools.toDegrees(Math.PI) == 180 && near(MathTools.toDegrees(-Math.PI / 2), -90), "toDegrees");
		check(near(MathTools.toDegrees(MathTools.toRadians(37.5)), 37.5), "toRadians and toDegrees undo each other");

		// Called on the number itself, with `using`.
		var level = 1.5, index = 9, degrees = 90.;
		check(level.clamp(0, 1) == 1 && isInt(index.clamp(0, 7)) && index.clamp(0, 7) == 7, "using: clamp on a Float and on an Int");
		check(isInt(index.wrap(0, 8)) && index.wrap(0, 8) == 1 && isInt(index.snap(4)) && index.snap(4) == 8, "using: wrap and snap on an Int");
		check(near(degrees.toRadians(), Math.PI / 2)
			&& level.sign() == 1
			&& index.min(4) == 4
			&& (-index).abs() == 9, "using: the others");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
