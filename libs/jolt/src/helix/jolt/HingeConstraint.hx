package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents a hinge, made by `HingeConstraintSettings`. */
class HingeConstraint extends TwoBodyConstraint {
	@:allow(helix.jolt) function new(world:Int, handle:Int) {
		super(world, handle);
	}

	/** Returns the hinge's angle, 0 at the pose the bodies had when the constraint was made.

		@return  The angle, in radians. */
	public function GetCurrentAngle():Float {
		return Hj.constraintGetFloat(world, handle, 0);
	}

	/** Sets the friction torque that slows the hinge.

		@param inFrictionTorque  The torque, in newton meters. */
	public function SetMaxFrictionTorque(inFrictionTorque:Float):Void {
		Hj.constraintSetFloat(world, handle, 1, inFrictionTorque);
	}

	/** Returns the friction torque that slows the hinge.

		@return  The torque, in newton meters. */
	public function GetMaxFrictionTorque():Float {
		return Hj.constraintGetFloat(world, handle, 1);
	}

	/** Returns the motor's settings, which may be changed in place.

		@return  The settings. */
	public function GetMotorSettings():MotorSettings {
		return motor(-1);
	}

	/** Sets what the motor drives toward.

		@param inState  The state. */
	public function SetMotorState(inState:EMotorState):Void {
		Hj.constraintSetMotorState(world, handle, -1, cast inState);
	}

	/** Returns what the motor drives toward.

		@return  The state. */
	public function GetMotorState():EMotorState {
		return cast Hj.constraintGetMotorState(world, handle, -1);
	}

	/** Sets the angular velocity the motor drives to, under `EMotorState_Velocity`.

		@param inAngularVelocity  The angular velocity, in radians a second. */
	public function SetTargetAngularVelocity(inAngularVelocity:Float):Void {
		Hj.constraintSetFloat(world, handle, 2, inAngularVelocity);
	}

	/** Returns the angular velocity the motor drives to.

		@return  The angular velocity, in radians a second. */
	public function GetTargetAngularVelocity():Float {
		return Hj.constraintGetFloat(world, handle, 2);
	}

	/** Sets the angle the motor drives to, under `EMotorState_Position`.

		@param inAngle  The angle, in radians. */
	public function SetTargetAngle(inAngle:Float):Void {
		Hj.constraintSetFloat(world, handle, 3, inAngle);
	}

	/** Returns the angle the motor drives to.

		@return  The angle, in radians. */
	public function GetTargetAngle():Float {
		return Hj.constraintGetFloat(world, handle, 3);
	}

	/** Sets the hinge's limits.

		@param inLimitsMin  The smallest angle, in radians, -pi to 0.
		@param inLimitsMax  The largest angle, in radians, 0 to pi. */
	public function SetLimits(inLimitsMin:Float, inLimitsMax:Float):Void {
		Hj.constraintSetRange(world, handle, inLimitsMin, inLimitsMax);
	}

	/** Returns the smallest angle.

		@return  The angle, in radians. */
	public function GetLimitsMin():Float {
		return Hj.constraintGetFloat(world, handle, 4);
	}

	/** Returns the largest angle.

		@return  The angle, in radians. */
	public function GetLimitsMax():Float {
		return Hj.constraintGetFloat(world, handle, 5);
	}

	/** Returns whether the hinge is limited.

		@return  True when the limits are narrower than a whole turn. */
	public function HasLimits():Bool {
		return Hj.constraintGetFloat(world, handle, 6) != 0;
	}
}
