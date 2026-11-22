package helix.jolt;

/** Represents a constraint's motor: how hard it drives, and how its target is reached. */
class MotorSettings {
	/** Gets or sets the spring the motor drives to a position with. Defaults to 2 hertz, damping 1. */
	public var mSpringSettings:SpringSettings;

	/** Gets or sets the most force the motor pushes back with, in newtons, 0 or less. Defaults to minus the largest float. */
	public var mMinForceLimit:Float = -3.4028234663852886e38;

	/** Gets or sets the most force the motor pushes with, in newtons. Defaults to the largest float. */
	public var mMaxForceLimit:Float = 3.4028234663852886e38;

	/** Gets or sets the most torque the motor turns back with, in newton meters, 0 or less. Defaults to minus the largest float. */
	public var mMinTorqueLimit:Float = -3.4028234663852886e38;

	/** Gets or sets the most torque the motor turns with, in newton meters. Defaults to the largest float. */
	public var mMaxTorqueLimit:Float = 3.4028234663852886e38;

	/** Creates a motor with no limit. */
	public function new() {
		mSpringSettings = new SpringSettings();
		mSpringSettings.mFrequency = 2;
		mSpringSettings.mDamping = 1;
	}
}
