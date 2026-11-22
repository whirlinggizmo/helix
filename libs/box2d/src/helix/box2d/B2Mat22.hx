package helix.box2d;

/** A 2-by-2 matrix stored as two column vectors. */
class B2Mat22 {
	/** The first column. */
	public var cx:B2Vec2;

	/** The second column. */
	public var cy:B2Vec2;

	/** Creates one, as C's initializer lists its fields.

		@param cx  Optional. The first column. A zero vector when omitted.
		@param cy  Optional. The second column. A zero vector when omitted. */
	public function new(?cx:B2Vec2, ?cy:B2Vec2) {
		throw "not built yet";
	}
}
