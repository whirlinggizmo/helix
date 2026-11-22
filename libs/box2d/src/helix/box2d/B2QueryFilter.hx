package helix.box2d;

/** Decides which shapes a query finds, such as a ray cast. A projectile's ray might find players and the static environment but not debris. */
class B2QueryFilter {
	/** The categories of the query, usually one bit. Defaults to 1. */
	public var categoryBits:haxe.Int64;

	/** The shape categories the query finds. Defaults to all bits. */
	public var maskBits:haxe.Int64;

	/** Creates one holding Box2D's defaults, as `b2DefaultQueryFilter()` returns. */
	public function new() {
		throw "not built yet";
	}
}
