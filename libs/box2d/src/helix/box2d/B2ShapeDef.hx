package helix.box2d;

/** Everything needed to create a shape on a body, such as with `b2CreateCircleShape`. The definition can be reused for more shapes. */
class B2ShapeDef {
	/** Any Haxe value the program keeps with the shape, returned as set. Defaults to null. */
	public var userData:Dynamic;

	/** The surface material of the shape. Defaults to a friction of 0.6 and zero for the rest. */
	public var material:B2SurfaceMaterial;

	/** The density of the shape's interior, usually in kilograms per square meter. Defaults to 1. */
	public var density:Float;

	/** Which shapes this shape collides with, and which queries find it. Defaults to category 1, colliding with all categories, in group 0. */
	public var filter:B2Filter;

	/** Whether the world's custom filter callback is asked about contacts of this shape. One of the two shapes involved needs it. See `b2World_SetCustomFilterCallback`. Defaults to false. */
	public var enableCustomFiltering:Bool;

	/** Whether the shape is a sensor. A sensor reports overlaps and never causes a collision response. A fast sensor may miss overlaps, so use a ray or shape cast for those. A sensor with density still adds to the body's mass. Defaults to false.

		_Note that a sensor reports events only when `enableSensorEvents` is true on it and on the shape it overlaps._ */
	public var isSensor:Bool;

	/** Whether sensor events are reported for this shape, whether it is a sensor or not. Both shapes involved need it. Defaults to false, even for sensors. */
	public var enableSensorEvents:Bool;

	/** Whether begin and end touch events are reported for this shape. Only applies to kinematic and dynamic bodies, and is ignored for sensors. One of the two shapes involved needs it. Defaults to false. */
	public var enableContactEvents:Bool;

	/** Whether hit events are reported for this shape. Only applies to kinematic and dynamic bodies, and is ignored for sensors. One of the two shapes involved needs it. Defaults to false. */
	public var enableHitEvents:Bool;

	/** Whether the world's pre-solve callback is called for contacts of this shape. Only applies to dynamic bodies, and is ignored for sensors. It is expensive. Defaults to false. */
	public var enablePreSolveEvents:Bool;

	/** Whether the new shape looks for collisions at the next step. Setting it to false speeds up creating many static shapes. Ignored for dynamic and kinematic shapes, which always look. Defaults to true. */
	public var invokeContactCreation:Bool;

	/** Whether the body's mass is recomputed when the shape is created. When false, call `b2Body_UpdateMassFromShapes` or `b2Body_SetMassData` before stepping the world. Defaults to true. */
	public var updateBodyMass:Bool;

	/** Creates one holding Box2D's defaults, as `b2DefaultShapeDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2ShapeDef(this);
		helix.box2d.internal.Calls.b2DefaultShapeDef(this);
	}
}
