import helix.platform.Event;
import helix.platform.IEvents;

/** Stands in for the platform's events in the services' tests: a frame's events, set by the test. */
class FakeEvents implements IEvents {
	/** Gets the events the next `poll` delivers. */
	public final next:Array<Event> = [];

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

	/** Gets false: the tests deliver `Unlocked` themselves. */
	public var unlocked(get, never):Bool;

	function get_unlocked():Bool
		return false;

	public function dispose():Void {}
}
