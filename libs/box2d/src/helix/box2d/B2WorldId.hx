package helix.box2d;

/** References a world. A program treats it as an opaque handle: it keeps it, passes it back to Box2D and compares ids with `B2_ID_EQUALS`, never `==`. Its fields are Box2D's own and a program doesn't read or set them. A new one is the null id until Box2D fills it. */
class B2WorldId {
	/** Box2D's index of the world plus one. Opaque to a program. */
	public var index1:Int;

	/** Box2D's reuse counter that tells apart objects sharing an index. Opaque to a program. */
	public var generation:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2WorldId(this);
	}
}
