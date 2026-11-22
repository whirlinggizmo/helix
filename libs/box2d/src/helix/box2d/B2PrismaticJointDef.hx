package helix.box2d;

/** Lets body B slide along the x-axis of the local frame in body A, with no rotation relative to it. */
class B2PrismaticJointDef {
	/** Base joint definition. Its bodies, frames and thresholds are set here. */
	public var base:B2JointDef;

	/** Whether a linear spring acts along the joint axis. Defaults to false. */
	public var enableSpring:Bool;

	/** The spring stiffness, in cycles per second. Defaults to 0. */
	public var hertz:Float;

	/** The spring damping ratio, non-dimensional. Defaults to 0. */
	public var dampingRatio:Float;

	/** The translation the spring aims for, in length units. Defaults to 0. */
	public var targetTranslation:Float;

	/** Whether the translation is limited. Defaults to false. */
	public var enableLimit:Bool;

	/** The lowest translation the limit allows, in length units. Defaults to 0. */
	public var lowerTranslation:Float;

	/** The highest translation the limit allows, in length units. Defaults to 0. */
	public var upperTranslation:Float;

	/** Whether the joint motor is on. Defaults to false. */
	public var enableMotor:Bool;

	/** The most force the motor applies, typically in newtons. Defaults to 0. */
	public var maxMotorForce:Float;

	/** The speed the motor aims for, typically in meters per second. Defaults to 0. */
	public var motorSpeed:Float;

	/** Creates one holding Box2D's defaults, as `b2DefaultPrismaticJointDef()` returns. The structs it holds are made with it. */
	public function new() {
		throw "not built yet";
	}
}
