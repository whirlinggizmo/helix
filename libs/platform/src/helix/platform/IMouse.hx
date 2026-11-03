package helix.platform;

/** Defines the mouse: `MouseMove`, `MouseDown`, `MouseUp`, `MouseLeave` and `Wheel` in `IEvents.events` while it exists, and the cursor
	over the canvas or window.

	Its adapter is constructed over the events adapter, whose `poll` delivers its events. A pen counts as the mouse. */
interface IMouse {
	/** Gets or sets whether the cursor shows over the canvas or window. Defaults to true. A locked mouse's cursor is hidden either way. */
	var cursorVisible(get, set):Bool;

	/** Gets or sets the cursor's shape while it shows. Defaults to `Arrow`. */
	var cursorShape(get, set):CursorShape;

	/** Gets whether the mouse is locked: its cursor hidden and held still, while its moves keep arriving. A locked mouse's `MouseMove`
		positions go on from where it was locked, by each move, past the canvas's or window's edges. */
	var locked(get, never):Bool;

	/** Asks for the mouse locked, for looking around with it, or let go.

		One of `done` or `failed` is called once, never during the call, and `locked` reflects the result from then. Natively the answer
		comes at the next `IEvents.poll`. A page locks only soon after a key press, click or tap; without one, it asks at the player's
		next. In a page, the player can let it go too, with Escape.
		@param locked  True to lock it, false to let it go.
		@param done  Optional. Called once it is granted.
		@param failed  Optional. Receives the reason when it is refused.
		@return  Whether it asked: false where the mouse can't be locked. */
	function requestLock(locked:Bool, ?done:Void->Void, ?failed:String->Void):Bool;

	/** Returns whether `setPosition` can move the cursor. It is false in a page, where the browser doesn't let a program move it. */
	function canSetPosition():Bool;

	/** Moves the cursor to a place over the canvas or window, and a `MouseMove` there arrives at the next poll.

		@param x  The place across, in framebuffer pixels from the left.
		@param y  The place down, in framebuffer pixels from the top.
		@return  Whether it moved: false where it can't (`canSetPosition`). */
	function setPosition(x:Float, y:Float):Bool;

	/** Stops listening to the mouse, and shows the cursor as the system has it. */
	function dispose():Void;
}
