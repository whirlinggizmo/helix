package helix.jolt;

/** Represents a slider, made by `SliderConstraintSettings`. */
class SliderConstraint extends TwoBodyConstraint {
	function new() {
		super();
	}

	/** Returns the slider's position, 0 at the pose the bodies had when the constraint was made.

		@return  The position, in meters. */
	public function GetCurrentPosition():Float {
		throw "not built yet";
	}

	/** Sets the friction force that slows the slider.

		@param inFrictionForce  The force, in newtons. */
	public function SetMaxFrictionForce(inFrictionForce:Float):Void {
		throw "not built yet";
	}

	/** Returns the friction force that slows the slider.

		@return  The force, in newtons. */
	public function GetMaxFrictionForce():Float {
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

	/** Sets the velocity the motor drives to, under `EMotorState_Velocity`.

		@param inVelocity  The velocity, in meters a second. */
	public function SetTargetVelocity(inVelocity:Float):Void {
		throw "not built yet";
	}

	/** Returns the velocity the motor drives to.

		@return  The velocity, in meters a second. */
	public function GetTargetVelocity():Float {
		throw "not built yet";
	}

	/** Sets the position the motor drives to, under `EMotorState_Position`.

		@param inPosition  The position, in meters. */
	public function SetTargetPosition(inPosition:Float):Void {
		throw "not built yet";
	}

	/** Returns the position the motor drives to.

		@return  The position, in meters. */
	public function GetTargetPosition():Float {
		throw "not built yet";
	}

	/** Sets the slider's limits.

		@param inLimitsMin  The lowest position, in meters.
		@param inLimitsMax  The highest position, in meters. */
	public function SetLimits(inLimitsMin:Float, inLimitsMax:Float):Void {
		throw "not built yet";
	}

	/** Returns the lowest position.

		@return  The position, in meters. */
	public function GetLimitsMin():Float {
		throw "not built yet";
	}

	/** Returns the highest position.

		@return  The position, in meters. */
	public function GetLimitsMax():Float {
		throw "not built yet";
	}

	/** Returns whether the slider is limited.

		@return  True when the slider has a lowest or highest position. */
	public function HasLimits():Bool {
		throw "not built yet";
	}
}
