package helix.input;

/** Edges survive polling/render frames until consume() after a simulation tick. */
interface IInput {
 public function down(key:Key):Bool;
 public function pressed(key:Key):Bool;
 public function released(key:Key):Bool;
 public function padDown(button:PadButton):Bool;
 public function padPressed(button:PadButton):Bool;
 public function axis(axis:PadAxis):Float;
 public var pointerX(default,null):Float;
 public var pointerY(default,null):Float;
 public var pointerDown(default,null):Bool;
 public var pointerPressed(default,null):Bool;
 public var pointerReleased(default,null):Bool;
 public function consume():Void;
}
