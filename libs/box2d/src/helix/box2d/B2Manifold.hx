package helix.box2d;

/** Describes the contact points between two colliding shapes. Box2D uses speculative collision, so some points may be separated. Box2D fills it. */
class B2Manifold {
	/** The unit normal in the world, pointing from shape A to shape B. */
	public var normal:B2Vec2;

	/** The angular impulse applied for rolling resistance, in newton-meter-seconds. */
	public var rollingImpulse:Float;

	/** The manifold points, from index 0 up to `pointCount`. A manifold in 2D has at most two. */
	public var points:Array<B2ManifoldPoint>;

	/** The number of manifold points: 0, 1 or 2. */
	public var pointCount:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2Manifold(this);
	}
}
