package helix.box2d;

/** A solid convex polygon with at most `B2_MAX_POLYGON_VERTICES` vertices, optionally rounded by a radius. */
class B2Polygon {
	/** The vertices, from index 0 up to `count`. */
	public var vertices:Array<B2Vec2>;

	/** The outward unit normals of the sides, from index 0 up to `count`. Side `i` runs from vertex `i` to the next. */
	public var normals:Array<B2Vec2>;

	/** The centroid of the polygon. */
	public var centroid:B2Vec2;

	/** The radius that rounds the corners, in length units. 0 for sharp corners. */
	public var radius:Float;

	/** The number of vertices. */
	public var count:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2Polygon(this);
	}
}
