import helix.platform.IGamepads;
import helix.platform.IKeyboard;
import helix.platform.IMouse;
import helix.platform.ITilt;
import helix.platform.ITouch;
import helix.platform.PadAxis;
import helix.platform.PadButton;

/** Stands in for the platform's keyboard, mouse, touch, gamepads and tilt in the services' tests: the pads' axes set by the test, and whether
	tilt access is held. */
class FakeDevices implements IKeyboard implements IMouse implements ITouch implements IGamepads implements ITilt {
	/** Gets the pads' axes, slot * PadAxis.COUNT + axis. */
	public final axes = [for (_ in 0...4 * PadAxis.COUNT) 0.];

	/** Gets a value indicating whether tilt access was asked for and not released. */
	public var tiltRequested(default, null) = false;

	/** Creates them, with a pad in slot 0 alone. */
	public function new() {}

	/** Gets or sets whether typed text arrives; the tests deliver `Text` themselves. */
	public var textInput(get, set):Bool;

	var typing = false;

	function get_textInput():Bool
		return typing;

	function set_textInput(on:Bool):Bool
		return typing = on;

	public function isConnected(slot:Int):Bool
		return slot == 0;

	public function getName(slot:Int):String
		return slot == 0 ? "Fake" : "";

	public function isButtonDown(slot:Int, button:PadButton):Bool
		return false;

	public function getAxis(slot:Int, axis:PadAxis):Float
		return axes[slot * PadAxis.COUNT + axis];

	public function requestAccess(?done:Void->Void, ?failed:String->Void):Bool {
		tiltRequested = true;
		return true;
	}

	public function releaseAccess():Void
		tiltRequested = false;

	public function dispose():Void {}
}
