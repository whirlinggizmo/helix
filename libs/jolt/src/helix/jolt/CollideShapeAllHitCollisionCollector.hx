package helix.jolt;

/** Represents a collector of every one of the bodies a shape overlaps, in no order until `Sort` is called. */
class CollideShapeAllHitCollisionCollector extends CollideShapeCollector {
	/** Gets the hits. Their objects are reused by the next query after `Reset`. */
	public var mHits(default, null):Array<CollideShapeResult>;

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
