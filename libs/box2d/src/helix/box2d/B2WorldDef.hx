package helix.box2d;

/** Everything needed to create a world with `b2CreateWorld`. */
class B2WorldDef {
	/** The gravity, in meters per second squared. Box2D has no up direction. Defaults to (0, -10). */
	public var gravity:B2Vec2;

	/** The approach speed, in meters per second, above which collisions bounce. Defaults to 1 meter per second. */
	public var restitutionThreshold:Float;

	/** The number of iterations of the restitution solver. More iterations can mean less box spinning. Defaults to 2. */
	public var restitutionIterations:Int;

	/** Whether the restitution solver propagates through whole contact chains. Experimental and expensive. Defaults to false. */
	public var enableRestitutionPropagation:Bool;

	/** The approach speed, in meters per second, above which a hit event is reported. Defaults to 1 meter per second. */
	public var hitEventThreshold:Float;

	/** The contact stiffness, in cycles per second. Raising it recovers from overlap faster but may add jitter. Defaults to 30. */
	public var contactHertz:Float;

	/** The contact damping ratio, non-dimensional. Lowering it recovers from overlap faster, with a more energetic result. Defaults to 10. */
	public var contactDampingRatio:Float;

	/** The most speed, in meters per second, at which overlap is resolved. It caps the recovery speed only, which the hertz and damping ratio also set. Defaults to 3 meters per second. */
	public var contactSpeed:Float;

	/** The most speed a body may have, in meters per second. Defaults to 400 meters per second. */
	public var maximumLinearSpeed:Float;

	/** An optional function that mixes the friction of two touching shapes. Defaults to null, which mixes as the square root of the two coefficients multiplied. */
	public var frictionCallback:B2FrictionCallbackFcn;

	/** An optional function that mixes the restitution of two touching shapes. Defaults to null, which mixes as the larger of the two coefficients. */
	public var restitutionCallback:B2RestitutionCallbackFcn;

	/** Whether bodies may fall asleep, which improves performance. Defaults to true. */
	public var enableSleep:Bool;

	/** Whether continuous collision is used to stop fast bodies from tunneling. Defaults to true. */
	public var enableContinuous:Bool;

	/** The number of workers for multithreading. Natively, a count above 1 runs Box2D's own threads, and 0 or 1 runs one thread. The count is limited to Box2D's maximum number of workers. Defaults to 0.

		_Note that in a page the module runs one worker, whatever the count._ */
	public var workerCount:Int;

	/** Any Haxe value the program keeps with the world, returned as set. Defaults to null. */
	public var userData:Dynamic;

	/** Expected counts that let Box2D reserve memory when the world is created. Defaults to zero for all of them, reserving nothing. */
	public var capacity:B2Capacity;

	/** Creates one holding Box2D's defaults, as `b2DefaultWorldDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2WorldDef(this);
		helix.box2d.internal.Calls.b2DefaultWorldDef(this);
	}
}
