package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents a slider, made by `SliderConstraintSettings`. */
class SliderConstraint extends TwoBodyConstraint {
	@:allow(helix.jolt) function new(world:Int, handle:Int) {
		super(world, handle);
	}

	/** Returns the slider's position, 0 at the pose the bodies had when the constraint was made.

		@return  The position, in meters. */
	public function GetCurrentPosition():Float {
		return Hj.constraintGetFloat(world, handle, 10);
	}

	/** Sets the friction force that slows the slider.

		@param inFrictionForce  The force, in newtons. */
	public function SetMaxFrictionForce(inFrictionForce:Float):Void {
		Hj.constraintSetFloat(world, handle, 11, inFrictionForce);
	}

	/** Returns the friction force that slows the slider.

		@return  The force, in newtons. */
	public function GetMaxFrictionForce():Float {
		return Hj.constraintGetFloat(world, handle, 11);
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

	/** Sets the velocity the motor drives to, under `EMotorState_Velocity`.

		@param inVelocity  The velocity, in meters a second. */
	public function SetTargetVelocity(inVelocity:Float):Void {
		Hj.constraintSetFloat(world, handle, 12, inVelocity);
	}

	/** Returns the velocity the motor drives to.

		@return  The velocity, in meters a second. */
	public function GetTargetVelocity():Float {
		return Hj.constraintGetFloat(world, handle, 12);
	}

	/** Sets the position the motor drives to, under `EMotorState_Position`.

		@param inPosition  The position, in meters. */
	public function SetTargetPosition(inPosition:Float):Void {
		Hj.constraintSetFloat(world, handle, 13, inPosition);
	}

	/** Returns the position the motor drives to.

		@return  The position, in meters. */
	public function GetTargetPosition():Float {
		return Hj.constraintGetFloat(world, handle, 13);
	}

	/** Sets the slider's limits.

		@param inLimitsMin  The lowest position, in meters.
		@param inLimitsMax  The highest position, in meters. */
	public function SetLimits(inLimitsMin:Float, inLimitsMax:Float):Void {
		Hj.constraintSetRange(world, handle, inLimitsMin, inLimitsMax);
	}

	/** Returns the lowest position.

		@return  The position, in meters. */
	public function GetLimitsMin():Float {
		return Hj.constraintGetFloat(world, handle, 14);
	}

	/** Returns the highest position.

		@return  The position, in meters. */
	public function GetLimitsMax():Float {
		return Hj.constraintGetFloat(world, handle, 15);
	}

	/** Returns whether the slider is limited.

		@return  True when the slider has a lowest or highest position. */
	public function HasLimits():Bool {
		return Hj.constraintGetFloat(world, handle, 16) != 0;
	}
}
