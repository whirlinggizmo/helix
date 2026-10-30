package helix.platform;

/** Defines the gamepads, in slots 0 to 3: `PadConnected`, `PadDisconnected`, `PadButtonDown` and `PadButtonUp` in `IEvents.events`
	while it exists, and each pad's state as of the last `IEvents.poll`.

	Its adapter is constructed over the events adapter, whose `poll` delivers its events and reads the pads. Natively, a button pressed and
	released between two polls arrives as both events. A page reads its pads only at each poll, so it sees a press only if the button is
	down then.

	```haxe
	var stick = gamepads.getAxis(0, LeftX);
	``` */
interface IGamepads {
	/** Returns whether a gamepad is in a slot.

		@param slot  The slot, 0 to 3.
		@return  True when one is connected there. */
	function isConnected(slot:Int):Bool;

	/** Returns the name of the gamepad in a slot.

		@param slot  The slot, 0 to 3.
		@return  The name, or "" when the slot is empty. */
	function getName(slot:Int):String;

	/** Returns whether a gamepad's button is down.

		@param slot  The slot, 0 to 3.
		@param button  The button.
		@return  True when it is down; false for an empty slot. */
	function isButtonDown(slot:Int, button:PadButton):Bool;

	/** Returns a gamepad's axis.

		@param slot  The slot, 0 to 3.
		@param axis  The axis.
		@return  The axis's value. A stick runs from -1 to 1, with down and right positive. A trigger runs from 0 to 1. An empty slot gives
			0. */
	function getAxis(slot:Int, axis:PadAxis):Float;

	/** Stops reading the gamepads and lets them go. */
	function dispose():Void;
}
