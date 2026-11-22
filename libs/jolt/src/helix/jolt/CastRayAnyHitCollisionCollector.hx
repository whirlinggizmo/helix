package helix.jolt;

/** Represents a collector of the first of a ray cast's hits found, which ends the query: the fastest answer to whether there is one. */
class CastRayAnyHitCollisionCollector extends CastRayCollector {
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

	override function kind():Int {
		return 2;
	}

	override public function Reset():Void {
		hadHit = false;
	}

	override function take(base:Int, count:Int):Void {
		if (count == 0 || hadHit)
			return;
		CastRayCollector.read(mHit, base, 0);
		hadHit = true;
	}
}
