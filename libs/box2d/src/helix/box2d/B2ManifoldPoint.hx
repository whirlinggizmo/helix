package helix.box2d;

/** One contact point of a manifold. Box2D fills it. */
class B2ManifoldPoint {
	/** The contact point relative to body A's center of mass, in world orientation. Add it to `b2Body_GetWorldCenter` of body A to get the world point. */
	public var anchorA:B2Vec2;

	/** The contact point relative to body B's center of mass, in world orientation. */
	public var anchorB:B2Vec2;

	/** The separation of the contact point, in length units. Negative when the shapes penetrate. */
	public var separation:Float;

	/** The impulse along the manifold normal. */
	public var normalImpulse:Float;

	/** The friction impulse. */
	public var tangentImpulse:Float;

	/** The whole normal impulse applied across sub-steps and restitution. A positive value marks a speculative point that was involved in the step. */
	public var totalNormalImpulse:Float;

	/** The relative velocity along the normal before the solve. Negative when the shapes approach. It is reliable only when hit events are enabled. */
	public var normalVelocity:Float;

	/** The separation Box2D keeps to recycle the contact, in length units. */
	public var baseSeparation:Float;

	/** Identifies the contact point between the two shapes. */
	public var id:Int;

	/** Whether the contact point existed in the previous step. */
	public var persisted:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
