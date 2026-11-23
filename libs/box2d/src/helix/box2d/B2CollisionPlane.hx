package helix.box2d;

/** A collision plane for `b2SolvePlanes` and `b2ClipVector`. A program usually makes one from each hit `B2PlaneResult` of `b2World_CollideMover`. */
class B2CollisionPlane {
	/** The collision plane between the mover and a shape, relative to the mover's position. */
	public var plane:B2Plane;

	/** How far the plane can push the mover, usually in meters. A huge value, such as C's `FLT_MAX` (3.4028234663852886e38), makes the plane as rigid as possible. Lower values make the collision soft. */
	public var pushLimit:Float;

	/** How far the plane pushed the mover, usually in meters. `b2SolvePlanes` sets it. */
	public var push:Float;

	/** Whether `b2ClipVector` clips against this plane. False for a soft collision. */
	public var clipVelocity:Bool;

	/** Creates one, as C's initializer lists its fields.

		@param plane  Optional. The plane. A plane with a zero normal and offset when omitted.
		@param pushLimit  Optional. The most the plane can push. Zero when omitted.
		@param push  Optional. The push. Zero when omitted.
		@param clipVelocity  Optional. Whether `b2ClipVector` clips against the plane. False when omitted. */
	public function new(?plane:B2Plane, pushLimit = 0., push = 0., clipVelocity = false) {
		helix.box2d.internal.Init.initB2CollisionPlane(this);
		if (plane != null)
			this.plane = plane;
		this.pushLimit = pushLimit;
		this.push = push;
		this.clipVelocity = clipVelocity;
	}
}
