package helix.platform;

/** Represents one input or window event, as `IEvents.poll` delivers it.

	Positions are in framebuffer pixels from the window's top-left corner. A key is its physical position on a US layout (`Key`).
	Right-hand modifiers are reported as the left-hand ones. */
enum Event {
	/** A key went down. repeat is true when the OS repeats a held key. */
	KeyDown(key:Key, repeat:Bool);

	/** A key went up. */
	KeyUp(key:Key);

	/** Characters were typed. It arrives only while `IEvents.setTextInput` is on. */
	Text(text:String);

	/** The mouse moved over the window. */
	MouseMove(x:Float, y:Float);

	/** A mouse button went down. */
	MouseDown(button:MouseButton, x:Float, y:Float);

	/** A mouse button went up. */
	MouseUp(button:MouseButton, x:Float, y:Float);

	/** The mouse left the window. */
	MouseLeave;

	/** The wheel turned, in notches. Right and away from the player are positive. */
	Wheel(dx:Float, dy:Float);

	/** A finger touched the screen. id stays the same for that finger until it lifts. */
	TouchDown(id:Int, x:Float, y:Float);

	/** A finger moved. */
	TouchMove(id:Int, x:Float, y:Float);

	/** A finger lifted, or the OS took the touch away. */
	TouchUp(id:Int, x:Float, y:Float);

	/** Reports the device's orientation while tilt access is held (`IEvents.requestTiltAccess`). beta and gamma are in degrees, and screenAngle is the screen's
		angle. */
	Tilt(beta:Float, gamma:Float, screenAngle:Float);

	/** The tilt's status changed. */
	TiltState(status:TiltStatus);

	/** The player's first press: a key or a mouse button pressed, or a finger lifted, for the first time.

		In a browser that press unlocks the page, which may then play sound, ask for tilt and go fullscreen. It arrives once, before that
		press's own event, on every target, so a game's "press any key" start flows the same everywhere (`IEvents.unlocked`). A finger counts
		as it lifts because a browser counts a tap then. A gamepad's press doesn't count, as a browser doesn't take one as the player's. */
	Unlocked;

	/** A gamepad was connected in a slot, 0 to 3. */
	PadConnected(slot:Int);

	/** The gamepad in a slot was disconnected. Its buttons count as up. */
	PadDisconnected(slot:Int);

	/** A gamepad's button went down. A trigger is also a button, down when pulled past half way. */
	PadButtonDown(slot:Int, button:PadButton);

	/** A gamepad's button went up. Natively, the Guide button's release arrives no sooner than a quarter second after its press. */
	PadButtonUp(slot:Int, button:PadButton);

	/** The drawable area changed size, in framebuffer pixels. */
	Resized(width:Int, height:Int);

	/** The window got the keyboard. */
	FocusGained;

	/** The window lost the keyboard. Just before it, each key still down arrives as a `KeyUp`. */
	FocusLost;

	/** The player can see the window again, because it was restored or its page came to the front. */
	Shown;

	/** The player can't see the window, because it is minimized or hidden, or its page is in the background. */
	Hidden;

	/** The player or the OS asked to close the window. The program decides whether to close it.

		It arrives only natively. A page never receives it, because a closing tab gives no frame to decide in. A page's end is
		`IWindow.onClose`. */
	CloseRequested;

	/** The GPU's context is gone. In a page, the WebGL context was lost to a GPU reset or an evicted tab. */
	GraphicsLost;
}
