package helix.time;

/** One timer of a Timers set: cancelled by the game, or done once it has fired (a repeating one never is until cancelled). */
class Timer {
	var f:Null<Void->Void>;

	@:allow(helix.time.Timers)
	function new(seconds:Float, repeating:Bool, f:Void->Void) {
		interval = seconds;
		remaining = seconds;
		this.repeating = repeating;
		this.f = f;
	}

	/** Seconds until it fires (next), 0 or less when due. */
	public var remaining(default, null):Float;

	/** Its interval, the seconds it was set with. */
	public var interval(default, null):Float;

	/** Whether it repeats. */
	public var repeating(default, null):Bool;

	/** Whether it's over: cancelled, or fired once for a one-shot. */
	public var done(default, null):Bool = false;

	/** Stops it from firing again (nothing if it's done). */
	public function cancel():Void {
		done = true;
		f = null;
	}

	// Counts delta down and fires when due: once, or each interval it covers for a repeating one.

	@:allow(helix.time.Timers)
	function advance(delta:Float):Void {
		if (done)
			return;
		remaining -= delta;
		if (remaining > 0)
			return;
		if (!repeating) {
			done = true;
			var fire = f;
			f = null;
			if (fire != null)
				fire();
			return;
		}
		// A stall of several intervals fires once, and the next is a whole interval away.
		remaining = interval;
		if (f != null)
			f();
	}
}
