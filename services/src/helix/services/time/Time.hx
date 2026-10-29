package helix.services.time;

import helix.platform.IPollable;
import helix.platform.ISystem;

/** Provides a frame's time: the game's seconds, which can be scaled and paused and have timers on them, and the real seconds beside them.

	The program constructs one and calls `poll` once a frame; game code then moves by `delta`. Something that must keep time while the
	game is paused, such as a menu's animation, moves by `realDelta`, or by a second `Time` of its own.

	```haxe
	var time = new Time(system);
	time.every(1, () -> trace('at $x, $y'));
	// each frame:
	time.poll();
	x += speed * time.delta;
	``` */
class Time implements IPollable {
	/** The least `maxDelta` may be: a millisecond. */
	static inline final LEAST_MAX_DELTA = .001;

	final system:ISystem;
	var last:Float;
	var timers:Array<Timer> = [];
	var made = 0;
	var polling = false;

	/** Creates the game's time at 0.

		@param system  The platform's facts: it reads their monotonic time (`getTime`). */
	public function new(system:ISystem) {
		this.system = system;
		last = system.getTime();
	}

	/** Gets the game's seconds this frame: the real seconds times `scale`, and 0 while paused. */
	public var delta(default, null):Float = 0;

	/** Gets the real seconds this frame: not scaled, running while paused, at most `maxDelta`. */
	public var realDelta(default, null):Float = 0;

	/** Gets the game's seconds since this was made: the sum of every `delta`. */
	public var elapsed(default, null):Float = 0;

	/** Gets or sets how fast the game's time runs: 1 as real time, 2 twice as fast, 0 stopped; 0 or more, a negative one
		being 0; 1 by default. */
	public var scale(default, set):Float = 1;

	function set_scale(value:Float):Float {
		return scale = value > 0 ? value : 0;
	}

	/** Gets or sets a value indicating whether the game's time stands still: `delta` is 0 and the timers wait; false by default. */
	public var paused:Bool = false;

	/** Gets or sets the most real seconds one frame counts, so a frame after a stall (a page in the background, a debugger) doesn't jump;
		more than 0, 0.25 by default. */
	public var maxDelta(default, set):Float = 0.25;

	function set_maxDelta(value:Float):Float {
		return maxDelta = value > LEAST_MAX_DELTA ? value : LEAST_MAX_DELTA;
	}

	/** Calls a function once, after some of the game's time.

		@param seconds  The game's seconds from now; 0 or less calls it at the next `poll`.
		@param f  The function.
		@return  The timer, to cancel it. */
	public function after(seconds:Float, f:Void->Void):Timer {
		return add(new Timer(elapsed + (seconds > 0 ? seconds : 0), 0, made++, f));
	}

	/** Calls a function each time some of the game's time passes, until it's cancelled.

		A frame longer than the interval calls it once for each interval it holds.
		@param seconds  The game's seconds between calls, more than 0.
		@param f  The function.
		@return  The timer, to cancel it.
		@throws String  For seconds of 0 or less. */
	public function every(seconds:Float, f:Void->Void):Timer {
		if (!(seconds > 0))
			throw 'every needs an interval more than 0, not $seconds';
		return add(new Timer(elapsed + seconds, seconds, made++, f));
	}

	/** Measures this frame from the platform's time, and calls the timers that are due, in the order they fall due; call once a frame. */
	public function poll():Void {
		var now = system.getTime();
		var real = now - last;
		last = now;
		realDelta = real > maxDelta ? maxDelta : real > 0 ? real : 0;
		delta = paused ? 0 : realDelta * scale;
		elapsed += delta;
		for (timer in timers)
			timer.fresh = false;
		// One at a time, the earliest due first, so a repeating timer whose next call also falls in this frame takes its turn among the
		// others; a timer made by one of them waits for the next poll.
		polling = true;
		while (true) {
			var next:Timer = null;
			for (timer in timers)
				if (!timer.done
					&& !timer.fresh
					&& timer.due <= elapsed
					&& (next == null || timer.due < next.due || (timer.due == next.due && timer.order < next.order)))
					next = timer;
			if (next == null)
				break;
			if (next.interval > 0)
				next.due += next.interval;
			else
				next.done = true;
			next.f();
		}
		polling = false;
		timers = [for (timer in timers) if (!timer.done) timer];
		for (timer in timers)
			timer.remaining = timer.due - elapsed;
	}

	/** Cancels every timer. */
	public function dispose():Void {
		for (timer in timers)
			timer.cancel();
		timers = [];
	}

	function add(timer:Timer):Timer {
		timer.fresh = polling;
		timer.remaining = timer.due - elapsed;
		timers.push(timer);
		return timer;
	}
}
