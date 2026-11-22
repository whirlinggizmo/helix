package helix.jolt;

/** Represents what collects a shape cast's hits, passed to `NarrowPhaseQuery.CastShape`. Made as one of the collectors below it, and reused from one
	query to the next. */
class CastShapeCollector {
	function new() {}

	/** Empties the collector for another query. A query doesn't empty the collector itself. */
	public function Reset():Void {
		throw "not built yet";
	}
}
