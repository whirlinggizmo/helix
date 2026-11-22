package helix.jolt;

/** Represents what a body is made from: its shape, where it starts and how it moves. Read once by `BodyInterface.CreateBody`, and may
	be changed and read again for another body.

	```haxe
	var settings = new BodyCreationSettings(new BoxShape(new Vec3(0.5, 0.5, 0.5)), new RVec3(0, 10, 0), Quat.sIdentity(),
		EMotionType_Dynamic, LAYER_MOVING);
	settings.mRestitution = 0.5;
	var id = bodyInterface.CreateAndAddBody(settings, EActivation_Activate);
	```

	The defaults are Jolt's. */
class BodyCreationSettings {
	/** Gets or sets the starting position, in meters. */
	public var mPosition:RVec3;

	/** Gets or sets the starting rotation. */
	public var mRotation:Quat;

	/** Gets or sets the starting velocity, in meters a second. */
	public var mLinearVelocity:Vec3;

	/** Gets or sets the starting angular velocity, in radians a second about each axis. */
	public var mAngularVelocity:Vec3;

	/** Gets or sets a number the program keeps with the body, such as an index into its own list. Defaults to 0. */
	public var mUserData:Int = 0;

	/** Gets or sets the body's object layer. */
	public var mObjectLayer:Int = 0;

	/** Gets or sets how the body moves. Defaults to `EMotionType_Dynamic`. */
	public var mMotionType:EMotionType = EMotionType_Dynamic;

	/** Gets or sets the directions the body may move and turn in. Defaults to `EAllowedDOFs_All`. */
	public var mAllowedDOFs:EAllowedDOFs = EAllowedDOFs_All;

	/** Gets or sets a value indicating whether a static body may later become kinematic or dynamic. Defaults to false. */
	public var mAllowDynamicOrKinematic:Bool = false;

	/** Gets or sets a value indicating whether the body is a sensor: it collides with nothing, and its contacts are reported. Defaults
		to false.

		A static sensor detects the awake dynamic and kinematic bodies in layers its own layer collides with. A body falling asleep
		inside a static sensor is reported as leaving it. A kinematic sensor detects sleeping bodies too. */
	public var mIsSensor:Bool = false;

	/** Gets or sets how the body's motion is tested for collisions. Defaults to `EMotionQuality_Discrete`. */
	public var mMotionQuality:EMotionQuality = EMotionQuality_Discrete;

	/** Gets or sets a value indicating whether the body may sleep. Defaults to true. */
	public var mAllowSleeping:Bool = true;

	/** Gets or sets the friction, 0 or more: 0 ice, 1 rubber. Defaults to 0.2. */
	public var mFriction:Float = 0.2;

	/** Gets or sets the bounce, 0 to 1. Defaults to 0. */
	public var mRestitution:Float = 0;

	/** Gets or sets the share of the velocity lost each second, 0 to 1. Defaults to 0.05. */
	public var mLinearDamping:Float = 0.05;

	/** Gets or sets the share of the angular velocity lost each second, 0 to 1. Defaults to 0.05. */
	public var mAngularDamping:Float = 0.05;

	/** Gets or sets the fastest the body moves, in meters a second. Defaults to 500. */
	public var mMaxLinearVelocity:Float = 500;

	/** Gets or sets the fastest the body turns, in radians a second. Defaults to 0.25 pi times 60. */
	public var mMaxAngularVelocity:Float = 0.25 * Math.PI * 60;

	/** Gets or sets how much of the gravity the body falls by. Defaults to 1. */
	public var mGravityFactor:Float = 1;

	/** Gets or sets how the mass and inertia are found. Defaults to `EOverrideMassProperties_CalculateMassAndInertia`. */
	public var mOverrideMassProperties:EOverrideMassProperties = EOverrideMassProperties_CalculateMassAndInertia;

	/** Gets or sets the mass and inertia used as `mOverrideMassProperties` says. */
	public var mMassPropertiesOverride:MassProperties;

	/** Creates settings for a body.

		@param inShape  Optional. The shape; when omitted, set with `SetShape` before the body is made.
		@param inPosition  Optional. The starting position; defaults to (0, 0, 0).
		@param inRotation  Optional. The starting rotation; defaults to the identity.
		@param inMotionType  Optional. How the body moves; defaults to `EMotionType_Dynamic`.
		@param inObjectLayer  Optional. The object layer; defaults to 0. */
	public function new(?inShape:Shape, ?inPosition:RVec3, ?inRotation:Quat, inMotionType:EMotionType = EMotionType_Dynamic, inObjectLayer = 0) {
		throw "not built yet";
	}

	/** Returns the shape.

		@return  The shape, or null if there is none. */
	public function GetShape():Null<Shape> {
		throw "not built yet";
	}

	/** Sets the shape.

		@param inShape  The shape. */
	public function SetShape(inShape:Shape):Void {
		throw "not built yet";
	}
}
