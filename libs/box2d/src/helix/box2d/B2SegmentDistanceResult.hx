package helix.box2d;

/** The result of computing the distance between two line segments. Box2D fills it. */
class B2SegmentDistanceResult {
	/** The closest point on the first segment. */
	public var closest1:B2Vec2;

	/** The closest point on the second segment. */
	public var closest2:B2Vec2;

	/** The barycentric coordinate on the first segment. */
	public var fraction1:Float;

	/** The barycentric coordinate on the second segment. */
	public var fraction2:Float;

	/** The squared distance between the closest points. */
	public var distanceSquared:Float;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
