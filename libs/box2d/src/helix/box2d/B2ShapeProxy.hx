package helix.box2d;

/** A convex cloud of points, with a radius, that stands for a shape in the distance, cast and time of impact functions. */
class B2ShapeProxy {
	/** The points, from index 0 up to `count`. */
	public var points:Array<B2Vec2>;

	/** The number of points. Must be greater than 0. */
	public var count:Int;

	/** The radius around the points, in length units. May be 0. */
	public var radius:Float;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2ShapeProxy(this);
	}
}
