package helix.box2d;

/** Keeps a point on body A and a point on body B at a distance, like a segment. Useful for ropes and springs. */
class B2DistanceJointDef {
	/** Base joint definition. Its bodies, frames and thresholds are set here. */
	public var base:B2JointDef;

	/** The rest length of the joint, in length units. Clamped to a stable minimum. Defaults to 1. */
	public var length:Float;

	/** Whether the joint acts as a spring. When false the joint is rigid, and its limit and motor are ignored. Defaults to false. */
	public var enableSpring:Bool;

	/** The most tension the spring can sustain, as a force. Defaults to the most negative float. */
	public var lowerSpringForce:Float;

	/** The most compression the spring can sustain, as a force. Defaults to the largest float. */
	public var upperSpringForce:Float;

	/** The spring stiffness, in cycles per second. Defaults to 0. */
	public var hertz:Float;

	/** The spring damping ratio, non-dimensional. Defaults to 0. */
	public var dampingRatio:Float;

	/** Whether the joint keeps its length between `minLength` and `maxLength`. Defaults to false. */
	public var enableLimit:Bool;

	/** The shortest length for the limit, in length units. Clamped to a stable minimum. Defaults to 0. */
	public var minLength:Float;

	/** The longest length for the limit, in length units. At least `minLength`. Defaults to `B2_HUGE`. */
	public var maxLength:Float;

	/** Whether the joint motor is on. Defaults to false. */
	public var enableMotor:Bool;

	/** The most force the motor applies, usually in newtons. Defaults to 0. */
	public var maxMotorForce:Float;

	/** The speed the motor aims for, usually in meters per second. Defaults to 0. */
	public var motorSpeed:Float;

	/** Creates one holding Box2D's defaults, as `b2DefaultDistanceJointDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2DistanceJointDef(this);
		helix.box2d.internal.Calls.b2DefaultDistanceJointDef(this);
	}
}
