package helix.jolt;

/** Represents a collector of the hit of deepest penetration. */
class CollideShapeClosestHitCollisionCollector extends CollideShapeCollector {
	/** Gets the hit, read when `HadHit` is true. */
	public var mHit(default, null):CollideShapeResult;

	/** Creates an empty collector. */
	public function new() {
		super();
		mHit = new CollideShapeResult();
	}

	/** Returns whether the query hit anything.

		@return  True when `mHit` holds a hit. */
	public function HadHit():Bool {
		return hadHit;
	}

	var hadHit = false;
	var hit = new CollideShapeResult();

	override function kind():Int {
		return 1;
	}

	override public function Reset():Void {
		hadHit = false;
	}

	override function take(base:Int, count:Int):Void {
		if (count == 0)
			return;
		CollideShapeCollector.read(hit, base, 0);
		if (!hadHit || hit.mPenetrationDepth > mHit.mPenetrationDepth) {
			var kept = mHit;
			mHit = hit;
			hit = kept;
			hadHit = true;
		}
	}
}
