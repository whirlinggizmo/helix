package helix.box2d;

/** Makes body B a wheel that rotates freely and slides along the x-axis of the local frame in body A, usually with a spring for the suspension. */
class B2WheelJointDef {
	/** Base joint definition. Its bodies, frames and thresholds are set here. */
	public var base:B2JointDef;

	/** Whether a linear spring acts along the local axis. Defaults to true. */
	public var enableSpring:Bool;

	/** The spring stiffness, in cycles per second. Defaults to 1. */
	public var hertz:Float;

	/** The spring damping ratio, non-dimensional. Defaults to 0.7. */
	public var dampingRatio:Float;

	/** Whether the translation along the axis is limited. Defaults to false. */
	public var enableLimit:Bool;

	/** The lowest translation the limit allows, in length units. Defaults to 0. */
	public var lowerTranslation:Float;

	/** The highest translation the limit allows, in length units. Defaults to 0. */
	public var upperTranslation:Float;

	/** Whether the rotational motor is on. Defaults to false. */
	public var enableMotor:Bool;

	/** The most torque the motor applies, typically in newton-meters. Defaults to 0. */
	public var maxMotorTorque:Float;

	/** The speed the motor aims for, in radians per second. Defaults to 0. */
	public var motorSpeed:Float;

	/** Creates one holding Box2D's defaults, as `b2DefaultWheelJointDef()` returns. */
	public function new() {
		throw "not built yet";
	}
}
