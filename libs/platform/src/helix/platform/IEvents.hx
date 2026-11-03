package helix.platform;

/** Defines the events, polled once a frame: what happens to the window, the player's first press, and what the devices built over it
	add.

	Each `poll` delivers what happened as `Event` records, in the order the OS reported them. Without a device, that is the window being
	resized, focused, shown, hidden or closed, its graphics lost, and `Unlocked`. A device's adapter, constructed over the events adapter,
	adds its own events to the same records: `IKeyboard` keys and text, `IMouse` the mouse, `ITouch` fingers, `IGamepads` pads and
	`ITilt` the tilt. A device that isn't constructed isn't listened to. Nothing is delivered between polls, and nothing calls the program.
	The program walks `events` itself.

	```haxe
	events.poll();
	for (event in events.events)
		switch event {
			case KeyDown(key, _): pressed(key);
			case CloseRequested: window.close();
			case _:
		}
	```
 */
interface IEvents extends IPollable {
	/** Drains the OS's queue into `events`, with the devices' events among them.

		`events` then holds this frame's events, in order. Last frame's events are cleared. */
	function poll():Void;

	/** Gets the events the last `poll` delivered. The array is reused by the next poll. */
	var events(get, never):Array<Event>;

	/** Sleeps in the OS until an event arrives or the timeout passes, using no CPU.

		It does nothing in a page. A native loop calls it while the window can't be seen (after `Hidden`), so the loop doesn't spin. The
		loop wakes at the timeout to service what must not starve. Events that arrive stay for the next `poll`.
		@param timeout  The longest wait, in seconds. */
	function wait(timeout:Float):Void;

	/** Gets a value indicating whether the player has made the first press (`Event.Unlocked`): a key or a mouse button pressed, or a
		finger lifted. In a browser that press unlocks the page, which may then play sound, ask for tilt and go fullscreen. It is heard
		without a keyboard, mouse or touch adapter, follows the same rule natively, and stays true once set. */
	var unlocked(get, never):Bool;

	/** Stops listening to the window and the first press. A program disposes of the devices built over it before it. */
	function dispose():Void;
}
