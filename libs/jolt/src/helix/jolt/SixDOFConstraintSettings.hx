package helix.jolt;

import helix.jolt.internal.Io;

/** Represents a constraint whose six axes (three of moving, three of turning) are each free, fixed or limited, with a motor each. */
class SixDOFConstraintSettings extends TwoBodyConstraintSettings<SixDOFConstraint> {
	/** Gets or sets the constraint's point on the first body, in meters. Defaults to (0, 0, 0). */
	public var mPosition1:RVec3;

	/** Gets or sets the constraint's x axis on the first body. Defaults to (1, 0, 0). */
	public var mAxisX1:Vec3;

	/** Gets or sets the constraint's y axis on the first body. Defaults to (0, 1, 0). */
	public var mAxisY1:Vec3;

	/** Gets or sets the constraint's point on the second body, in meters. Defaults to (0, 0, 0). */
	public var mPosition2:RVec3;

	/** Gets or sets the constraint's x axis on the second body. Defaults to (1, 0, 0). */
	public var mAxisX2:Vec3;

	/** Gets or sets the constraint's y axis on the second body. Defaults to (0, 1, 0). */
	public var mAxisY2:Vec3;

	/** Gets or sets each axis' friction, by `SixDOFConstraintSettings_EAxis`: a force, in newtons, or a torque, in newton meters. */
	public var mMaxFriction:Array<Float>;

	/** Gets or sets each axis' lowest value, by `SixDOFConstraintSettings_EAxis`: meters or radians. */
	public var mLimitMin:Array<Float>;

	/** Gets or sets each axis' highest value, by `SixDOFConstraintSettings_EAxis`: meters or radians. */
	public var mLimitMax:Array<Float>;

	/** Gets or sets each axis' spring at its limits, by `SixDOFConstraintSettings_EAxis`. */
	public var mLimitsSpringSettings:Array<SpringSettings>;

	/** Gets or sets each axis' motor, by `SixDOFConstraintSettings_EAxis`. */
	public var mMotorSettings:Array<MotorSettings>;

	/** Creates the settings with every axis free. */
	public function new() {
		super();
		mPosition1 = new RVec3();
		mAxisX1 = new Vec3(1, 0, 0);
		mAxisY1 = new Vec3(0, 1, 0);
		mPosition2 = new RVec3();
		mAxisX2 = new Vec3(1, 0, 0);
		mAxisY2 = new Vec3(0, 1, 0);
		mMaxFriction = [for (_ in 0...6) 0.];
		mLimitMin = [for (_ in 0...6) -3.4028234663852886e38];
		mLimitMax = [for (_ in 0...6) 3.4028234663852886e38];
		mLimitsSpringSettings = [for (_ in 0...6) new SpringSettings()];
		mMotorSettings = [for (_ in 0...6) new MotorSettings()];
	}

	/** Frees an axis.

		@param inAxis  The axis. */
	public function MakeFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Void {
		mLimitMin[(cast inAxis : Int)] = -3.4028234663852886e38;
		mLimitMax[(cast inAxis : Int)] = 3.4028234663852886e38;
	}

	/** Fixes an axis.

		@param inAxis  The axis. */
	public function MakeFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Void {
		mLimitMin[(cast inAxis : Int)] = 3.4028234663852886e38;
		mLimitMax[(cast inAxis : Int)] = -3.4028234663852886e38;
	}

	/** Limits an axis to a range.

		@param inAxis  The axis.
		@param inMin  The lowest value: meters or radians.
		@param inMax  The highest value: meters or radians. */
	public function SetLimitedAxis(inAxis:SixDOFConstraintSettings_EAxis, inMin:Float, inMax:Float):Void {
		mLimitMin[(cast inAxis : Int)] = inMin;
		mLimitMax[(cast inAxis : Int)] = inMax;
	}

	/** Returns whether an axis is free.

		@param inAxis  The axis.
		@return  True when free. */
	public function IsFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		return mLimitMin[(cast inAxis : Int)] == -3.4028234663852886e38 && mLimitMax[(cast inAxis : Int)] == 3.4028234663852886e38;
	}

	/** Returns whether an axis is fixed.

		@param inAxis  The axis.
		@return  True when fixed. */
	public function IsFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		return mLimitMin[(cast inAxis : Int)] >= mLimitMax[(cast inAxis : Int)];
	}

	override function write():Int {
		super.write();
		var base = Io.bulk(108 * 4);
		var points:Array<Vec3> = [mPosition1, mAxisX1, mAxisY1, mPosition2, mAxisX2, mAxisY2];
		for (n in 0...6) {
			Io.setBulkF(base, n * 3, points[n].x);
			Io.setBulkF(base, n * 3 + 1, points[n].y);
			Io.setBulkF(base, n * 3 + 2, points[n].z);
		}
		for (a in 0...6) {
			Io.setBulkF(base, 18 + a, mMaxFriction[a]);
			Io.setBulkF(base, 24 + a, mLimitMin[a]);
			Io.setBulkF(base, 30 + a, mLimitMax[a]);
			var spring = mLimitsSpringSettings[a];
			Io.setBulkF(base, 36 + a * 3, spring.mFrequency);
			Io.setBulkF(base, 37 + a * 3, spring.mStiffness);
			Io.setBulkF(base, 38 + a * 3, spring.mDamping);
			var motor = mMotorSettings[a];
			Io.setBulkF(base, 54 + a * 7, motor.mSpringSettings.mFrequency);
			Io.setBulkF(base, 55 + a * 7, motor.mSpringSettings.mStiffness);
			Io.setBulkF(base, 56 + a * 7, motor.mSpringSettings.mDamping);
			Io.setBulkF(base, 57 + a * 7, motor.mMinForceLimit);
			Io.setBulkF(base, 58 + a * 7, motor.mMaxForceLimit);
			Io.setBulkF(base, 59 + a * 7, motor.mMinTorqueLimit);
			Io.setBulkF(base, 60 + a * 7, motor.mMaxTorqueLimit);
			Io.setBulkI(base, 96 + a, cast spring.mMode);
			Io.setBulkI(base, 102 + a, cast motor.mSpringSettings.mMode);
		}
		return 6;
	}

	override function make(world:Int, handle:Int):SixDOFConstraint {
		return new SixDOFConstraint(world, handle);
	}
}
