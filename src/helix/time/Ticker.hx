package helix.time;

import helix.input.IInput;

/** A fixed-rate simulation inside the frame callback, fed a clock's elapsed time (Clock.elapsed: paused or scaled there, so the ticks are
	too). Each tick sees the input's tick edges, consumed after it, so a press is seen by exactly one tick. fraction is how far the frame is
	between the last tick and the next, for drawing between them. */
class Ticker {
	// The input given, or null for the program's (Input), read when used.
	var given:Null<IInput>;
	var input(get, never):IInput;

	function get_input():IInput
		return given != null ? given : helix.input.Input.instance;

	var accumulator = 0.;

	/** Ticks at rate a second (clamped as the rate property is), consuming input's tick edges after each: the program's (Input) when not
		given, read as it's used, so a ticker made before the program runs (a field's initial value) works. */
	public function new(rate = 60., ?input:IInput) {
		given = input;
		this.rate = rate;
	}

	/** Ticks a second. At least 1e-6 (0 or less, or NaN, is 1e-6). */
	public var rate(default, set):Float = 60.;

	function set_rate(value:Float):Float {
		value = value > 1e-6 ? value : 1e-6;
		rate = value;
		delta = 1 / value;
		return value;
	}

	/** Seconds a tick simulates. */
	public var delta(default, null):Float = 1 / 60;

	/** How far the frame is from the last tick to the next, from 0 to under 1. */
	public var fraction(default, null):Float = 0.;

	/** Ticks run in one frame at most; a longer stall loses the rest rather than spiralling. At least 1. */
	public var maxSteps(default, set):Int = 8;

	function set_maxSteps(value:Int):Int {
		value = value > 1 ? value : 1;
		maxSteps = value;
		return value;
	}

	/** Runs tick for each step due after elapsed seconds (a Clock's elapsed, Time.clock's for the game's time), at most maxSteps of
		them; returns how many ran. */
	public function advance(elapsed:Float, tick:Void->Void):Int {
		accumulator += Math.max(0, elapsed);
		var steps = 0;
		while (accumulator >= delta && steps < maxSteps) {
			tick();
			input.consume();
			accumulator -= delta;
			steps++;
		}
		if (accumulator >= delta)
			accumulator %= delta;
		fraction = accumulator / delta;
		return steps;
	}
}
