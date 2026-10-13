package helix.input;

/** Keyboard, pointer, mouse buttons, wheel, typed text, touches and gamepads.
    Tick edges (isPressed, isReleased) are counted and survive polling and render frames; consume() after a simulation tick takes one of each,
    so every press is seen by exactly one tick, and two presses between ticks reach two ticks.
    Frame edges (isFramePressed, isFrameReleased), typed text, the wheel and lifted touches last one frame. */
interface IInput {
 public function isDown(key:Key):Bool;
 public function isPressed(key:Key):Bool;
 public function isReleased(key:Key):Bool;
 public function isFramePressed(key:Key):Bool;
 public function isFrameReleased(key:Key):Bool;
 /** The primary pointer, in framebuffer pixels: the mouse with its left button, or the first finger. -1 when it isn't over the window. */
 public function getPointerX():Float;
 public function getPointerY():Float;
 public function isPointerDown():Bool;
 public function isPointerPressed():Bool;
 public function isPointerReleased():Bool;
 public function isPointerFramePressed():Bool;
 public function isPointerFrameReleased():Bool;
 public function isMouseDown(button:MouseButton):Bool;
 public function isMousePressed(button:MouseButton):Bool;
 public function isMouseFramePressed(button:MouseButton):Bool;
 /** Wheel notches this frame; up and right are positive. */
 public function getWheelX():Float;
 public function getWheelY():Float;
 /** Characters typed this frame, after the keyboard layout. */
 public function getText():String;
 /** Fingers down, and those lifted this frame. */
 public function getTouches():Array<Touch>;
 /** Four slots, connected or not. */
 public function getPadCount():Int;
 /** null for an index out of range. */
 public function getPad(index:Int):Null<Gamepad>;
 /** Any connected pad. */
 public function isPadDown(button:PadButton):Bool;
 public function isPadPressed(button:PadButton):Bool;
 /** The first connected pad's axis, before the dead zone. */
 public function getPadAxis(axis:PadAxis):Float;
 public function consume():Void;
}
