package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Represents a six degrees of freedom constraint, made by `SixDOFConstraintSettings`. Its targets are in the constraint's space,
	which `CS` ends their names with. */
class SixDOFConstraint extends TwoBodyConstraint {
	@:allow(helix.jolt) function new(world:Int, handle:Int) {
		super(world, handle);
	}

	/** Sets the limits of moving along each axis.

		@param inLimitMin  The lowest positions, in meters.
		@param inLimitMax  The highest positions, in meters. */
	public function SetTranslationLimits(inLimitMin:Vec3, inLimitMax:Vec3):Void {
		Io.setF(0, inLimitMin.x);
		Io.setF(1, inLimitMin.y);
		Io.setF(2, inLimitMin.z);
		Io.setF(3, inLimitMax.x);
		Io.setF(4, inLimitMax.y);
		Io.setF(5, inLimitMax.z);
		Hj.constraintSixDofSetLimits(world, handle, 1);
	}

	/** Sets the limits of turning about each axis.

		@param inLimitMin  The smallest angles, in radians.
		@param inLimitMax  The largest angles, in radians. */
	public function SetRotationLimits(inLimitMin:Vec3, inLimitMax:Vec3):Void {
		Io.setF(0, inLimitMin.x);
		Io.setF(1, inLimitMin.y);
		Io.setF(2, inLimitMin.z);
		Io.setF(3, inLimitMax.x);
		Io.setF(4, inLimitMax.y);
		Io.setF(5, inLimitMax.z);
		Hj.constraintSixDofSetLimits(world, handle, 0);
	}

	/** Returns an axis' lowest value.

		@param inAxis  The axis.
		@return  The value: meters or radians. */
	public function GetLimitsMin(inAxis:SixDOFConstraintSettings_EAxis):Float {
		return Hj.constraintGetFloat(world, handle, 40 + (cast inAxis : Int));
	}

	/** Returns an axis' highest value.

		@param inAxis  The axis.
		@return  The value: meters or radians. */
	public function GetLimitsMax(inAxis:SixDOFConstraintSettings_EAxis):Float {
		return Hj.constraintGetFloat(world, handle, 50 + (cast inAxis : Int));
	}

	/** Returns whether an axis is fixed.

		@param inAxis  The axis.
		@return  True when fixed. */
	public function IsFixedAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		return Hj.constraintGetFloat(world, handle, 60 + (cast inAxis : Int)) != 0;
	}

	/** Returns whether an axis is free.

		@param inAxis  The axis.
		@return  True when free. */
	public function IsFreeAxis(inAxis:SixDOFConstraintSettings_EAxis):Bool {
		return Hj.constraintGetFloat(world, handle, 70 + (cast inAxis : Int)) != 0;
	}

	/** Sets an axis' friction.

		@param inAxis  The axis.
		@param inFriction  A force, in newtons, or a torque, in newton meters. */
	public function SetMaxFriction(inAxis:SixDOFConstraintSettings_EAxis, inFriction:Float):Void {
		Hj.constraintSetFloat(world, handle, 80 + (cast inAxis : Int), inFriction);
	}

	/** Returns an axis' motor settings, which may be changed in place.

		@param inAxis  The axis.
		@return  The settings. */
	public function GetMotorSettings(inAxis:SixDOFConstraintSettings_EAxis):MotorSettings {
		return motor((cast inAxis : Int));
	}

	/** Sets what an axis' motor drives toward.

		@param inAxis  The axis.
		@param inState  The state. */
	public function SetMotorState(inAxis:SixDOFConstraintSettings_EAxis, inState:EMotorState):Void {
		Hj.constraintSetMotorState(world, handle, (cast inAxis : Int), cast inState);
	}

	/** Returns what an axis' motor drives toward.

		@param inAxis  The axis.
		@return  The state. */
	public function GetMotorState(inAxis:SixDOFConstraintSettings_EAxis):EMotorState {
		return cast Hj.constraintGetMotorState(world, handle, (cast inAxis : Int));
	}

	/** Sets the velocity the motors drive to.

		@param inVelocity  The velocity, in meters a second. */
	public function SetTargetVelocityCS(inVelocity:Vec3):Void {
		Io.setF(0, inVelocity.x);
		Io.setF(1, inVelocity.y);
		Io.setF(2, inVelocity.z);
		Hj.constraintSixDofSetTarget(world, handle, 0);
	}

	/** Sets the angular velocity the motors drive to.

		@param inAngularVelocity  The angular velocity, in radians a second about each axis. */
	public function SetTargetAngularVelocityCS(inAngularVelocity:Vec3):Void {
		Io.setF(0, inAngularVelocity.x);
		Io.setF(1, inAngularVelocity.y);
		Io.setF(2, inAngularVelocity.z);
		Hj.constraintSixDofSetTarget(world, handle, 1);
	}

	/** Sets the position the motors drive to.

		@param inPosition  The position, in meters. */
	public function SetTargetPositionCS(inPosition:Vec3):Void {
		Io.setF(0, inPosition.x);
		Io.setF(1, inPosition.y);
		Io.setF(2, inPosition.z);
		Hj.constraintSixDofSetTarget(world, handle, 2);
	}

	/** Sets the rotation the motors drive to.

		@param inOrientation  The rotation. */
	public function SetTargetOrientationCS(inOrientation:Quat):Void {
		Io.setF(0, inOrientation.x);
		Io.setF(1, inOrientation.y);
		Io.setF(2, inOrientation.z);
		Io.setF(3, inOrientation.w);
		Hj.constraintSixDofSetTarget(world, handle, 3);
	}
}
