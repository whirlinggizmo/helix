package helix.services.time;

/** Represents a function called after some of the game's time, once or repeatedly (`Time.after`, `Time.every`). */
@:allow(helix.services.time)
class Timer {
	/** The game's elapsed seconds at which it's next called. */
	var due:Float;

	/** The order it was made in, which breaks a tie between timers due at once. */
	var order:Int;

	/** Whether it was made during its time's poll, so it waits for the next. */
	var fresh = false;

	final f:Void->Void;

	function new(due:Float, interval:Float, order:Int, f:Void->Void) {
		this.due = due;
		this.interval = interval;
		this.order = order;
		this.f = f;
	}

	/** Gets the game's seconds until the next call. */
	public var remaining(default, null):Float = 0;

	/** Gets the game's seconds between calls for a repeating timer, or 0 for one called once. */
	public var interval(default, null):Float = 0;

	/** Gets a value indicating whether it will call its function no more: called once, or cancelled. */
	public var done(default, null):Bool = false;

	/** Stops it: its function isn't called again. Does nothing once it's done. */
	public function cancel():Void {
		done = true;
	}
}
