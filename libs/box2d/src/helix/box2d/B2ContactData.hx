package helix.box2d;

/** The data of a contact between two shapes. By convention the manifold normal points from shape A to shape B. Box2D fills it, as `b2Shape_GetContactData` and `b2Body_GetContactData` return it. */
class B2ContactData {
	/** The id of the contact. The program may keep it to follow a contact across steps, but it can become orphaned, so check it with `b2Contact_IsValid` before use. */
	public var contactId:B2ContactId;

	/** The id of the first shape. */
	public var shapeIdA:B2ShapeId;

	/** The id of the second shape. */
	public var shapeIdB:B2ShapeId;

	/** A copy of the contact's manifold. */
	public var manifold:B2Manifold;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
