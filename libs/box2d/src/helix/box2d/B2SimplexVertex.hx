package helix.box2d;

/** A vertex of the simplex of the GJK distance algorithm, for debugging. Box2D fills it. */
class B2SimplexVertex {
	/** The support point in proxy A. */
	public var wA:B2Vec2;

	/** The support point in proxy B. */
	public var wB:B2Vec2;

	/** The difference `wB - wA`. */
	public var w:B2Vec2;

	/** The barycentric coordinate of the closest point. */
	public var a:Float;

	/** The index of `wA` in proxy A's points. */
	public var indexA:Int;

	/** The index of `wB` in proxy B's points. */
	public var indexB:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
