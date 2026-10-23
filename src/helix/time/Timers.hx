package helix.time;

import helix.time.Timer;

/** Timers on a clock: after(seconds, f) runs f once, every(seconds, f) runs it each interval, both measured in the clock's deltas (Clock.delta, so
	a stall fires each once, not a burst) when update runs each frame. Those due in one update fire in the order made; one made or cancelled
	inside a callback takes effect from the next update. */
class Timers {
	var timers:Array<Timer> = [];
	var updating = false;
	var pending:Array<Timer> = [];

	/** No timers yet. */
	public function new() {}

	/** Runs f once, seconds from now (at once on the next update for 0 or less). */
	public function after(seconds:Float, f:Void->Void):Timer
		return add(new Timer(seconds, false, f));

	/** Runs f every seconds, starting one interval from now, until cancelled. Throws for an interval of 0 or less, which would never stop firing. */
	public function every(seconds:Float, f:Void->Void):Timer {
		if (!(seconds > 0))
			throw 'Timers.every needs an interval over 0, not $seconds';
		return add(new Timer(seconds, true, f));
	}

	/** How many are set (running or waiting), done ones gone. */
	public var count(get, never):Int;

	function get_count():Int
		return timers.length + pending.length;

	/** Cancels every timer. */
	public function clear():Void {
		for (t in timers)
			t.cancel();
		for (t in pending)
			t.cancel();
		timers = [];
		pending = [];
	}

	/** Advances every timer by delta seconds (a clock's delta) and runs those due. Once a frame. */
	public function update(delta:Float):Void {
		if (delta < 0)
			delta = 0;
		updating = true;
		for (t in timers)
			t.advance(delta);
		updating = false;
		var kept = [];
		for (t in timers)
			if (!t.done)
				kept.push(t);
		for (t in pending)
			if (!t.done)
				kept.push(t);
		pending = [];
		timers = kept;
	}

	function add(timer:Timer):Timer {
		(updating ? pending : timers).push(timer);
		return timer;
	}
}
