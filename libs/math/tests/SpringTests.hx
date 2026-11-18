import helix.math.Spring;

/** Checks Spring with the library alone: a value following a target, pinned to a critically damped spring's motion, the same at any
	frame rate, stopping at the target, with the value and the velocity set by hand. */
class SpringTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) < tolerance;

	static function main():Void {
		var spring = new Spring();
		check(spring.value == 0 && spring.velocity == 0 && new Spring(4).value == 4, "a spring at rest, at 0 unless told");

		// From rest at 0 toward 10 over half a second: 10 (1 - (1 + 4t) e^(-4t)), moving at 160 t e^(-4t).
		check(near(spring.update(10, .5, .25), 10 * (1 - 2 * Math.exp(-1))) && near(spring.velocity, 40 * Math.exp(-1)),
			"a step from rest: the spring's own motion");
		check(spring.update(10, .5, 0) == spring.value
			&& spring.update(10, .5, -1) == spring.value
			&& near(spring.velocity, 40 * Math.exp(-1)),
			"a time step of 0 or less leaves the value and the velocity unchanged");
		var one = new Spring(), sixty = new Spring(), uneven = new Spring();
		one.update(10, .5, 1);
		for (_ in 0...60)
			sixty.update(10, .5, 1 / 60);
		for (dt in [.3, .05, .45, .2])
			uneven.update(10, .5, dt);
		check(near(one.value, 10 * (1 - 5 * Math.exp(-4)))
			&& near(sixty.value, one.value, 1e-11)
			&& near(uneven.value, one.value, 1e-11)
			&& near(sixty.velocity, one.velocity, 1e-11)
			&& near(uneven.velocity, one.velocity, 1e-11),
			"one step, sixty steps and uneven steps over a second: the same value and velocity");
		var half = new Spring(), twice = new Spring();
		half.update(10, .5, .5);
		twice.update(10, .5, 1);
		check(near(half.value, 10 * (1 - 3 * Math.exp(-2)))
			&& half.value > 5.9
			&& twice.value > 9, "3/5 of the gap in the time, 9/10 in twice the time");

		// Never past the target, and at rest there.
		var follower = new Spring(-3), last = -3., rising = true, below = true;
		for (_ in 0...600) {
			follower.update(7, .2, 1 / 60);
			if (follower.value < last)
				rising = false;
			if (follower.value > 7)
				below = false;
			last = follower.value;
		}
		check(rising && below && near(follower.value, 7, 1e-9) && near(follower.velocity, 0, 1e-9), "toward the target all the way, never past, at rest there");
		follower.value = 0;
		follower.velocity = 500;
		check(follower.update(1, .5, .1) == 1 && follower.velocity == 0, "a value that would pass the target stops at the target");
		follower.value = 2;
		follower.velocity = -500;
		check(follower.update(1, .5, .1) == 1 && follower.velocity == 0, "from above too");
		follower.value = 5;
		follower.velocity = 3;
		check(follower.update(-2, 0, .1) == -2 && follower.velocity == 0 && follower.value == -2, "a time of 0 or less puts the value at the target");
		follower.velocity = 4;
		check(follower.update(-2, 1, .1) > -2 && follower.velocity < 4, "at the target and moving: carried off, and slowed");

		// A target that moves is followed.
		var chaser = new Spring(), target = 0.;
		for (_ in 0...240) {
			target += 2 / 60;
			chaser.update(target, .25, 1 / 60);
		}
		check(chaser.value < target && near(chaser.velocity, 2, .01) && near(target - chaser.value, .5, .02),
			"a target moving steadily is followed at its speed, about the time behind");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
