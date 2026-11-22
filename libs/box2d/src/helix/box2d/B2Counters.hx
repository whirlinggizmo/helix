package helix.box2d;

/** Counts that describe the size of a simulation. `b2World_GetCounters` returns one that Box2D fills. */
class B2Counters {
	/** Bytes of memory Box2D has allocated. */
	public var byteCount:Int;

	/** The number of bodies. */
	public var bodyCount:Int;

	/** The number of shapes. */
	public var shapeCount:Int;

	/** The number of contacts. */
	public var contactCount:Int;

	/** The number of joints. */
	public var jointCount:Int;

	/** The number of simulation islands. */
	public var islandCount:Int;

	/** Bytes of Box2D's stack allocator in use. */
	public var stackUsed:Int;

	/** The height of the static bodies' broad-phase tree. */
	public var staticTreeHeight:Int;

	/** The height of the moving bodies' broad-phase trees, the tallest of them. */
	public var treeHeight:Int;

	/** The number of tasks Box2D ran in the last step. */
	public var taskCount:Int;

	/** The number of constraints in each of the 24 graph colors, the solver's groups of constraints that can be solved together. An array of 24 integers. */
	public var colorCounts:Array<Int>;

	/** Number of contacts touched by the collide pass (graph contacts + awake-set non-touching). */
	public var awakeContactCount:Int;

	/** Number of contacts recycled in the most recent step. */
	public var recycledContactCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
