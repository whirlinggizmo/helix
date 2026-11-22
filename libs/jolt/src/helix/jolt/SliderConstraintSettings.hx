package helix.jolt;

import helix.jolt.internal.Io;

/** Represents a constraint letting two bodies move apart along one axis, without turning: a drawer, a piston. */
class SliderConstraintSettings extends TwoBodyConstraintSettings<SliderConstraint> {
	/** Gets or sets a value indicating whether the point is where the bodies are when the constraint is made. Defaults to false. */
	public var mAutoDetectPoint:Bool = false;

	/** Gets or sets the slider's point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPoint1:RVec3;

	/** Gets or sets the slider's axis on the first body. Defaults to (1, 0, 0). */
	public var mSliderAxis1:Vec3;

	/** Gets or sets an axis at right angles to the slider's on the first body. Defaults to (0, 1, 0). */
	public var mNormalAxis1:Vec3;

	/** Gets or sets the slider's point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPoint2:RVec3;

	/** Gets or sets the slider's axis on the second body. Defaults to (1, 0, 0). */
	public var mSliderAxis2:Vec3;

	/** Gets or sets an axis at right angles to the slider's on the second body. Defaults to (0, 1, 0). */
	public var mNormalAxis2:Vec3;

	/** Gets or sets the lowest position, in meters. Defaults to minus the largest float: no limit. */
	public var mLimitsMin:Float = -3.4028234663852886e38;

	/** Gets or sets the highest position, in meters. Defaults to the largest float: no limit. */
	public var mLimitsMax:Float = 3.4028234663852886e38;

	/** Gets or sets the spring at the positions' limits. Rigid by default. */
	public var mLimitsSpringSettings:SpringSettings;

	/** Gets or sets the friction force that slows the slider, in newtons. Defaults to 0. */
	public var mMaxFrictionForce:Float = 0;

	/** Gets or sets the motor: by default with no force limit, and off until the constraint's `SetMotorState`. */
	public var mMotorSettings:MotorSettings;

	/** Creates the settings. */
	public function new() {
		super();
		mPoint1 = new RVec3();
		mSliderAxis1 = new Vec3(1, 0, 0);
		mNormalAxis1 = new Vec3(0, 1, 0);
		mPoint2 = new RVec3();
		mSliderAxis2 = new Vec3(1, 0, 0);
		mNormalAxis2 = new Vec3(0, 1, 0);
		mLimitsSpringSettings = new SpringSettings();
		mMotorSettings = new MotorSettings();
	}

	override function write():Int {
		super.write();
		Io.setI(2, mAutoDetectPoint ? 1 : 0);
		Io.setF(0, mPoint1.x);
		Io.setF(1, mPoint1.y);
		Io.setF(2, mPoint1.z);
		Io.setF(3, mSliderAxis1.x);
		Io.setF(4, mSliderAxis1.y);
		Io.setF(5, mSliderAxis1.z);
		Io.setF(6, mNormalAxis1.x);
		Io.setF(7, mNormalAxis1.y);
		Io.setF(8, mNormalAxis1.z);
		Io.setF(9, mPoint2.x);
		Io.setF(10, mPoint2.y);
		Io.setF(11, mPoint2.z);
		Io.setF(12, mSliderAxis2.x);
		Io.setF(13, mSliderAxis2.y);
		Io.setF(14, mSliderAxis2.z);
		Io.setF(15, mNormalAxis2.x);
		Io.setF(16, mNormalAxis2.y);
		Io.setF(17, mNormalAxis2.z);
		Io.setF(18, mLimitsMin);
		Io.setF(19, mLimitsMax);
		Io.setF(20, mMaxFrictionForce);
		Io.setI(3, cast mLimitsSpringSettings.mMode);
		Io.setF(21, mLimitsSpringSettings.mFrequency);
		Io.setF(22, mLimitsSpringSettings.mStiffness);
		Io.setF(23, mLimitsSpringSettings.mDamping);
		Io.setI(4, cast mMotorSettings.mSpringSettings.mMode);
		Io.setF(24, mMotorSettings.mSpringSettings.mFrequency);
		Io.setF(25, mMotorSettings.mSpringSettings.mStiffness);
		Io.setF(26, mMotorSettings.mSpringSettings.mDamping);
		Io.setF(27, mMotorSettings.mMinForceLimit);
		Io.setF(28, mMotorSettings.mMaxForceLimit);
		Io.setF(29, mMotorSettings.mMinTorqueLimit);
		Io.setF(30, mMotorSettings.mMaxTorqueLimit);
		return 4;
	}

	override function make(world:Int, handle:Int):SliderConstraint {
		return new SliderConstraint(world, handle);
	}
}
