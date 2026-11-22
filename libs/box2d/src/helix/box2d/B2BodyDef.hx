package helix.box2d;

/** Everything needed to create a body with `b2CreateBody`. The definition can be reused for more bodies. Shapes are added to a body after it's created. */
class B2BodyDef {
	/** How the body moves: static, kinematic or dynamic. Defaults to `b2_staticBody`. */
	public var type:B2BodyType;

	/** The body's starting position in the world, in length units. Create the body here, since creating it at the origin and moving it afterward nearly doubles the cost. Defaults to the origin. */
	public var position:B2Pos;

	/** The body's starting rotation. Make one from an angle with `b2MakeRot`. Defaults to no rotation. */
	public var rotation:B2Rot;

	/** The starting velocity of the body's origin, in meters per second. Defaults to zero. */
	public var linearVelocity:B2Vec2;

	/** The starting angular velocity, in radians per second. Defaults to 0. */
	public var angularVelocity:Float;

	/** Slows the body's linear velocity over time. 0 or more. A large value makes the effect depend on the time step, and any damping makes objects move as if floating. Defaults to 0. */
	public var linearDamping:Float;

	/** Slows the body's angular velocity over time. 0 or more. A large value makes the effect depend on the time step. Defaults to 0. */
	public var angularDamping:Float;

	/** Scales the gravity applied to this body. Non-dimensional. Defaults to 1. */
	public var gravityScale:Float;

	/** The speed below which the body may fall asleep, in meters per second. Defaults to 0.05 meters per second. */
	public var sleepThreshold:Float;

	/** How far the body may move in one step, as a fraction of the distance that risks tunneling, before it gets continuous collision. Non-dimensional, recommended 0.01 to 0.5. Defaults to 0.5, for high performance with low tunneling risk. */
	public var safetyFactor:Float;

	/** An optional name for debugging, up to `B2_NAME_LENGTH` characters. Defaults to null. */
	public var name:String;

	/** Any Haxe value the program keeps with the body, returned as set. Defaults to null. */
	public var userData:Dynamic;

	/** The movement the body is locked out of. A locked direction may be solved more softly. Defaults to nothing locked. */
	public var motionLocks:B2MotionLocks;

	/** Whether the body may fall asleep. Set it to false for a body that must never sleep. Defaults to true. */
	public var enableSleep:Bool;

	/** Whether the body starts awake. Defaults to true. */
	public var isAwake:Bool;

	/** Whether this dynamic body is a fast object that gets continuous collision against dynamic and kinematic bodies, but not against other bullets. Use it sparingly, as it doesn't guarantee a hit when both bodies are fast. Defaults to false. */
	public var isBullet:Bool;

	/** Whether the body is enabled. A disabled body doesn't move or collide. Defaults to true. */
	public var isEnabled:Bool;

	/** Whether the body may exceed the rotation speed limit. Use it only for round objects such as wheels. Defaults to false. */
	public var allowFastRotation:Bool;

	/** Whether the body's contacts are recycled between steps. Recycling improves performance but may cause ghost collisions, so turn it off for characters. Defaults to true. */
	public var enableContactRecycling:Bool;

	/** Creates one holding Box2D's defaults, as `b2DefaultBodyDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2BodyDef(this);
		helix.box2d.internal.Calls.b2DefaultBodyDef(this);
	}
}
