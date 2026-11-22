package helix.jolt;

/** Represents a body a shape overlaps, and where. */
class CollideShapeResult {
	/** Gets or sets the deepest point on the query's shape, in the world, in meters. */
	public var mContactPointOn1:Vec3;

	/** Gets or sets the deepest point on the body's shape, in the world, in meters. */
	public var mContactPointOn2:Vec3;

	/** Gets or sets the direction the query's shape moves to leave the body, its length any. */
	public var mPenetrationAxis:Vec3;

	/** Gets or sets how deep the shapes overlap, in meters. */
	public var mPenetrationDepth:Float = 0;

	/** Gets or sets the part of the query's shape. */
	public var mSubShapeID1:SubShapeID;

	/** Gets or sets the part of the body's shape. */
	public var mSubShapeID2:SubShapeID;

	/** Gets or sets the body. */
	public var mBodyID2:BodyID;

	/** Creates an empty result. */
	public function new() {
		throw "not built yet";
	}
}
