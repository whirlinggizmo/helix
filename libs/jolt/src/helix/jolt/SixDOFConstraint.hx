package helix.jolt;

/** Represents a six degrees of freedom constraint, made by `SixDOFConstraintSettings`. Its targets are in the constraint's space,
	which `CS` ends their names with. */
class SixDOFConstraint extends TwoBodyConstraint {
	function new() {
		super();
	}

	/** Sets the limits of moving along each axis.

		@param inLimitMin  The lowest positions, in meters.
		@param inLimitMax  The highest positions, in meters. */
	public function SetTranslationLimits(inLimitMin:Vec3, inLimitMax:Vec3):Void {
		throw "not built yet";
	}

	/** Sets the limits of turning about each axis.

		@param inLimitMin  The smallest angles, in radians.
		@param inLimitMax  The largest angles, in radians. */
	public function SetRotationLimits(inLimitMin:Vec3, inLimitMax:Vec3):Void {
		throw "not built yet";
	}

	/** Returns an axis' lowest value.

		@param inAxis  The axis.
		@return  The value: meters or radians. */
	public function GetLimitsMin(inAxis:SixDOFConstraintSettings_EAxis):Float {
		throw "not built yet";
	}

	/** Returns an axis' highest value.

		@param inAxis  The axis.
		@return  The value: meters or radians. */
	public function GetLimitsMax(inAxis:SixDOFConstraintSettings_EAxis):Float {
		throw "not built yet";
	}

	/** Returns whether an axis is fixed.

		@param inAxis  The axis.
		@return  True when fixed. */
	public function IsFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		throw "not built yet";
	}

	/** Returns whether an axis is free.

		@param inAxis  The axis.
		@return  True when free. */
	public function IsFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		throw "not built yet";
	}

	/** Sets an axis' friction.

		@param inAxis  The axis.
		@param inFriction  A force, in newtons, or a torque, in newton meters. */
	public function SetMaxFriction(inAxis:SixDOFConstraintSettings_EAxis, inFriction:Float):Void {
		throw "not built yet";
	}

	/** Returns an axis' motor settings, which may be changed in place.

		@param inAxis  The axis.
		@return  The settings. */
	public function GetMotorSettings(inAxis:SixDOFConstraintSettings_EAxis):MotorSettings {
		throw "not built yet";
	}

	/** Sets what an axis' motor drives toward.

		@param inAxis  The axis.
		@param inState  The state. */
	public function SetMotorState(inAxis:SixDOFConstraintSettings_EAxis, inState:EMotorState):Void {
		throw "not built yet";
	}

	/** Returns what an axis' motor drives toward.

		@param inAxis  The axis.
		@return  The state. */
	public function GetMotorState(inAxis:SixDOFConstraintSettings_EAxis):EMotorState {
		throw "not built yet";
	}

	/** Sets the velocity the motors drive to.

		@param inVelocity  The velocity, in meters a second. */
	public function SetTargetVelocityCS(inVelocity:Vec3):Void {
		throw "not built yet";
	}

	/** Sets the angular velocity the motors drive to.

		@param inAngularVelocity  The angular velocity, in radians a second about each axis. */
	public function SetTargetAngularVelocityCS(inAngularVelocity:Vec3):Void {
		throw "not built yet";
	}

	/** Sets the position the motors drive to.

		@param inPosition  The position, in meters. */
	public function SetTargetPositionCS(inPosition:Vec3):Void {
		throw "not built yet";
	}

	/** Sets the rotation the motors drive to.

		@param inOrientation  The rotation. */
	public function SetTargetOrientationCS(inOrientation:Quat):Void {
		throw "not built yet";
	}
}
