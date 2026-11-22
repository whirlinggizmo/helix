package helix.box2d;

/** The settings every joint type shares, held in the `base` field of each joint definition. The local frames are measured from each body's origin and not its center of mass, since the center of mass may not be known yet and changes when shapes are added or removed. */
class B2JointDef {
	/** Any Haxe value the program keeps with the joint, returned as set. Defaults to null. */
	public var userData:Dynamic;

	/** The first attached body. Defaults to the null id, which must be replaced. */
	public var bodyIdA:B2BodyId;

	/** The second attached body. Defaults to the null id, which must be replaced. */
	public var bodyIdB:B2BodyId;

	/** The joint's frame in the first body, measured from the body's origin. Defaults to the body's origin with no rotation. */
	public var localFrameA:B2Transform;

	/** The joint's frame in the second body, measured from the body's origin. Defaults to the body's origin with no rotation. */
	public var localFrameB:B2Transform;

	/** The force above which an awake joint reports a joint event, in newtons. Defaults to the largest float, so none is reported. */
	public var forceThreshold:Float;

	/** The torque above which an awake joint reports a joint event, in newton-meters. Defaults to the largest float, so none is reported. */
	public var torqueThreshold:Float;

	/** The stiffness of the joint's constraint, in cycles per second. An advanced setting. Defaults to 60. */
	public var constraintHertz:Float;

	/** The damping ratio of the joint's constraint, non-dimensional. An advanced setting. Defaults to 2. */
	public var constraintDampingRatio:Float;

	/** The scale of the joint when debug drawn. Defaults to the world's length units per meter. */
	public var drawScale:Float;

	/** Whether the two attached bodies collide with each other. Defaults to false. */
	public var collideConnected:Bool;

	/** Creates one holding the base values that every joint's default definition starts from, as `b2DefaultDistanceJointDef()` and the other default functions set in their `base`. */
	public function new() {
		throw "not built yet";
	}
}
