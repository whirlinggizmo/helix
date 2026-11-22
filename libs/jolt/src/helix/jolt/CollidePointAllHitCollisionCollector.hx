package helix.jolt;

/** Represents a collector of every one of the bodies a point is inside, in no order until `Sort` is called. */
class CollidePointAllHitCollisionCollector extends CollidePointCollector {
	/** Gets the hits. Their objects are reused by the next query after `Reset`. */
	public var mHits(default, null):Array<CollidePointResult>;

	/** Creates an empty collector. */
	public function new() {
		super();
		mHits = [];
	}

	/** Returns whether the query hit anything.

		@return  True when `mHits` holds a hit. */
	public function HadHit():Bool {
		return mHits.length > 0;
	}

	var spare:Array<CollidePointResult> = [];

	override public function Reset():Void {
		for (hit in mHits)
			spare.push(hit);
		mHits.resize(0);
	}

	override function take(base:Int, count:Int):Void {
		for (n in 0...count) {
			var hit = spare.length > 0 ? spare.pop() : new CollidePointResult();
			CollidePointCollector.read(hit, base, n * 2);
			mHits.push(hit);
		}
	}
}
