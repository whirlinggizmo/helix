package helix.box2d;

/** Reports that two shapes began touching. */
class B2ContactBeginTouchEvent {
	/** The id of the first shape. */
	public var shapeIdA:B2ShapeId;

	/** The id of the second shape. */
	public var shapeIdB:B2ShapeId;

	/** The id of the contact. It is transient, as Box2D may destroy the contact when the world is modified or stepped. Check it with `b2Contact_IsValid` before use. */
	public var contactId:B2ContactId;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2ContactBeginTouchEvent(this);
	}
}
