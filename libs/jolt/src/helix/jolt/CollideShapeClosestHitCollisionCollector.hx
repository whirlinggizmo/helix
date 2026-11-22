package helix.jolt;

/** Represents a collector of the hit of deepest penetration. */
class CollideShapeClosestHitCollisionCollector extends CollideShapeCollector {
	/** Gets the hit, read when `HadHit` is true. */
	public var mHit(default, null):CollideShapeResult;

	/** Creates an empty collector. */
	public function new() {
		super();
		throw "not built yet";
	}

	/** Returns whether the query hit anything.

		@return  True when `mHit` holds a hit. */
	public function HadHit():Bool {
		throw "not built yet";
	}
}
