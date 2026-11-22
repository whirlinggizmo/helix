package helix.jolt;

/** Represents a collector of every one of the bodies a point is inside, in no order until `Sort` is called. */
class CollidePointAllHitCollisionCollector extends CollidePointCollector {
	/** Gets the hits. Their objects are reused by the next query after `Reset`. */
	public var mHits(default, null):Array<CollidePointResult>;

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
}
