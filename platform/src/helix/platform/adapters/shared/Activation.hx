package helix.platform.adapters.shared;

import helix.platform.Event;

/** Puts `Event.Activated` before the player's first press, the same way for every events adapter: a key or a mouse button as it goes
	down, a finger as it lifts, as a browser counts them (a phone's tap activates on its lift, not its landing). */
@:noCompletion
class Activation {
	/** Inserts `Activated` before the first key or mouse button going down, or finger lifting, among a poll's events, once.

		@param events  The poll's events, in order.
		@param activated  Whether `Activated` was already delivered.
		@return  Whether it has been delivered now. */
	public static function mark(events:Array<Event>, activated:Bool):Bool {
		if (activated)
			return true;
		for (i in 0...events.length)
			switch events[i] {
				case KeyDown(_, _) | MouseDown(_, _, _) | TouchUp(_, _, _):
					events.insert(i, Activated);
					return true;
				case _:
			}
		return false;
	}
}
