package helix.services.time;

import haxe.exceptions.NotImplementedException;
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
	/** Creates the game's time at 0.

		@param system  The platform's facts: it reads their monotonic time (`getTime`). */
	public function new(system:ISystem) {
		throw new NotImplementedException();
	}

	/** Gets the game's seconds this frame: the real seconds times `scale`, and 0 while paused. */
	public var delta(default, null):Float = 0;

	/** Gets the real seconds this frame: not scaled, running while paused, at most `maxDelta`. */
	public var realDelta(default, null):Float = 0;

	/** Gets the game's seconds since this was made: the sum of every `delta`. */
	public var elapsed(default, null):Float = 0;

	/** Gets or sets how fast the game's time runs: 1 as real time, 2 twice as fast, 0 stopped; 0 or more, 1 by default. */
	public var scale(default, set):Float = 1;

	function set_scale(value:Float):Float {
		throw new NotImplementedException();
	}

	/** Gets or sets a value indicating whether the game's time stands still: `delta` is 0 and the timers wait; false by default. */
	public var paused:Bool = false;

	/** Gets or sets the most real seconds one frame counts, so a frame after a stall (a page in the background, a debugger) doesn't jump;
		more than 0, 0.25 by default. */
	public var maxDelta(default, set):Float = 0.25;

	function set_maxDelta(value:Float):Float {
		throw new NotImplementedException();
	}

	/** Calls a function once, after some of the game's time.

		@param seconds  The game's seconds from now; 0 or less calls it at the next `poll`.
		@param f  The function.
		@return  The timer, to cancel it. */
	public function after(seconds:Float, f:Void->Void):Timer {
		throw new NotImplementedException();
	}

	/** Calls a function each time some of the game's time passes, until it's cancelled.

		A frame longer than the interval calls it once for each interval it holds.
		@param seconds  The game's seconds between calls, more than 0.
		@param f  The function.
		@return  The timer, to cancel it. */
	public function every(seconds:Float, f:Void->Void):Timer {
		throw new NotImplementedException();
	}

	/** Measures this frame from the platform's time, and calls the timers that are due, in the order they fall due; call once a frame. */
	public function poll():Void {
		throw new NotImplementedException();
	}

	/** Cancels every timer. */
	public function dispose():Void {
		throw new NotImplementedException();
	}
}
