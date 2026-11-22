package helix.jolt;

import helix.jolt.internal.Io;

/** Represents what collects the bodies a point is inside, passed to `NarrowPhaseQuery.CollidePoint`. Made as one of the collectors below it, and reused from one
	query to the next. */
class CollidePointCollector {
	function new() {}

	/** The collector kind hj's queries read: 0 all, 1 closest, 2 any. */
	@:allow(helix.jolt) function kind():Int {
		return 0;
	}

	/** Reads a query's hits from the bulk buffer. */
	@:allow(helix.jolt) function take(base:Int, count:Int):Void {}

	/** Reads a hit from the bulk buffer, 2 numbers from `at`. */
	static function read(result:CollidePointResult, base:Int, at:Int):Void {
		result.mBodyID = new BodyID(Io.bulkI(base, at));
		result.mSubShapeID2 = cast Io.bulkI(base, at + 1);
	}

	/** Empties the collector for another query. A query doesn't empty the collector itself. */
	public function Reset():Void {
		// Each collector empties its own hits.
	}
}
