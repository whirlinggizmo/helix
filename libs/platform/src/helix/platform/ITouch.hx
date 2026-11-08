package helix.platform;

/** Defines touch: `TouchDown`, `TouchMove` and `TouchUp` in `IEvents.events` while it exists.

	Its adapter is constructed over the events adapter, whose `poll` delivers its events. A finger is never reported as the mouse, and a trackpad's fingers aren't touch. */
interface ITouch {
	/** Gets a value indicating whether the device has touch. A trackpad isn't touch. */
	var available(get, never):Bool;

	/** Stops listening to touch. */
	function dispose():Void;
}
