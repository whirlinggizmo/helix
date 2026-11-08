import helix.platform.IGamepads;
import helix.platform.IKeyboard;
import helix.platform.CursorShape;
import helix.platform.IMouse;
import helix.platform.ITilt;
import helix.platform.ITouch;
import helix.platform.GamepadAxis;
import helix.platform.GamepadButton;

/** Stands in for the platform's keyboard, mouse, touch, gamepads and tilt in the services' tests: the gamepads' axes set by the test, and whether
	tilt access is held. */
class FakeDevices implements IKeyboard implements IMouse implements ITouch implements IGamepads implements ITilt {
	/** Gets or sets whether the cursor shows. */
	public var cursorVisible(get, set):Bool;

	var visible = true;

	function get_cursorVisible():Bool
		return visible;

	function set_cursorVisible(on:Bool):Bool
		return visible = on;

	/** Gets or sets the cursor's shape. */
	public var cursorShape(get, set):CursorShape;

	var shape = Arrow;

	function get_cursorShape():CursorShape
		return shape;

	function set_cursorShape(to:CursorShape):CursorShape
		return shape = to;

	/** Gets whether the mouse is locked: as last asked, granted at once. */
	public var locked(get, never):Bool;

	var held = false;

	function get_locked():Bool
		return held;

	// The answers due at the next answer().
	var due:Array<Void->Void> = [];

	/** Locks or lets go of the mouse at once, `done` called at the next `answer`, as an `IEvents.poll` would. */
	public function requestLock(locked:Bool, ?done:Void->Void, ?failed:String->Void):Bool {
		held = locked;
		if (done != null)
			due.push(done);
		return true;
	}

	/** Answers the locks asked for since the last call, as an `IEvents.poll` would. */
	public function answer():Void {
		var now = due;
		due = [];
		for (f in now)
			f();
	}

	/** Says the gamepad shakes when one is connected. */
	public function setVibration(slot:Int, low:Float, high:Float, seconds:Float):Bool
		return isConnected(slot);

	/** Adds none. */
	public function addMappings(mappings:String):Int
		return 0;

	/** Returns true: the fake's cursor moves. */
	public function canSetPosition():Bool
		return true;

	/** Records nothing and says it moved. */
	public function setPosition(x:Float, y:Float):Bool
		return true;

	/** Gets the gamepads' axes, slot * GamepadAxis.COUNT + axis. */
	public final axes = [for (_ in 0...4 * GamepadAxis.COUNT) 0.];

	/** Gets a value indicating whether tilt access was asked for and not released. */
	public var tiltRequested(default, null) = false;

	/** Creates them, with a gamepad in slot 0 alone. */
	public function new() {}

	/** Gets or sets whether typed text arrives; nothing types in the tests. */
	public var textInput(get, set):Bool;

	var typing = false;

	function get_textInput():Bool
		return typing;

	function set_textInput(on:Bool):Bool
		return typing = on;

	/** Gets or sets whether the device has touch. */
	public var touchAvailable = true;

	public var available(get, never):Bool;

	function get_available():Bool
		return touchAvailable;

	/** Gets or sets whether a gamepad is in slot 0. */
	public var gamepadConnected = true;

	public function isConnected(slot:Int):Bool
		return slot == 0 && gamepadConnected;

	public function getName(slot:Int):String
		return slot == 0 && gamepadConnected ? "Fake" : "";

	public function isButtonDown(slot:Int, button:GamepadButton):Bool
		return false;

	public function getAxis(slot:Int, axis:GamepadAxis):Float
		return axes[slot * GamepadAxis.COUNT + axis];

	public function requestAccess(?done:Void->Void, ?failed:String->Void):Bool {
		tiltRequested = true;
		return true;
	}

	public function releaseAccess():Void
		tiltRequested = false;

	public function dispose():Void {}
}
