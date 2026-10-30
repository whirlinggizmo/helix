import helix.platform.Event;
import helix.platform.IEvents;
import helix.platform.PadAxis;
import helix.platform.PadButton;

/** Stands in for the platform's events in the services' tests: a frame's events and the pads' axes, set by the test. */
class FakeEvents implements IEvents {
	/** Gets the events the next `poll` delivers. */
	public final next:Array<Event> = [];

	/** Gets the pads' axes, slot * PadAxis.COUNT + axis. */
	public final axes = [for (_ in 0...4 * PadAxis.COUNT) 0.];

	final delivered:Array<Event> = [];

	/** Creates one with nothing to deliver. */
	public function new() {}

	public function poll():Void {
		delivered.resize(0);
		for (event in next)
			delivered.push(event);
		next.resize(0);
	}

	/** Gets the events the last poll delivered. */
	public var events(get, never):Array<Event>;

	function get_events():Array<Event>
		return delivered;

	public function wait(timeout:Float):Void {}

	public function setTextInput(on:Bool):Void {}

	public function setTiltWanted(on:Bool):Void {}

	public function isPadConnected(slot:Int):Bool
		return slot == 0;

	public function getPadName(slot:Int):String
		return slot == 0 ? "Fake" : "";

	public function isPadButtonDown(slot:Int, button:PadButton):Bool
		return false;

	public function getPadAxis(slot:Int, axis:PadAxis):Float
		return axes[slot * PadAxis.COUNT + axis];

	public function dispose():Void {}
}
