package helix.time;

import helix.host.FrameClock;

/** A game's time, from the frames' (FrameClock): scaled and paused as a whole, so everything fed by it (a Ticker's steps, tweens, timers,
	animators, emitters) slows, stops and resumes together, with nothing else to flag. Time.clock is the program's, updated by the runner
	before each frame; a game keeps more where times differ: a menu's clock running while the world's is paused (Unity's unscaled time). Each
	frame has two measures, as FrameClock's: the delta, held at MAX_DELTA (a stall moves animation on by that much), and the elapsed time,
	unheld, for a Ticker, which bounds its own catch-up. Both are 0 while paused. */
class Clock {
	/** A clock at 0, running at the frames' pace. */
	public function new() {}

	/** Advances by frameElapsed seconds of the frames' time (Time.frameElapsed), scaled; nothing while paused. Once a frame. */
	public function update(frameElapsed:Float):Void {
		elapsed = paused ? 0 : Math.max(0, frameElapsed) * timeScale;
		delta = elapsed > FrameClock.MAX_DELTA ? FrameClock.MAX_DELTA : elapsed;
		time += delta;
	}

	/** This frame's delta in its seconds: the elapsed time held at FrameClock.MAX_DELTA, for animation; 0 while paused. */
	public var delta(default, null):Float = 0.;

	/** This frame's elapsed time in its seconds, unheld, for a Ticker; 0 while paused. */
	public var elapsed(default, null):Float = 0.;

	/** Its seconds so far: the deltas summed (what animation has seen), not moving while paused. */
	public var time(default, null):Float = 0.;

	/** How fast it runs against the frames: 1 as they do, 0.5 slow motion, 0 still. 0 or more (under 0, or NaN, is 0). */
	public var timeScale(default, set):Float = 1.;

	function set_timeScale(value:Float):Float {
		value = value >= 0 ? value : 0;
		timeScale = value;
		return value;
	}

	/** Whether it's paused: updates give 0 until resume. */
	public var paused(default, null):Bool = false;

	/** Stops it; the time scale is kept for resume. */
	public function pause():Void
		paused = true;

	/** Runs it on from where it stopped. */
	public function resume():Void
		paused = false;
}
