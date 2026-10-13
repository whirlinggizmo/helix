package helix.input;

/** Keyboard, pointer, mouse buttons, wheel, typed text, touches and gamepads.
    Tick edges (pressed, released) are counted and survive polling and render frames; consume() after a simulation tick takes one of each,
    so every press is seen by exactly one tick, and two presses between ticks reach two ticks.
    Frame edges (framePressed, frameReleased), typed text, the wheel and lifted touches last one frame. */
interface IInput {
 public function down(key:Key):Bool;
 public function pressed(key:Key):Bool;
 public function released(key:Key):Bool;
 public function framePressed(key:Key):Bool;
 public function frameReleased(key:Key):Bool;
 /** The primary pointer, in framebuffer pixels: the mouse with its left button, or the first finger. -1 when it isn't over the window. */
 public var pointerX(default,null):Float;
 public var pointerY(default,null):Float;
 public var pointerDown(default,null):Bool;
 public var pointerPressed(get,never):Bool;
 public var pointerReleased(get,never):Bool;
 public var pointerFramePressed(default,null):Bool;
 public var pointerFrameReleased(default,null):Bool;
 public function mouseDown(button:MouseButton):Bool;
 public function mousePressed(button:MouseButton):Bool;
 public function mouseFramePressed(button:MouseButton):Bool;
 /** Wheel notches this frame; up and right are positive. */
 public var wheelX(default,null):Float;
 public var wheelY(default,null):Float;
 /** Characters typed this frame, after the keyboard layout. */
 public var text(default,null):String;
 /** Fingers down, and those lifted this frame. */
 public var touches(default,null):Array<Touch>;
 /** Four slots, connected or not. */
 public var pads(default,null):Array<Gamepad>;
 /** Any connected pad. */
 public function padDown(button:PadButton):Bool;
 public function padPressed(button:PadButton):Bool;
 /** The first connected pad's axis, before the dead zone. */
 public function axis(axis:PadAxis):Float;
 public function consume():Void;
}
