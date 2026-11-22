package helix.jolt;

import helix.jolt.internal.Io;

/** Represents a constraint holding a point of one body to another, the second body's axis kept within a cone about the first's: a
	shoulder. */
class ConeConstraintSettings extends TwoBodyConstraintSettings<ConeConstraint> {
	/** Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the cone's axis on the first body. Defaults to (1, 0, 0). */
	public var mTwistAxis1:Vec3;

	/** Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the axis on the second body kept in the cone. Defaults to (1, 0, 0). */
	public var mTwistAxis2:Vec3;

	/** Gets or sets half the cone's angle, in radians, 0 to pi. Defaults to 0. */
	public var mHalfConeAngle:Float = 0;

	/** Creates the settings. */
	public function new() {
		super();
		mPoint1 = new RVec3();
		mTwistAxis1 = new Vec3(1, 0, 0);
		mPoint2 = new RVec3();
		mTwistAxis2 = new Vec3(1, 0, 0);
	}

	override function write():Int {
		super.write();
		Io.setF(0, mPoint1.x);
		Io.setF(1, mPoint1.y);
		Io.setF(2, mPoint1.z);
		Io.setF(3, mTwistAxis1.x);
		Io.setF(4, mTwistAxis1.y);
		Io.setF(5, mTwistAxis1.z);
		Io.setF(6, mPoint2.x);
		Io.setF(7, mPoint2.y);
		Io.setF(8, mPoint2.z);
		Io.setF(9, mTwistAxis2.x);
		Io.setF(10, mTwistAxis2.y);
		Io.setF(11, mTwistAxis2.z);
		Io.setF(12, mHalfConeAngle);
		return 5;
	}

	override function make(world:Int, handle:Int):ConeConstraint {
		return new ConeConstraint(world, handle);
	}
}
