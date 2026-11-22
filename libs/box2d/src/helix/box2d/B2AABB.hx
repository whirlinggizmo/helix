package helix.box2d;

/** An axis-aligned bounding box, in world units (meters by default). */
class B2AABB {
	/** The corner with the smallest x and y. */
	public var lowerBound:B2Vec2;

	/** The corner with the largest x and y. */
	public var upperBound:B2Vec2;

	/** Creates one, as C's initializer lists its fields.

		@param lowerBound  Optional. The lower corner. A zero vector when omitted.
		@param upperBound  Optional. The upper corner. A zero vector when omitted. */
	public function new(?lowerBound:B2Vec2, ?upperBound:B2Vec2) {
		throw "not built yet";
	}
}
