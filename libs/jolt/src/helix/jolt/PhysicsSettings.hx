package helix.jolt;

/** Represents a `PhysicsSystem`'s solver and sleep settings. Read with `PhysicsSystem.GetPhysicsSettings`, changed, and set with
	`PhysicsSystem.SetPhysicsSettings`. The defaults are Jolt's. */
class PhysicsSettings {
	/** Gets or sets the share of the penetration removed each step, 0 to 1. Defaults to 0.2. */
	public var mBaumgarte:Float = 0.2;

	/** Gets or sets the distance at which contacts are made before shapes touch, in meters. Defaults to 0.02. */
	public var mSpeculativeContactDistance:Float = 0.02;

	/** Gets or sets the penetration allowed, in meters. Defaults to 0.02. */
	public var mPenetrationSlop:Float = 0.02;

	/** Gets or sets the share of a body's inner radius it may move in a step before a `EMotionQuality_LinearCast` body is cast.
		Defaults to 0.75. */
	public var mLinearCastThreshold:Float = 0.75;

	/** Gets or sets the velocity steps of the solver each collision step. Defaults to 10. */
	public var mNumVelocitySteps:Int = 10;

	/** Gets or sets the position steps of the solver each collision step. Defaults to 2. */
	public var mNumPositionSteps:Int = 2;

	/** Gets or sets the slowest closing speed that bounces, in meters a second. Defaults to 1. */
	public var mMinVelocityForRestitution:Float = 1;

	/** Gets or sets the seconds a body must be still before it sleeps. Defaults to 0.5. */
	public var mTimeBeforeSleep:Float = 0.5;

	/** Gets or sets the speed below which a body's points count as still, in meters a second. Defaults to 0.03. */
	public var mPointVelocitySleepThreshold:Float = 0.03;

	/** Gets or sets a value indicating whether bodies may sleep. Defaults to true. */
	public var mAllowSleeping:Bool = true;

	/** Gets or sets a value indicating whether a contact on a mesh's inner edge is corrected to the face's normal. Defaults to true. */
	public var mCheckActiveEdges:Bool = true;

	/** Creates settings with Jolt's defaults. */
	public function new() {}
}
