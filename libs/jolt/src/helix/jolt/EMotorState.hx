package helix.jolt;

/** Specifies what a constraint's motor drives toward. */
enum abstract EMotorState(Int) {
	/** Nothing: the motor is off. */
	var EMotorState_Off = 0;

	/** A target velocity. */
	var EMotorState_Velocity = 1;

	/** A target position or angle. */
	var EMotorState_Position = 2;

	/** A target position or angle, at a target velocity. */
	var EMotorState_PositionAndVelocity = 3;
}
