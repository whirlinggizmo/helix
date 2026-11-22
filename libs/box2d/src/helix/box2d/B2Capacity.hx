package helix.box2d;

/** Expected counts that let a world reserve memory when it is created and avoid allocating while it runs. Every field defaults to 0, which reserves nothing. */
class B2Capacity {
	/** The expected number of static shapes. */
	public var staticShapeCount:Int;

	/** The expected number of dynamic and kinematic shapes. */
	public var dynamicShapeCount:Int;

	/** The expected number of static bodies. */
	public var staticBodyCount:Int;

	/** The expected number of dynamic and kinematic bodies. */
	public var dynamicBodyCount:Int;

	/** The expected number of contacts. */
	public var contactCount:Int;

	/** The bytes to reserve for temporary allocations. */
	public var arenaByteCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2Capacity(this);
	}
}
