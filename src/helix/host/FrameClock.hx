package helix.host;

/** A host's frame timing, the same on every target, measured on the host's own clock between frames that ran (not a smoothed estimate, whose
	sum drifts from wall time). Each frame has two measures: the delta, the dt IApp.update is passed, held between MIN_DELTA and MAX_DELTA for animation; and the
	elapsed time, unheld, for a fixed-rate simulation (Ticker), which bounds its own catch-up. */
class FrameClock {
	/** The least delta, in seconds. */
	public static inline var MIN_DELTA = 1e-6;

	/** The most delta, in seconds: past a longer stall (a hidden tab, a debugger) animation moves on by this much. */
	public static inline var MAX_DELTA = .1;

	var previous = -1.;

	/** A clock with no frame yet. */
	public function new() {}

	/** Starts a frame at now, seconds on the host's clock (IHost.time). */
	public function frame(now:Float):Void {
		elapsed = previous < 0 ? 0 : Math.max(0, now - previous);
		var dt = previous < 0 ? 1 / 60 : elapsed;
		delta = dt < MIN_DELTA ? MIN_DELTA : dt > MAX_DELTA ? MAX_DELTA : dt;
		previous = now;
	}

	/** This frame's delta in seconds: the time since the last frame, held between MIN_DELTA and MAX_DELTA, and 1/60 on the first, which has
		nothing to measure from. */
	public var delta(default, null):Float = 1 / 60;

	/** This frame's elapsed time in seconds: the time since the last frame, unheld, and 0 on the first. */
	public var elapsed(default, null):Float = 0.;
}
