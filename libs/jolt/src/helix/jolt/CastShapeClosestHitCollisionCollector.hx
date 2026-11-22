package helix.jolt;

/** Represents a collector of the hit nearest the cast's start. */
class CastShapeClosestHitCollisionCollector extends CastShapeCollector {
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
