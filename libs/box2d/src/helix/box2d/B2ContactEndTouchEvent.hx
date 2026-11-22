package helix.box2d;

/** Reports that two shapes stopped touching. It is also reported when something destroys a contact made before the last step, such as setting a body's transform, destroying a body or shape, or changing a filter or a body type. */
class B2ContactEndTouchEvent {
	/** The id of the first shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`. */
	public var shapeIdA:B2ShapeId;

	/** The id of the second shape. The shape may have been destroyed, so check it with `b2Shape_IsValid`. */
	public var shapeIdB:B2ShapeId;

	/** The id of the contact. The contact may have been destroyed, so check it with `b2Contact_IsValid`. */
	public var contactId:B2ContactId;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
