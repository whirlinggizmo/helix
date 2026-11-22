package helix.box2d;

/** Controls the relative velocity, and optionally the relative transform, of two bodies. With a velocity of zero it acts like top-down friction. */
class B2MotorJointDef {
	/** Base joint definition. Its bodies, frames and thresholds are set here. */
	public var base:B2JointDef;

	/** The linear velocity to aim for, in meters per second. Defaults to zero. */
	public var linearVelocity:B2Vec2;

	/** The most force the motor applies to reach the linear velocity, in newtons. Defaults to 0. */
	public var maxVelocityForce:Float;

	/** The angular velocity to aim for, in radians per second. Defaults to 0. */
	public var angularVelocity:Float;

	/** The most torque the motor applies to reach the angular velocity, in newton-meters. Defaults to 0. */
	public var maxVelocityTorque:Float;

	/** The stiffness of the linear spring that holds the relative position, in cycles per second. Defaults to 0. */
	public var linearHertz:Float;

	/** The damping ratio of the linear spring, non-dimensional. Defaults to 0. */
	public var linearDampingRatio:Float;

	/** The most force the linear spring applies, in newtons. Defaults to 0. */
	public var maxSpringForce:Float;

	/** The stiffness of the angular spring that holds the relative angle, in cycles per second. Defaults to 0. */
	public var angularHertz:Float;

	/** The damping ratio of the angular spring, non-dimensional. Defaults to 0. */
	public var angularDampingRatio:Float;

	/** The most torque the angular spring applies, in newton-meters. Defaults to 0. */
	public var maxSpringTorque:Float;

	/** Creates one holding Box2D's defaults, as `b2DefaultMotorJointDef()` returns. */
	public function new() {
		throw "not built yet";
	}
}
