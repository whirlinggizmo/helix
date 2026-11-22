package helix.jolt;

import helix.jolt.internal.Io;

/** Represents a constraint keeping two points of two bodies within a range of distances: a rope, a rod, a spring. */
class DistanceConstraintSettings extends TwoBodyConstraintSettings<DistanceConstraint> {
	/** Gets or sets the point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the shortest distance, in meters, or -1 for the distance when the constraint is made. Defaults to -1. */
	public var mMinDistance:Float = -1;

	/** Gets or sets the longest distance, in meters, or -1 for the distance when the constraint is made. Defaults to -1. */
	public var mMaxDistance:Float = -1;

	/** Gets or sets the spring at the distances' limits. Rigid by default. */
	public var mLimitsSpringSettings:SpringSettings;

	/** Creates the settings. */
	public function new() {
		super();
		mPoint1 = new RVec3();
		mPoint2 = new RVec3();
		mLimitsSpringSettings = new SpringSettings();
	}

	override function write():Int {
		super.write();
		Io.setF(0, mPoint1.x);
		Io.setF(1, mPoint1.y);
		Io.setF(2, mPoint1.z);
		Io.setF(3, mPoint2.x);
		Io.setF(4, mPoint2.y);
		Io.setF(5, mPoint2.z);
		Io.setF(6, mMinDistance);
		Io.setF(7, mMaxDistance);
		Io.setI(2, cast mLimitsSpringSettings.mMode);
		Io.setF(8, mLimitsSpringSettings.mFrequency);
		Io.setF(9, mLimitsSpringSettings.mStiffness);
		Io.setF(10, mLimitsSpringSettings.mDamping);
		return 2;
	}

	override function make(world:Int, handle:Int):DistanceConstraint {
		return new DistanceConstraint(world, handle);
	}
}
