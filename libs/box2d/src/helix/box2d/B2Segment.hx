package helix.box2d;

/** A line segment with two-sided collision. */
class B2Segment {
	/** The first point. */
	public var point1:B2Vec2;

	/** The second point. */
	public var point2:B2Vec2;

	/** Creates one, as C's initializer lists its fields.

		@param point1  Optional. The first point.
		@param point2  Optional. The second point. */
	public function new(?point1:B2Vec2, ?point2:B2Vec2) {
		helix.box2d.internal.Init.initB2Segment(this);
		if (point1 != null)
			this.point1 = point1;
		if (point2 != null)
			this.point2 = point2;
	}
}
