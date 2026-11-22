package helix.box2d;

/** Everything needed to create a chain of line segments with `b2CreateChain`. A chain is one-sided, with no mass, so use it on static bodies. It has a counter-clockwise winding, where the normal points right of the segment direction. It collides on one side, its front, which is to the right looking from each point to the next: points listed from right to left make ground whose top is up. It's either a loop or open, and an open chain needs a ghost point at each end, as `b2CreateChain` refuses an open chain whose ghost points are left at their defaults. The distance between two points must exceed `B2_LINEAR_SLOP`, and the chain must not intersect itself. Use chains only when you understand these limits. */
class B2ChainDef {
	/** Any Haxe value the program keeps with the chain, returned as set. Defaults to null. */
	public var userData:Dynamic;

	/** The chain's points, read from index 0 up to `pointCount`. Each consecutive pair is a segment, and for a loop the last and first point are a segment too. Box2D copies them. Defaults to none. */
	public var points:Array<B2Vec2>;

	/** The number of points to use. At least 2 for an open chain and at least 3 for a loop. Defaults to 0. */
	public var pointCount:Int;

	/** The leading ghost point of an open chain. Its distance from the first point must exceed `B2_LINEAR_SLOP`. Ignored for a loop. Defaults to a point at infinity, which is not valid until it's set. */
	public var ghost1:B2Vec2;

	/** The trailing ghost point of an open chain. Its distance from the last point must exceed `B2_LINEAR_SLOP`. Ignored for a loop. Defaults to a point at infinity, which is not valid until it's set. */
	public var ghost2:B2Vec2;

	/** One material for the whole chain, or one for each segment, read from index 0 up to `materialCount`. Box2D copies them. Defaults to one material with a friction of 0.6. */
	public var materials:Array<B2SurfaceMaterial>;

	/** The number of materials to use. Must be 1 or the segment count, which is `pointCount` for a loop and one less for an open chain. Defaults to 1. */
	public var materialCount:Int;

	/** Which shapes the chain collides with, and which queries find it. Defaults to category 1, colliding with all categories, in group 0. */
	public var filter:B2Filter;

	/** Whether the chain is closed by joining the last point to the first. Defaults to false. */
	public var isLoop:Bool;

	/** Whether sensors detect the chain. Defaults to false. */
	public var enableSensorEvents:Bool;

	/** Creates one holding Box2D's defaults, as `b2DefaultChainDef()` returns. The structs it holds are made with it. */
	public function new() {
		helix.box2d.internal.Init.initB2ChainDef(this);
		helix.box2d.internal.Calls.b2DefaultChainDef(this);
	}
}
