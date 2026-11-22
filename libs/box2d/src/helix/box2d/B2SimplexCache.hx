package helix.box2d;

/** Warm starts `b2ComputeShapeDistance` with the simplex of an earlier call on the same shapes. Start with `b2_emptySimplexCache`. */
class B2SimplexCache {
	/** The number of stored simplex points. */
	public var count:Int;

	/** The cached indices of the simplex points on shape A, from index 0 up to `count`. */
	public var indexA:Array<Int>;

	/** The cached indices of the simplex points on shape B, from index 0 up to `count`. */
	public var indexB:Array<Int>;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
