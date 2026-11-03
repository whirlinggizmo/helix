package helix.services.time;

/** Represents a function called after some of the game's time, once (`Time.after`) or repeatedly (`Time.every`). */
@:allow(helix.services.time)
class Timer {
	/** The game's elapsed seconds at which it is next called. */
	var due:Float;

	/** The order it was made in, which breaks a tie between timers due at once. */
	var order:Int;

	/** Whether it was created during its time's poll, so it waits for the next. */
	var fresh = false;

	final f:Void->Void;

	function new(due:Float, interval:Float, order:Int, f:Void->Void) {
		this.due = due;
		this.interval = interval;
		this.order = order;
		this.f = f;
	}

	/** Gets the game's seconds until the next call. It is updated at each `Time.poll`. */
	public var remaining(default, null):Float = 0;

	/** Gets the game's seconds between calls for a repeating timer, or 0 for one called once. */
	public var interval(default, null):Float = 0;

	/** Gets a value indicating whether the timer will call its function no more, because it was called once or cancelled. */
	public var done(default, null):Bool = false;

	/** Cancels the timer, so its function isn't called again. Does nothing once it is done. */
	public function cancel():Void {
		done = true;
	}
}
