package helix.box2d;

/** Connects two bodies together rigidly, or with some flex when the stiffness is set. */
class B2WeldJointDef {
	/** Base joint definition. Its bodies, frames and thresholds are set here. */
	public var base:B2JointDef;

	/** The linear stiffness, in cycles per second. 0 is the maximum stiffness. Defaults to 0. */
	public var linearHertz:Float;

	/** The angular stiffness, in cycles per second. 0 is the maximum stiffness. Defaults to 0. */
	public var angularHertz:Float;

	/** The linear damping ratio, non-dimensional. 1 is critical damping. Defaults to 0. */
	public var linearDampingRatio:Float;

	/** The angular damping ratio, non-dimensional. 1 is critical damping. Defaults to 0. */
	public var angularDampingRatio:Float;

	/** Creates one holding Box2D's defaults, as `b2DefaultWeldJointDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2WeldJointDef(this);
		helix.box2d.internal.Calls.b2DefaultWeldJointDef(this);
	}
}
