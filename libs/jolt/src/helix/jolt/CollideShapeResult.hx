package helix.jolt;

import helix.jolt.internal.Io;

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
		mContactPointOn1 = new Vec3();
		mContactPointOn2 = new Vec3();
		mPenetrationAxis = new Vec3();
		mSubShapeID1 = new SubShapeID();
		mSubShapeID2 = new SubShapeID();
		mBodyID2 = new BodyID();
	}

	/** Reads a result from the bulk buffer, 13 numbers from `at`, as hj_query_collide_shape writes it. */
	@:allow(helix.jolt) function read(base:Int, at:Int):Void {
		(mContactPointOn1 : helix.math.Vector3).set(Io.bulkF(base, at), Io.bulkF(base, at + 1), Io.bulkF(base, at + 2));
		(mContactPointOn2 : helix.math.Vector3).set(Io.bulkF(base, at + 3), Io.bulkF(base, at + 4), Io.bulkF(base, at + 5));
		(mPenetrationAxis : helix.math.Vector3).set(Io.bulkF(base, at + 6), Io.bulkF(base, at + 7), Io.bulkF(base, at + 8));
		mPenetrationDepth = Io.bulkF(base, at + 9);
		mSubShapeID1 = cast Io.bulkI(base, at + 10);
		mSubShapeID2 = cast Io.bulkI(base, at + 11);
		mBodyID2 = new BodyID(Io.bulkI(base, at + 12));
	}
}
