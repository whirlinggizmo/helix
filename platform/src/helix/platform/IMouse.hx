package helix.platform;

/** Defines the mouse: `MouseMove`, `MouseDown`, `MouseUp`, `MouseLeave` and `Wheel` in `IEvents.events` while it exists.

	Its adapter is constructed over the events adapter, whose `poll` delivers its events. A pen counts as the mouse. */
interface IMouse {
	/** Stops listening to the mouse. */
	function dispose():Void;
}
