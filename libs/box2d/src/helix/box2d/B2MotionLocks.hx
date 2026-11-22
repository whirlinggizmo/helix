package helix.box2d;

/** Motion locks to restrict the body movement. */
class B2MotionLocks {
	/** Prevent translation along the x-axis. */
	public var linearX:Bool;

	/** Prevent translation along the y-axis. */
	public var linearY:Bool;

	/** Prevent rotation around the z-axis. */
	public var angularZ:Bool;

	/** Creates one, as C's initializer lists its fields.

		@param linearX  Optional. Prevent translation along the x-axis.
		@param linearY  Optional. Prevent translation along the y-axis.
		@param angularZ  Optional. Prevent rotation around the z-axis. */
	public function new(linearX = false, linearY = false, angularZ = false) {
		throw "not built yet";
	}
}
