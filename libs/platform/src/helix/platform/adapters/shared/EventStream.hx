package helix.platform.adapters.shared;

import helix.platform.Event;

/** Holds the one stream of events an events adapter delivers and the device adapters built over it add to, in the order they happened.

	Listeners record between polls; the poll delivers what was recorded, then what the devices read at it. */
@:noCompletion
class EventStream {
	/** Gets the events the last poll delivered. */
	public final delivered:Array<Event> = [];

	/** Gets what a device reads at each poll, after what was recorded is delivered: a page's gamepads, a request's answers. */
	public final polls:Array<Void->Void> = [];

	/** Gets what a device lets go of just before `FocusLost` is recorded: a page's held keys, which get no keyup while it hasn't the
		keyboard. */
	public final focusLosses:Array<Void->Void> = [];

	/** Gets a value indicating whether `Unlocked` has been delivered. */
	public var unlocked(default, null) = false;

	final recorded:Array<Event> = [];

	/** Creates an empty stream. */
	public function new() {}

	/** Records an event for the next poll.

		@param event  The event. */
	public function record(event:Event):Void {
		if (event.match(FocusLost))
			for (lose in focusLosses)
				lose();
		recorded.push(event);
	}

	/** Starts a poll: last poll's events are cleared, and what was recorded since is delivered. */
	public function begin():Void {
		delivered.resize(0);
		for (event in recorded)
			deliver(event);
		recorded.resize(0);
	}

	/** Delivers an event in this poll.

		@param event  The event. */
	public function deliver(event:Event):Void {
		if (event.match(Unlocked))
			unlocked = true;
		delivered.push(event);
	}

	/** Ends a poll: each device reads what it reads at it. */
	public function end():Void {
		for (poll in polls)
			poll();
	}
}
