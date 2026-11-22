package helix.jolt;

/** Represents a collector of every one of a shape cast's hits, in no order until `Sort` is called. */
class CastShapeAllHitCollisionCollector extends CastShapeCollector {
	/** Gets the hits. Their objects are reused by the next query after `Reset`. */
	public var mHits(default, null):Array<ShapeCastResult>;

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

	/** Sorts the hits, nearest first. */
	public function Sort():Void {
		mHits.sort((a, b) -> a.mFraction < b.mFraction ? -1 : a.mFraction > b.mFraction ? 1 : 0);
	}

	var spare:Array<ShapeCastResult> = [];

	override public function Reset():Void {
		for (hit in mHits)
			spare.push(hit);
		mHits.resize(0);
	}

	override function take(base:Int, count:Int):Void {
		for (n in 0...count) {
			var hit = spare.length > 0 ? spare.pop() : new ShapeCastResult();
			CastShapeCollector.read(hit, base, n * 15);
			mHits.push(hit);
		}
	}
}
