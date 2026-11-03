import helix.services.time.Time;

/** Checks Time over a fake system's clock: deltas real, scaled, paused and capped; elapsed as their sum; timers once and repeating, in
	the order they fall due, cancelled, made inside a call, and every refusing an interval of 0. */
class TimeTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float):Bool
		return Math.abs(a - b) < 1e-9;

	static function main():Void {
		var system = new FakeSystem();
		system.now = 100;
		var time = new Time(system);
		system.now = 100.1;
		time.poll();
		check(near(time.realDelta, .1) && near(time.delta, .1) && near(time.elapsed, .1), "a frame: real and game seconds alike at scale 1");
		time.scale = 2;
		system.now = 100.2;
		time.poll();
		check(near(time.realDelta, .1) && near(time.delta, .2) && near(time.elapsed, .3), "scale 2: twice the game seconds");
		time.scale = -3;
		check(time.scale == 0, "a negative scale is 0");
		time.scale = 1;
		time.paused = true;
		system.now = 100.3;
		time.poll();
		check(near(time.realDelta, .1) && time.delta == 0 && near(time.elapsed, .3), "paused: real seconds run, game seconds don't");
		time.paused = false;
		system.now = 105;
		time.poll();
		check(time.realDelta == .25 && time.delta == .25, "a stall counts maxDelta at most");
		time.maxDelta = 0;
		check(time.maxDelta > 0, "maxDelta stays more than 0");
		time.maxDelta = .25;
		system.now = 104;
		time.poll();
		check(time.realDelta == 0, "a clock going back counts 0");

		var start = time.elapsed;
		var calls = [];
		var once = time.after(.1875, () -> calls.push("once"));
		var repeat = time.every(.125, () -> calls.push("every"));
		check(once.remaining == .1875 && once.interval == 0 && !once.done && repeat.interval == .125, "made: remaining and interval");
		system.now = 104.125;
		time.poll();
		check(calls.join(",") == "every" && once.remaining == .0625, "every's first call; once not yet");
		system.now = 104.375;
		time.poll();
		check(calls.join(",") == "every,once,every,every" && once.done, "a long frame: each call in the order it falls due");
		repeat.cancel();
		system.now = 104.5;
		time.poll();
		check(calls.length == 4 && repeat.done, "cancelled: no more calls");

		var inner = 0;
		time.after(0, () -> time.after(0, () -> inner++));
		system.now = 104.6;
		time.poll();
		check(inner == 0, "a timer made inside a call waits for the next poll");
		system.now = 104.7;
		time.poll();
		check(inner == 1, "and is called then");

		var paused = 0;
		time.after(.05, () -> paused++);
		time.paused = true;
		system.now = 104.9;
		time.poll();
		check(paused == 0, "timers wait while paused");
		time.paused = false;
		system.now = 105;
		time.poll();
		check(paused == 1, "and run after");

		var refused = try {
			time.every(0, () -> {});
			false;
		} catch (e:String)
			true;
		check(refused, "every refuses an interval of 0");

		var left = time.every(1, () -> {});
		time.dispose();
		check(left.done, "dispose cancels every timer");
		check(time.elapsed > start, "elapsed sums the deltas");
		var paced = new Time(system);
		check(paced.fps == 0 && paced.getRemaining() == 0, "fps 0 before a frame; no target, nothing left");
		for (_ in 0...40) {
			system.now += .02;
			paced.poll();
		}
		check(Math.abs(paced.fps - 50) < 1e-6, "fps: 50 from frames of a fiftieth of a second");
		paced.targetDelta = 1 / 30;
		system.now += .01;
		check(Math.abs(paced.getRemaining() - (1 / 30 - .01)) < 1e-9, "what's left of the frame aimed for");
		system.now += .05;
		check(paced.getRemaining() == 0, "none past it");
		paced.targetDelta = -1;
		check(paced.targetDelta == 0, "a negative target is none");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
