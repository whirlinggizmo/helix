package helix.jolt;

import helix.jolt.internal.Io;

/** Represents what collects a shape cast's hits, passed to `NarrowPhaseQuery.CastShape`. Made as one of the collectors below it, and reused from one
	query to the next. */
class CastShapeCollector {
	function new() {}

	/** The collector kind hj's queries read: 0 all, 1 closest, 2 any. */
	@:allow(helix.jolt) function kind():Int {
		return 0;
	}

	/** Reads a query's hits from the bulk buffer. */
	@:allow(helix.jolt) function take(base:Int, count:Int):Void {}

	/** Reads a hit from the bulk buffer, 15 numbers from `at`. */
	static function read(result:ShapeCastResult, base:Int, at:Int):Void {
		result.read(base, at);
		result.mFraction = Io.bulkF(base, at + 13);
		result.mIsBackFaceHit = Io.bulkI(base, at + 14) != 0;
	}

	/** Empties the collector for another query. A query doesn't empty the collector itself. */
	public function Reset():Void {
		// Each collector empties its own hits.
	}
}
