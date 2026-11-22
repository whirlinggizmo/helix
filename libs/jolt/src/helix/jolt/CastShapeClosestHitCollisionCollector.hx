package helix.jolt;

/** Represents a collector of the hit nearest the cast's start. */
class CastShapeClosestHitCollisionCollector extends CastShapeCollector {
	/** Gets the hit, read when `HadHit` is true. */
	public var mHit(default, null):ShapeCastResult;

	/** Creates an empty collector. */
	public function new() {
		super();
		mHit = new ShapeCastResult();
	}

	/** Returns whether the query hit anything.

		@return  True when `mHit` holds a hit. */
	public function HadHit():Bool {
		return hadHit;
	}

	var hadHit = false;
	var hit = new ShapeCastResult();

	override function kind():Int {
		return 1;
	}

	override public function Reset():Void {
		hadHit = false;
	}

	override function take(base:Int, count:Int):Void {
		if (count == 0)
			return;
		CastShapeCollector.read(hit, base, 0);
		if (!hadHit || hit.mFraction < mHit.mFraction) {
			var kept = mHit;
			mHit = hit;
			hit = kept;
			hadHit = true;
		}
	}
}
