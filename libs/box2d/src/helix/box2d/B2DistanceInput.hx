package helix.box2d;

/** The input of `b2ComputeShapeDistance`. */
class B2DistanceInput {
	/** The proxy for shape A. */
	public var proxyA:B2ShapeProxy;

	/** The proxy for shape B. */
	public var proxyB:B2ShapeProxy;

	/** The pose of shape B in the frame of shape A. */
	public var transform:B2Transform;

	/** Whether the radii of the proxies count in the distance. */
	public var useRadii:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
