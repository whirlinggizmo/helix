package helix.box2d;

/** Reports two shapes that collided faster than the world's hit event threshold. It may be reported for a speculative contact that has a confirmed impulse. */
class B2ContactHitEvent {
	/** The id of the first shape. */
	public var shapeIdA:B2ShapeId;

	/** The id of the second shape. */
	public var shapeIdB:B2ShapeId;

	/** The id of the contact. The contact may have been destroyed, so check it with `b2Contact_IsValid`. */
	public var contactId:B2ContactId;

	/** The point where the shapes hit, midway between the two surfaces. It may be a speculative point where the shapes weren't touching at the start of the step. It is rebuilt after the step, so when both bodies move it may trail the impact by up to one step of motion. */
	public var point:B2Pos;

	/** The unit normal, pointing from shape A to shape B. */
	public var normal:B2Vec2;

	/** The speed at which the shapes approach, always positive, usually in meters per second. */
	public var approachSpeed:Float;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
