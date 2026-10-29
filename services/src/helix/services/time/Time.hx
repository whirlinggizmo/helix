package helix.services.time;

import helix.platform.IPollable;
import helix.platform.ISystem;

/** Provides a frame's time, in the game's seconds and in real seconds.

	The game's seconds can be scaled and paused, and timers run on them. The program constructs one `Time` and calls `poll` once a frame.
	Game code then moves by `delta`. Something that must keep time while the game is paused, such as a menu's animation, moves by
	`realDelta`, or by a second `Time` of its own.

	```haxe
	var time = new Time(system);
	time.every(1, () -> trace('at $x, $y'));
	// each frame:
	time.poll();
	x += speed * time.delta;
	``` */
class Time implements IPollable {
	/** The least `maxDelta` may be, a millisecond. */
	static inline final LEAST_MAX_DELTA = .001;

	final system:ISystem;
	var last:Float;
	var timers:Array<Timer> = [];
	var made = 0;
	var polling = false;

	/** Creates the game's time, starting at 0.

		@param system  The platform's system, whose monotonic time (`getTime`) it reads. */
	public function new(system:ISystem) {
		this.system = system;
		last = system.getTime();
	}

	/** Gets the game's seconds this frame, which is `realDelta` times `scale`, or 0 while paused. */
	public var delta(default, null):Float = 0;

	/** Gets the real seconds this frame, at most `maxDelta`. It isn't scaled, and it keeps running while paused. */
	public var realDelta(default, null):Float = 0;

	/** Gets the game's seconds since this `Time` was created, which is the sum of every `delta`. */
	public var elapsed(default, null):Float = 0;

	/** Gets or sets how fast the game's time runs. Defaults to 1.

		1 runs as real time, 2 twice as fast, and 0 stops it. A negative value is clamped to 0. */
	public var scale(default, set):Float = 1;

	function set_scale(value:Float):Float {
		return scale = value > 0 ? value : 0;
	}

	/** Gets or sets a value indicating whether the game's time stands still. Defaults to false.

		While paused, `delta` is 0 and the timers wait. */
	public var paused:Bool = false;

	/** Gets or sets the most real seconds one frame counts. Defaults to 0.25, and is clamped to at least 0.001.

		It keeps a frame after a stall, such as a page in the background or a debugger, from jumping ahead. */
	public var maxDelta(default, set):Float = 0.25;

	function set_maxDelta(value:Float):Float {
		return maxDelta = value > LEAST_MAX_DELTA ? value : LEAST_MAX_DELTA;
	}

	/** Calls a function once, after some of the game's time.

		@param seconds  The game's seconds from now. 0 or less calls it at the next `poll`.
		@param f  The function.
		@return  The timer, which cancels the call. */
	public function after(seconds:Float, f:Void->Void):Timer {
		return add(new Timer(elapsed + (seconds > 0 ? seconds : 0), 0, made++, f));
	}

	/** Calls a function each time an interval of the game's time passes, until it is cancelled.

		A frame longer than the interval calls it once for each interval the frame holds.

		@param seconds  The game's seconds between calls. Must be more than 0.
		@param f  The function.
		@return  The timer, which cancels the calls.
		@throws String  When seconds is 0 or less. */
	public function every(seconds:Float, f:Void->Void):Timer {
		if (!(seconds > 0))
			throw 'every needs an interval more than 0, not $seconds';
		return add(new Timer(elapsed + seconds, seconds, made++, f));
	}

	/** Measures this frame from the platform's time, and calls the timers that are due, in the order they fall due.

		Call it once a frame. A timer created by a timer's function waits for the next `poll`. */
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
