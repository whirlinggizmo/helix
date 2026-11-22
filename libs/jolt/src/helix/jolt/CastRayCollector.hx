package helix.jolt;

/** Represents what collects a ray cast's hits, passed to `NarrowPhaseQuery.CastRay`. Made as one of the collectors below it, and reused from one
	query to the next. */
class CastRayCollector {
	function new() {}

	/** Empties the collector for another query. A query doesn't empty the collector itself. */
	public function Reset():Void {
		throw "not built yet";
	}
}
