package helix.box2d;

/** The output of `b2ComputeShapeDistance`. Box2D fills it. */
class B2DistanceOutput {
	/** Closest point on shapeA, in shape A's frame. */
	public var pointA:B2Vec2;

	/** Closest point on shapeB, in shape A's frame. */
	public var pointB:B2Vec2;

	/** A to B normal in shape A's frame. Invalid if distance is zero. */
	public var normal:B2Vec2;

	/** The final distance, zero if overlapped. */
	public var distance:Float;

	/** Number of GJK iterations used. */
	public var iterations:Int;

	/** The number of simplexes stored in the simplex array. */
	public var simplexCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2DistanceOutput(this);
	}
}
