package helix.box2d;

/** Performance results of a dynamic tree query. Box2D fills it. */
class B2TreeStats {
	/** Number of internal nodes visited during the query. */
	public var nodeVisits:Int;

	/** Number of leaf nodes visited during the query. */
	public var leafVisits:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2TreeStats(this);
	}
}
