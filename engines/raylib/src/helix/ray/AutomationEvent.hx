package helix.ray;

/** Represents raylib's `AutomationEvent`: an input or window event, recorded in a frame, to be played later. */
class AutomationEvent {
	/** Gets or sets the frame it happened in. */
	public var frame:Int = 0;

	/** Gets or sets what happened, as raylib's AutomationEventType numbers it: 1 a key up, 2 a key down, 5 and 6 a mouse button up and
		down, 7 the mouse moved, 8 the wheel, 11 and 12 a gamepad button up and down, 13 a gamepad axis, 14 and 15 a finger up and down, 16
		a finger moved, 17 a gesture, 18 to 21 the window closed, maximized, minimized and resized, 22 a screenshot, 23 the target frames
		a second. */
	public var type:Int = 0;

	/** Gets or sets its four parameters, by its type: a key, a button, a position, a gamepad and its button or axis and value (times
		32768), a size. */
	public var params:Array<Int> = [0, 0, 0, 0];

	/** Creates one, its fields zero. */
	public function new() {}
}
