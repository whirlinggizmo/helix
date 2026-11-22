package helix.box2d;

/** Describes the contact points between two shapes in local coordinates, the frame of shape A. Box2D fills it. */
class B2LocalManifold {
	/** The unit normal in frame A, pointing from shape A to shape B. */
	public var normal:B2Vec2;

	/** The manifold points, from index 0 up to `pointCount`. A manifold in 2D has at most two. */
	public var points:Array<B2LocalManifoldPoint>;

	/** The number of manifold points: 0, 1 or 2. */
	public var pointCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
