package helix.box2d;

/** One contact point of a local manifold, in the frame of shape A. Box2D fills it. */
class B2LocalManifoldPoint {
	/** The contact point in frame A. */
	public var point:B2Vec2;

	/** The separation of the contact point, in length units. Negative when the shapes penetrate. */
	public var separation:Float;

	/** Identifies the contact point between the two shapes. */
	public var id:Int;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2LocalManifoldPoint(this);
	}
}
