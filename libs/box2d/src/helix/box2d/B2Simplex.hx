package helix.box2d;

/** A simplex from the GJK distance algorithm, for debugging. Box2D fills it when `b2ComputeShapeDistance` is provided an array of them. */
class B2Simplex {
	/** The first vertex. */
	public var v1:B2SimplexVertex;

	/** The second vertex. Valid when `count` is at least 2. */
	public var v2:B2SimplexVertex;

	/** The third vertex. Valid when `count` is 3. */
	public var v3:B2SimplexVertex;

	/** The number of valid vertices, 1 to 3. */
	public var count:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
