package helix.platform;

/** Represents one thing that happened, as `IEvents.poll` delivers it.

	Positions are framebuffer pixels from the window's top-left. A key is its physical position on a US layout (`Key`), right-hand
	modifiers reported as the left-hand ones. */
enum Event {
	/** A key went down; repeat is true when the OS repeats a held key. */
	KeyDown(key:Key, repeat:Bool);

	/** A key went up. */
	KeyUp(key:Key);

	/** Characters were typed, while `IEvents.setTextInput` is on. */
	Text(text:String);

	/** The mouse moved over the window. */
	MouseMove(x:Float, y:Float);

	/** A mouse button went down. */
	MouseDown(button:MouseButton, x:Float, y:Float);

	/** A mouse button went up. */
	MouseUp(button:MouseButton, x:Float, y:Float);

	/** The mouse left the window. */
	MouseLeave;

	/** The wheel turned, in notches: right and away from the player positive. */
	Wheel(dx:Float, dy:Float);

	/** A finger touched the screen; id is the same for that finger until it lifts. */
	TouchDown(id:Int, x:Float, y:Float);

	/** A finger moved. */
	TouchMove(id:Int, x:Float, y:Float);

	/** A finger lifted, or the OS took the touch away. */
	TouchUp(id:Int, x:Float, y:Float);

	/** The device's orientation, while `IEvents.setTiltWanted` is on: beta and gamma in degrees, and the screen's angle. */
	Tilt(beta:Float, gamma:Float, screenAngle:Float);

	/** The tilt's state changed: 0 off, 1 waiting for the player's permission, 2 calibrating, 3 on, 4 refused, 5 unavailable, 6 unavailable
		because the page isn't secure (HTTPS). */
	TiltState(state:Int);

	/** A gamepad was connected in a slot, 0 to 3. */
	PadConnected(slot:Int);

	/** The gamepad in a slot was disconnected; its buttons count as up. */
	PadDisconnected(slot:Int);

	/** A gamepad's button went down. A trigger is a button too, down past half way. */
	PadButtonDown(slot:Int, button:PadButton);

	/** A gamepad's button went up. Natively the Guide button's release arrives no sooner than a quarter second after its press. */
	PadButtonUp(slot:Int, button:PadButton);

	/** The drawable area changed size, in framebuffer pixels. */
	Resized(width:Int, height:Int);

	/** The window got the keyboard. */
	FocusGained;

	/** The window lost the keyboard; each key still down came up just before, a `KeyUp` each. */
	FocusLost;

	/** The player can see the window again: restored, or the page in front again. */
	Shown;

	/** The player can't see the window: minimized or hidden, or the page in the background. */
	Hidden;

	/** The player or the OS asked to close the window, natively; the owner decides.

		A page never gets it: a tab closing gives no frame to decide in, and its end is `IWindow.onClose`. */
	CloseRequested;

	/** The GPU's context is gone: in a page, the WebGL context lost to a GPU reset or an evicted tab. */
	GraphicsLost;
}
