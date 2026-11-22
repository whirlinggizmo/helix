package helix.jolt;

/** Represents a collector of every one of a shape cast's hits, in no order until `Sort` is called. */
class CastShapeAllHitCollisionCollector extends CastShapeCollector {
	/** Gets the hits. Their objects are reused by the next query after `Reset`. */
	public var mHits(default, null):Array<ShapeCastResult>;

	/** Creates an empty collector. */
	public function new() {
		super();
		throw "not built yet";
	}

	/** Returns whether the query hit anything.

		@return  True when `mHits` holds a hit. */
	public function HadHit():Bool {
		throw "not built yet";
	}

	/** Sorts the hits, nearest first. */
	public function Sort():Void {
		throw "not built yet";
	}
}
