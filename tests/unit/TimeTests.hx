import helix.time.Clock;
import helix.time.Timers;

/** A game's time (helix.time.Clock): scaled, paused, held; and timers on it (Timers): once, every, cancelled, made and cancelled inside
	callbacks, a stall firing once. */
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
		// The clock.
		var clock = new Clock();
		check(clock.delta == 0 && clock.elapsed == 0 && clock.time == 0 && !clock.paused && clock.timeScale == 1, "A new clock is at 0, running");
		clock.update(1 / 60);
		check(near(clock.delta, 1 / 60) && near(clock.elapsed, 1 / 60) && near(clock.time, 1 / 60), "A frame's time goes by");
		clock.update(.5);
		check(near(clock.delta, .1) && near(clock.elapsed, .5) && near(clock.time, 1 / 60 + .1),
			"A stall's delta is held at 0.1 s, its elapsed time unheld, and the time takes the delta");
		clock.timeScale = -1;
		check(clock.timeScale == 0, "The scale is 0 or more");
		clock.timeScale = .5;
		clock.update(.02);
		check(near(clock.delta, .01) && near(clock.elapsed, .01), "Scaled time");
		clock.pause();
		var before = clock.time;
		clock.update(.02);
		check(clock.paused && clock.delta == 0 && clock.elapsed == 0 && clock.time == before, "Paused: nothing goes by");
		clock.resume();
		clock.update(.02);
		check(near(clock.delta, .01) && clock.timeScale == .5, "Resumed at the scale it had");
		clock.update(-1);
		check(clock.delta == 0, "A negative frame time is 0");

		// Timers.
		var timers = new Timers(), log = [];
		var once = timers.after(1, () -> log.push("once"));
		var tick = timers.every(.5, () -> log.push("tick"));
		check(timers.count == 2 && !once.done && once.remaining == 1 && tick.repeating && !once.repeating, "Two set");
		timers.update(.4);
		check(log.length == 0 && near(once.remaining, .6), "Not yet");
		timers.update(.1);
		check(log.join(",") == "tick", "The repeating one fires on its interval");
		timers.update(.5);
		check(log.join(",") == "tick,once,tick" && once.done && timers.count == 1, "Due together, they fire in the order made; a one-shot is done");
		timers.update(1.7);
		check(log.length == 4 && near(tick.remaining, .5), "A stall fires a repeating timer once, the next a whole interval away");
		tick.cancel();
		timers.update(1);
		check(tick.done && log.length == 4 && timers.count == 0, "Cancelled: fires no more, gone from the set");
		timers.after(0, () -> log.push("now"));
		timers.update(0);
		check(log[log.length - 1] == "now", "0 seconds fires at the next update");
		// Made and cancelled inside callbacks.
		var inner:Null<helix.time.Timer> = null;
		timers.after(.1, () -> {
			inner = timers.after(0, () -> log.push("inner"));
		});
		// The canceller made before its victim, so it runs first when both are due.
		var victim:Null<helix.time.Timer> = null;
		timers.after(.05, () -> victim.cancel());
		victim = timers.every(.1, () -> log.push("victim"));
		timers.update(.1);
		check(log.indexOf("inner") < 0 && log.indexOf("victim") < 0 && timers.count == 1,
			"One made in a callback waits for the next update; one cancelled there doesn't fire");
		timers.update(0);
		check(log[log.length - 1] == "inner", "and fires then");
		var threw = false;
		try
			timers.every(0, () -> {})
		catch (e:Dynamic)
			threw = true;
		check(threw, "every refuses an interval of 0");
		timers.after(5, () -> log.push("never"));
		timers.clear();
		timers.update(10);
		check(timers.count == 0 && log.indexOf("never") < 0, "clear cancels everything");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
