package helix.box2d;

/** Stops two specific bodies from colliding with each other. */
class B2FilterJointDef {
	/** Base joint definition. Its bodies, frames and thresholds are set here. */
	public var base:B2JointDef;

	/** Creates one holding Box2D's defaults, as `b2DefaultFilterJointDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2FilterJointDef(this);
		helix.box2d.internal.Calls.b2DefaultFilterJointDef(this);
	}
}
