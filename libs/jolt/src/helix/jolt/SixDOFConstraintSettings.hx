package helix.jolt;

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
		throw "not built yet";
	}

	/** Frees an axis.

		@param inAxis  The axis. */
	public function MakeFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Void {
		throw "not built yet";
	}

	/** Fixes an axis.

		@param inAxis  The axis. */
	public function MakeFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Void {
		throw "not built yet";
	}

	/** Limits an axis to a range.

		@param inAxis  The axis.
		@param inMin  The lowest value: meters or radians.
		@param inMax  The highest value: meters or radians. */
	public function SetLimitedAxis(inAxis:SixDOFConstraintSettings_EAxis, inMin:Float, inMax:Float):Void {
		throw "not built yet";
	}

	/** Returns whether an axis is free.

		@param inAxis  The axis.
		@return  True when free. */
	public function IsFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		throw "not built yet";
	}

	/** Returns whether an axis is fixed.

		@param inAxis  The axis.
		@return  True when fixed. */
	public function IsFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		throw "not built yet";
	}
}
