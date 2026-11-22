package helix.box2d;

/** A solid capsule can be viewed as two semicircles connected by a rectangle. */
class B2Capsule {
	/** Local center of the first semicircle. */
	public var center1:B2Vec2;

	/** Local center of the second semicircle. */
	public var center2:B2Vec2;

	/** The radius of the semicircles. */
	public var radius:Float;

	/** Creates one, as C's initializer lists its fields.

		@param center1  Optional. Local center of the first semicircle.
		@param center2  Optional. Local center of the second semicircle.
		@param radius  Optional. The radius of the semicircles. */
	public function new(?center1:B2Vec2, ?center2:B2Vec2, radius = 0.) {
		throw "not built yet";
	}
}
