package helix.jolt;

import helix.jolt.internal.Io;

/** Represents a constraint letting two bodies turn about one axis: a door, a wheel. */
class HingeConstraintSettings extends TwoBodyConstraintSettings<HingeConstraint> {
	/** Gets or sets the hinge's point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the hinge's axis on the first body. Defaults to (0, 1, 0). */
	public var mHingeAxis1:Vec3;

	/** Gets or sets an axis at right angles to the hinge's on the first body, from which the angle is measured. Defaults to (1, 0, 0). */
	public var mNormalAxis1:Vec3;

	/** Gets or sets the hinge's point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the hinge's axis on the second body. Defaults to (0, 1, 0). */
	public var mHingeAxis2:Vec3;

	/** Gets or sets an axis at right angles to the hinge's on the second body. Defaults to (1, 0, 0). */
	public var mNormalAxis2:Vec3;

	/** Gets or sets the smallest angle, in radians, -pi to 0. Defaults to -pi: no limit. */
	public var mLimitsMin:Float = -Math.PI;

	/** Gets or sets the largest angle, in radians, 0 to pi. Defaults to pi: no limit. */
	public var mLimitsMax:Float = Math.PI;

	/** Gets or sets the spring at the angles' limits. Rigid by default. */
	public var mLimitsSpringSettings:SpringSettings;

	/** Gets or sets the friction torque that slows the hinge, in newton meters. Defaults to 0. */
	public var mMaxFrictionTorque:Float = 0;

	/** Gets or sets the motor: by default with no force limit, and off until the constraint's `SetMotorState`. */
	public var mMotorSettings:MotorSettings;

	/** Creates the settings. */
	public function new() {
		super();
		mPoint1 = new RVec3();
		mHingeAxis1 = new Vec3(0, 1, 0);
		mNormalAxis1 = new Vec3(1, 0, 0);
		mPoint2 = new RVec3();
		mHingeAxis2 = new Vec3(0, 1, 0);
		mNormalAxis2 = new Vec3(1, 0, 0);
		mLimitsSpringSettings = new SpringSettings();
		mMotorSettings = new MotorSettings();
	}

	override function write():Int {
		super.write();
		Io.setF(0, mPoint1.x);
		Io.setF(1, mPoint1.y);
		Io.setF(2, mPoint1.z);
		Io.setF(3, mHingeAxis1.x);
		Io.setF(4, mHingeAxis1.y);
		Io.setF(5, mHingeAxis1.z);
		Io.setF(6, mNormalAxis1.x);
		Io.setF(7, mNormalAxis1.y);
		Io.setF(8, mNormalAxis1.z);
		Io.setF(9, mPoint2.x);
		Io.setF(10, mPoint2.y);
		Io.setF(11, mPoint2.z);
		Io.setF(12, mHingeAxis2.x);
		Io.setF(13, mHingeAxis2.y);
		Io.setF(14, mHingeAxis2.z);
		Io.setF(15, mNormalAxis2.x);
		Io.setF(16, mNormalAxis2.y);
		Io.setF(17, mNormalAxis2.z);
		Io.setF(18, mLimitsMin);
		Io.setF(19, mLimitsMax);
		Io.setF(20, mMaxFrictionTorque);
		Io.setI(2, cast mLimitsSpringSettings.mMode);
		Io.setF(21, mLimitsSpringSettings.mFrequency);
		Io.setF(22, mLimitsSpringSettings.mStiffness);
		Io.setF(23, mLimitsSpringSettings.mDamping);
		Io.setI(3, cast mMotorSettings.mSpringSettings.mMode);
		Io.setF(24, mMotorSettings.mSpringSettings.mFrequency);
		Io.setF(25, mMotorSettings.mSpringSettings.mStiffness);
		Io.setF(26, mMotorSettings.mSpringSettings.mDamping);
		Io.setF(27, mMotorSettings.mMinForceLimit);
		Io.setF(28, mMotorSettings.mMaxForceLimit);
		Io.setF(29, mMotorSettings.mMinTorqueLimit);
		Io.setF(30, mMotorSettings.mMaxTorqueLimit);
		return 3;
	}

	override function make(world:Int, handle:Int):HingeConstraint {
		return new HingeConstraint(world, handle);
	}
}
