package helix.jolt;

import helix.jolt.internal.Io;

/** Represents a constraint holding a point of one body to a point of another, the bodies free to turn: a ball joint. */
class PointConstraintSettings extends TwoBodyConstraintSettings<TwoBodyConstraint> {
	/** Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Creates the settings. */
	public function new() {
		super();
		mPoint1 = new RVec3();
		mPoint2 = new RVec3();
	}

	override function write():Int {
		super.write();
		Io.setF(0, mPoint1.x);
		Io.setF(1, mPoint1.y);
		Io.setF(2, mPoint1.z);
		Io.setF(3, mPoint2.x);
		Io.setF(4, mPoint2.y);
		Io.setF(5, mPoint2.z);
		return 1;
	}

	override function make(world:Int, handle:Int):TwoBodyConstraint {
		return new TwoBodyConstraint(world, handle);
	}
}
