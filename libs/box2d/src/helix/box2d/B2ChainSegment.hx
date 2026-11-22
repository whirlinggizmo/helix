package helix.box2d;

/** A line segment of a chain, with one-sided collision. It has a ghost vertex at each end. */
class B2ChainSegment {
	/** The ghost vertex before the segment. */
	public var ghost1:B2Vec2;

	/** The line segment. */
	public var segment:B2Segment;

	/** The ghost vertex after the segment. */
	public var ghost2:B2Vec2;

	/** Box2D's index of the chain that owns the segment. Opaque to a program. */
	public var chainId:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
