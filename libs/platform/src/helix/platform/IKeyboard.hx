package helix.platform;

/** Defines the keyboard: `KeyDown`, `KeyUp` and `Text` in `IEvents.events` while it exists.

	Its adapter is constructed over the events adapter, whose `poll` delivers its events. */
interface IKeyboard {
	/** Gets or sets whether typed text arrives, as `Text` events. A phone shows its keyboard while it is on. Defaults to false. */
	var textInput(get, set):Bool;

	/** Stops listening to the keyboard. */
	function dispose():Void;
}
