package helix.time;

import helix.host.FrameClock;

/** A game's time, from the frames' (FrameClock): scaled and paused as a whole, so everything fed by it (a Ticker's steps, tweens, timers,
	animators, emitters) slows, stops and resumes together, with nothing else to flag. Services.clock is the program's, updated by the runner
	before each frame; a game keeps more where times differ: a menu's clock running while the world's is paused (Unity's unscaled time). Each
	frame has two measures, as FrameClock's: the delta, held at MAX_DELTA (a stall moves animation on by that much), and the elapsed time,
	unheld, for a Ticker, which bounds its own catch-up. Both are 0 while paused. */
class Clock {
	var timeScale = 1.;
	var paused = false;
	var delta = 0.;
	var elapsed = 0.;
	var time = 0.;

	/** A clock at 0, running at the frames' pace. */
	public function new() {}

	/** Advances by frameElapsed seconds of the frames' time (Services.getFrameElapsed), scaled; nothing while paused. Once a frame. */
	public function update(frameElapsed:Float):Void {
		elapsed = paused ? 0 : Math.max(0, frameElapsed) * timeScale;
		delta = elapsed > FrameClock.MAX_DELTA ? FrameClock.MAX_DELTA : elapsed;
		time += delta;
	}

	/** This frame's delta in its seconds: the elapsed time held at FrameClock.MAX_DELTA, for animation; 0 while paused. */
	public function getDelta():Float
		return delta;

	/** This frame's elapsed time in its seconds, unheld, for a Ticker; 0 while paused. */
	public function getElapsed():Float
		return elapsed;

	/** Its seconds so far: the deltas summed (what animation has seen), not moving while paused. */
	public function getTime():Float
		return time;

	/** How fast it runs against the frames: 1 as they do, 0.5 slow motion, 0 still. */
	public function getTimeScale():Float
		return timeScale;

	/** Sets how fast it runs; false, changing nothing, for a scale under 0. */
	public function setTimeScale(value:Float):Bool {
		if (!(value >= 0))
			return false;
		timeScale = value;
		return true;
	}

	/** Whether it's paused: updates give 0 until resume. */
	public function isPaused():Bool
		return paused;

	/** Stops it; the time scale is kept for resume. */
	public function pause():Void
		paused = true;

	/** Runs it on from where it stopped. */
	public function resume():Void
		paused = false;
}
