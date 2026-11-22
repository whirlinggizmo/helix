package helix.box2d;

/** A convex hull of points, made by `b2ComputeHull`. */
class B2Hull {
	/** The points of the hull, from index 0 up to `count`. */
	public var points:Array<B2Vec2>;

	/** The number of points. */
	public var count:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
