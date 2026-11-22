package helix.box2d;

/** Fixes a point on body B to a point on body A, so the bodies rotate about it like a hinge. */
class B2RevoluteJointDef {
	/** Base joint definition. Its bodies, frames and thresholds are set here. */
	public var base:B2JointDef;

	/** The angle the spring aims for, in radians. Defaults to 0. */
	public var targetAngle:Float;

	/** Whether a rotational spring acts on the hinge. Defaults to false. */
	public var enableSpring:Bool;

	/** The spring stiffness, in cycles per second. Defaults to 0. */
	public var hertz:Float;

	/** The spring damping ratio, non-dimensional. Defaults to 0. */
	public var dampingRatio:Float;

	/** Whether the angle is limited. Defaults to false. */
	public var enableLimit:Bool;

	/** The lowest angle the limit allows, in radians. At least -0.99 times pi. Defaults to 0. */
	public var lowerAngle:Float;

	/** The highest angle the limit allows, in radians. At most 0.99 times pi. Defaults to 0. */
	public var upperAngle:Float;

	/** Whether the joint motor is on. Defaults to false. */
	public var enableMotor:Bool;

	/** The most torque the motor applies, typically in newton-meters. Defaults to 0. */
	public var maxMotorTorque:Float;

	/** The speed the motor aims for, in radians per second: body B's angular velocity relative to body A's. Positive turns body B counterclockwise relative to body A. Defaults to 0. */
	public var motorSpeed:Float;

	/** Creates one holding Box2D's defaults, as `b2DefaultRevoluteJointDef()` returns. The structs it holds are made with it. */
	public function new() {
		throw "not built yet";
	}
}
