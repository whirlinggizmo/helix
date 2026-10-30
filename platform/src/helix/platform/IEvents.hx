package helix.platform;

/** Defines the input and window events, polled once a frame, and the gamepads' state.

	Each `poll` delivers what happened as `Event` records, in the order the OS reported them. That covers keys, text, the mouse, touches,
	a pad connecting, a pad's buttons, and the window being resized, focused or closed. Nothing is delivered between polls, and nothing
	calls the program. The program walks `events` itself.

	What is held, such as a stick, a trigger or a pad's buttons, can also be read directly after a poll.

	Natively, a button pressed and released between two polls arrives as both events. A page reads its pads only at each poll, so it sees
	a press only if the button is down then.

	```haxe
	events.poll();
	for (event in events.events)
		switch event {
			case KeyDown(key, _): pressed(key);
			case CloseRequested: window.close();
			case _:
		}
	var stick = events.getPadAxis(0, 0);
	```
 */
interface IEvents extends IPollable {
	/** Drains the OS's queue into `events`.

		`events` then holds this frame's events, in order. Last frame's events are cleared. */
	function poll():Void;

	/** Gets the events the last `poll` delivered. The array is reused by the next poll. */
	var events(get, never):Array<Event>;

	/** Sleeps in the OS until an event arrives or the timeout passes, using no CPU.

		It does nothing in a page. A native loop calls it while the window can't be seen (after `Hidden`), so the loop doesn't spin. The
		loop wakes at the timeout to service what must not starve. Events that arrive stay for the next `poll`.
		@param timeout  The longest wait, in seconds. */
	function wait(timeout:Float):Void;

	/** Starts or stops typed text input.

		`Text` events arrive only while it is on, and a phone shows its keyboard then.

		@param on  True to start. */
	function setTextInput(on:Bool):Void;

	/** Starts or stops reading the device's orientation as `Tilt` events.

		A page may need the player's permission, which is asked at the player's next tap. `TiltState` events report each change: waiting for
		that tap, on, refused, unavailable, and off again when it's turned off.
		@param on  True to start. */
	function setTiltWanted(on:Bool):Void;

	/** Returns whether a gamepad is in a slot, as of the last `poll`.

		@param slot  The slot, 0 to 3.
		@return  True when one is connected there. */
	function isPadConnected(slot:Int):Bool;

	/** Returns the name of the gamepad in a slot.

		@param slot  The slot, 0 to 3.
		@return  The name, or "" when the slot is empty. */
	function getPadName(slot:Int):String;

	/** Returns whether a gamepad's button is down, as of the last `poll`.

		@param slot  The slot, 0 to 3.
		@param button  The button.
		@return  True when it is down; false for an empty slot. */
	function isPadButtonDown(slot:Int, button:PadButton):Bool;

	/** Returns a gamepad's axis, as of the last `poll`.

		@param slot  The slot, 0 to 3.
		@param axis  The axis.
		@return  The axis's value. A stick runs from -1 to 1, with down and right positive. A trigger runs from 0 to 1. An empty slot gives
			0. */
	function getPadAxis(slot:Int, axis:PadAxis):Float;

	/** Releases the events' resources, which are its listeners and the gamepads. */
	function dispose():Void;
}
