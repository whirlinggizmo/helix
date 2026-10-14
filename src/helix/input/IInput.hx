package helix.input;

/** Keyboard, pointer, mouse buttons, wheel, typed text, touches and gamepads.
	Tick edges (isPressed, isReleased) are counted and survive polling and render frames; consume() after a simulation tick takes one of each,
	so every press is seen by exactly one tick, and two presses between ticks reach two ticks.
	Frame edges (isFramePressed, isFrameReleased), typed text, the wheel and lifted touches last one frame. */
interface IInput {
	/** Whether the key is held now. */
	public function isDown(key:Key):Bool;

	/** The key went down: a tick edge, counted until consume() takes it. */
	public function isPressed(key:Key):Bool;

	/** The key came up: a tick edge, counted until consume() takes it. */
	public function isReleased(key:Key):Bool;

	/** The key went down this frame: a frame edge. */
	public function isFramePressed(key:Key):Bool;

	/** The key came up this frame: a frame edge. */
	public function isFrameReleased(key:Key):Bool;

	/** The primary pointer, in framebuffer pixels: the mouse with its left button, or the first finger. -1 when it isn't over the window. */
	public function getPointerX():Float;

	/** The primary pointer's y, in framebuffer pixels down from the top. -1 when it isn't over the window. */
	public function getPointerY():Float;

	/** Whether the primary pointer is down: the left mouse button held, or the first finger touching. */
	public function isPointerDown():Bool;

	/** The primary pointer went down: a tick edge, counted until consume() takes it. */
	public function isPointerPressed():Bool;

	/** The primary pointer came up: a tick edge, counted until consume() takes it. */
	public function isPointerReleased():Bool;

	/** The primary pointer went down this frame: a frame edge. */
	public function isPointerFramePressed():Bool;

	/** The primary pointer came up this frame: a frame edge. */
	public function isPointerFrameReleased():Bool;

	/** Whether the mouse button is held now. */
	public function isMouseDown(button:MouseButton):Bool;

	/** The mouse button went down: a tick edge, counted until consume() takes it. */
	public function isMousePressed(button:MouseButton):Bool;

	/** The mouse button went down this frame: a frame edge. */
	public function isMouseFramePressed(button:MouseButton):Bool;

	/** The button came up: a counted tick edge, as a key's. */
	public function isMouseReleased(button:MouseButton):Bool;

	/** The button came up this frame: a frame edge. */
	public function isMouseFrameReleased(button:MouseButton):Bool;

	/** Wheel notches this frame; up and right are positive. */
	public function getWheelX():Float;

	/** Vertical wheel notches this frame; up is positive. */
	public function getWheelY():Float;

	/** Characters typed this frame, after the keyboard layout. */
	public function getText():String;

	/** Fingers down, and those lifted this frame. */
	public function getTouches():Array<Touch>;

	/** Whether two fingers are down: the two down longest make the gesture. */
	public function isTouchGesture():Bool;

	/** The point between the gesture's fingers now, in framebuffer pixels; 0 without a gesture. */
	public function getTouchGestureCenterX():Float;

	/** See getTouchGestureCenterX. */
	public function getTouchGestureCenterY():Float;

	/** How far the point between the fingers moved, in framebuffer pixels: this frame, or since the last tick with perTick. */
	public function getTouchGesturePanX(perTick:Bool = false):Float;

	/** See getTouchGesturePanX. */
	public function getTouchGesturePanY(perTick:Bool = false):Float;

	/** How much the fingers spread (over 1) or pinched (under 1), as a factor: this frame, or since the last tick with perTick; 1 without. */
	public function getTouchGestureScale(perTick:Bool = false):Float;

	/** How far the line between the fingers turned, in radians, clockwise on screen positive: this frame, or since the last tick with perTick. */
	public function getTouchGestureRotation(perTick:Bool = false):Float;

	/** Four slots, connected or not. */
	public function getPadCount():Int;

	/** null for an index out of range. */
	public function getPad(index:Int):Null<Gamepad>;

	/** Any connected pad. */
	public function isPadDown(button:PadButton):Bool;

	/** A connected pad's button went down: a counted tick edge, as a key's. */
	public function isPadPressed(button:PadButton):Bool;

	/** The first connected pad's axis, past the dead zone as Gamepad.getAxis gives it. */
	public function getPadAxis(axis:PadAxis):Float;

	/** Call after each simulation tick: takes one of each counted tick edge and clears the pads' tick edges. */
	public function consume():Void;
}
