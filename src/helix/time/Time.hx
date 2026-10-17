package helix.time;

import helix.host.Runner;

/** The program's time: the host's clock, the frames' timings and the game's clock (clock), which tickers, tweens, timers, animators and
	emitters are fed. The program's one, a static class over the runner's frame clock, bound by the runner from its init to its cleanup. */
@:allow(helix.host.Runner)
class Time {
	/** The game's time: the frames' time scaled and paused as a whole (Clock), updated before each frame; what tickers, tweens, timers,
		animators and emitters are fed. Null outside the runner's init and cleanup. Kept across a hot reload (@:hot): set once by the runner,
		nothing would set it again. */
	@:hot public static var clock(default, null):Clock;

	// The runner the frame's timings are read from; kept across a hot reload (@:hot), as clock is.
	@:hot static var runner:Runner;

	// The runner's, at its init (with the program's clock) and its cleanup (nulls).
	static function bind(runner:Null<Runner>, clock:Null<Clock>):Void {
		Time.runner = runner;
		Time.clock = clock;
	}

	/** Seconds on the host's monotonic clock. */
	public static var time(get, never):Float;

	static function get_time():Float
		return runner.host.time;

	/** The seconds since the last frame, unheld (the app's frame dt is held at 0.1), and 0 on the first: what a fixed-rate simulation
		(Ticker.advance) is fed, so a slow frame is caught up in ticks instead of lost. */
	public static var frameElapsed(get, never):Float;

	static function get_frameElapsed():Float
		return runner.clock.elapsed;

	/** The last frame's CPU time in milliseconds, its services' polls included. */
	public static var frameCpu(get, never):Float;

	static function get_frameCpu():Float
		return runner.frameCpu;

	/** Milliseconds between the last two frames' starts (0 for the first). */
	public static var frameInterval(get, never):Float;

	static function get_frameInterval():Float
		return runner.frameInterval;
}
