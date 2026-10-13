package helix.app;

import helix.input.IInput;

/** A fixed-rate simulation inside the frame callback. Each tick sees the input's tick edges, consumed after it, so a press is seen by exactly one tick.
	getFraction is how far the frame is between the last tick and the next, for drawing between them. */
class Ticker {
	var rate = 60.;
	var delta = 1 / 60;
	var timeScale = 1.;
	var fraction = 0.;
	var maxSteps = 8;
	var input:IInput;
	var accumulator = 0.;

	/** Ticks at rate a second, consuming input's tick edges after each; a rate of 0 or less keeps 60. */
	public function new(input:IInput, rate = 60.) {
		this.input = input;
		setRate(rate);
	}

	/** Ticks a second. */
	public function getRate():Float
		return rate;

	/** False for a rate of 0 or less. */
	public function setRate(value:Float):Bool {
		if (!(value > 0))
			return false;
		rate = value;
		delta = 1 / value;
		return true;
	}

	/** Seconds a tick simulates. */
	public function getDelta():Float
		return delta;

	/** Scales simulated time: 0 pauses the ticks while frames go on. */
	public function getTimeScale():Float
		return timeScale;

	/** False for a scale under 0. */
	public function setTimeScale(value:Float):Bool {
		if (!(value >= 0))
			return false;
		timeScale = value;
		return true;
	}

	/** How far the frame is from the last tick to the next, from 0 to under 1. */
	public function getFraction():Float
		return fraction;

	/** Ticks run in one frame at most; a longer stall loses the rest rather than spiralling. */
	public function getMaxSteps():Int
		return maxSteps;

	/** False for fewer than 1. */
	public function setMaxSteps(value:Int):Bool {
		if (value < 1)
			return false;
		maxSteps = value;
		return true;
	}

	/** Runs tick for each step due after dt seconds; returns how many ran. */
	public function advance(dt:Float, tick:Void->Void):Int {
		accumulator += Math.max(0, Math.min(dt, .25)) * timeScale;
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
