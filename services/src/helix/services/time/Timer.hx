package helix.services.time;

import haxe.exceptions.NotImplementedException;

/** Represents a function called after some of a clock's game time, once or repeatedly (`Clock.after`, `Clock.every`). */
class Timer {
	@:allow(helix.services.time)
	function new() {}

	/** Gets the game's seconds until the next call. */
	public var remaining(default, null):Float = 0;

	/** Gets the game's seconds between calls for a repeating timer, or 0 for one called once. */
	public var interval(default, null):Float = 0;

	/** Gets a value indicating whether it will call its function no more: called once, or cancelled. */
	public var done(default, null):Bool = false;

	/** Stops it: its function isn't called again. Does nothing once it's done. */
	public function cancel():Void {
		throw new NotImplementedException();
	}
}
