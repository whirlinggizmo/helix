package helix.jolt;

import helix.jolt.internal.Io;

/** Represents what collects a ray cast's hits, passed to `NarrowPhaseQuery.CastRay`. Made as one of the collectors below it, and reused from one
	query to the next. */
class CastRayCollector {
	function new() {}

	/** The collector kind hj's queries read: 0 all, 1 closest, 2 any. */
	@:allow(helix.jolt) function kind():Int {
		return 0;
	}

	/** Reads a query's hits from the bulk buffer. */
	@:allow(helix.jolt) function take(base:Int, count:Int):Void {}

	/** Reads a hit from the bulk buffer, 3 numbers from `at`. */
	static function read(result:RayCastResult, base:Int, at:Int):Void {
		result.mBodyID = new BodyID(Io.bulkI(base, at));
		result.mSubShapeID2 = cast Io.bulkI(base, at + 1);
		result.mFraction = Io.bulkF(base, at + 2);
	}

	/** Empties the collector for another query. A query doesn't empty the collector itself. */
	public function Reset():Void {
		// Each collector empties its own hits.
	}
}
