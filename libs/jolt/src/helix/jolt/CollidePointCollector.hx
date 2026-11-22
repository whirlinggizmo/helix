package helix.jolt;

/** Represents what collects the bodies a point is inside, passed to `NarrowPhaseQuery.CollidePoint`. Made as one of the collectors below it, and reused from one
	query to the next. */
class CollidePointCollector {
	function new() {}

	/** Empties the collector for another query. A query doesn't empty the collector itself. */
	public function Reset():Void {
		throw "not built yet";
	}
}
