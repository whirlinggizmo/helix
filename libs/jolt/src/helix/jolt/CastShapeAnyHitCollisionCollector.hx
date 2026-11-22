package helix.jolt;

/** Represents a collector of the first of a shape cast's hits found, which ends the query: the fastest answer to whether there is one. */
class CastShapeAnyHitCollisionCollector extends CastShapeCollector {
	/** Gets the hit, read when `HadHit` is true. */
	public var mHit(default, null):ShapeCastResult;

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
