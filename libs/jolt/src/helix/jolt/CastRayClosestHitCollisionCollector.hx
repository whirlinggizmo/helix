package helix.jolt;

/** Represents a collector of the hit nearest the ray's origin. */
class CastRayClosestHitCollisionCollector extends CastRayCollector {
	/** Gets the hit, read when `HadHit` is true. */
	public var mHit(default, null):RayCastResult;

	/** Creates an empty collector. */
	public function new() {
		super();
		mHit = new RayCastResult();
	}

	/** Returns whether the query hit anything.

		@return  True when `mHit` holds a hit. */
	public function HadHit():Bool {
		return hadHit;
	}

	var hadHit = false;
	var hit = new RayCastResult();

	override function kind():Int {
		return 1;
	}

	override public function Reset():Void {
		hadHit = false;
	}

	override function take(base:Int, count:Int):Void {
		if (count == 0)
			return;
		CastRayCollector.read(hit, base, 0);
		if (!hadHit || hit.mFraction < mHit.mFraction) {
			var kept = mHit;
			mHit = hit;
			hit = kept;
			hadHit = true;
		}
	}
}
