package helix.jolt;

/** Represents a hinge, made by `HingeConstraintSettings`. */
class HingeConstraint extends TwoBodyConstraint {
	function new() {
		super();
	}

	/** Returns the hinge's angle, 0 at the pose the bodies had when the constraint was made.

		@return  The angle, in radians. */
	public function GetCurrentAngle():Float {
		throw "not built yet";
	}

	/** Sets the friction torque that slows the hinge.

		@param inFrictionTorque  The torque, in newton meters. */
	public function SetMaxFrictionTorque(inFrictionTorque:Float):Void {
		throw "not built yet";
	}

	/** Returns the friction torque that slows the hinge.

		@return  The torque, in newton meters. */
	public function GetMaxFrictionTorque():Float {
		throw "not built yet";
	}

	/** Returns the motor's settings, which may be changed in place.

		@return  The settings. */
	public function GetMotorSettings():MotorSettings {
		throw "not built yet";
	}

	/** Sets what the motor drives toward.

		@param inState  The state. */
	public function SetMotorState(inState:EMotorState):Void {
		throw "not built yet";
	}

	/** Returns what the motor drives toward.

		@return  The state. */
	public function GetMotorState():EMotorState {
		throw "not built yet";
	}

	/** Sets the angular velocity the motor drives to, under `EMotorState_Velocity`.

		@param inAngularVelocity  The angular velocity, in radians a second. */
	public function SetTargetAngularVelocity(inAngularVelocity:Float):Void {
		throw "not built yet";
	}

	/** Returns the angular velocity the motor drives to.

		@return  The angular velocity, in radians a second. */
	public function GetTargetAngularVelocity():Float {
		throw "not built yet";
	}

	/** Sets the angle the motor drives to, under `EMotorState_Position`.

		@param inAngle  The angle, in radians. */
	public function SetTargetAngle(inAngle:Float):Void {
		throw "not built yet";
	}

	/** Returns the angle the motor drives to.

		@return  The angle, in radians. */
	public function GetTargetAngle():Float {
		throw "not built yet";
	}

	/** Sets the hinge's limits.

		@param inLimitsMin  The smallest angle, in radians, -pi to 0.
		@param inLimitsMax  The largest angle, in radians, 0 to pi. */
	public function SetLimits(inLimitsMin:Float, inLimitsMax:Float):Void {
		throw "not built yet";
	}

	/** Returns the smallest angle.

		@return  The angle, in radians. */
	public function GetLimitsMin():Float {
		throw "not built yet";
	}

	/** Returns the largest angle.

		@return  The angle, in radians. */
	public function GetLimitsMax():Float {
		throw "not built yet";
	}

	/** Returns whether the hinge is limited.

		@return  True when the limits are narrower than a whole turn. */
	public function HasLimits():Bool {
		throw "not built yet";
	}
}
