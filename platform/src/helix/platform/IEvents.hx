package helix.platform;

/** Defines the input and the window's events, pulled once a frame, and the gamepads' state.

	What happens (keys, text, the mouse, touches, a pad connecting, a pad's buttons, the window resized, focused or closed) arrives as
	`Event` records from `poll`, in the order the OS gave them; natively a button pressed and let go between two polls arrives as both,
	while a page reads its pads only at each poll, so it sees one only if it is down then. What is held (a stick, a trigger, a pad's
	buttons) can also be read directly after it. Nothing is delivered between polls, and nothing calls the program: the owner walks
	`events`.

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
interface IEvents {
	/** Drains the OS's queue into `events`: this frame's events, in order. Last frame's are cleared. */
	function poll():Void;

	/** Gets the events the last `poll` delivered. The array is reused by the next poll. */
	var events(get, never):Array<Event>;

	/** Sleeps in the OS until an event arrives or the timeout passes, using no CPU; does nothing in a page.

		A native loop calls it while the window can't be seen (after `Hidden`), so it doesn't spin, waking at the timeout to service what
		must not starve. Events that arrive stay for the next `poll`.
		@param timeout  The longest wait, in seconds. */
	function wait(timeout:Float):Void;

	/** Starts or stops typed text: `Text` events arrive only while it is on, and a phone shows its keyboard then.

		@param on  True to start. */
	function setTextInput(on:Bool):Void;

	/** Starts or stops reading the device's orientation as `Tilt` events.

		A page may need the player's permission, asked at their next tap; `TiltState` events report how it went.
		@param on  True to start. */
	function setTiltWanted(on:Bool):Void;

	/** Gets a value indicating whether the player has pressed a key, a button or a finger yet: a browser allows audio and fullscreen only
		after that. Always true natively. */
	var activated(get, never):Bool;

	/** Returns whether a gamepad is in a slot, as of the last `poll`.

		@param slot  The slot, 0 to 3.
		@return  True when one is connected there. */
	function isPadConnected(slot:Int):Bool;

	/** Returns a slot's gamepad's name.

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
		@return  A stick from -1 to 1, down and right positive; a trigger from 0 to 1; 0 for an empty slot. */
	function getPadAxis(slot:Int, axis:PadAxis):Float;

	/** Releases the events' resources: listeners, the gamepads. */
	function dispose():Void;
}
