package helix.box2d;

/** A plane in 2D, the set of points where `dot(normal, point) - offset` is zero. That value is a point's signed separation from the plane. */
class B2Plane {
	/** The unit normal of the plane. */
	public var normal:B2Vec2;

	/** The plane's offset from the origin along the normal, in length units. */
	public var offset:Float;

	/** Creates one, as C's initializer lists its fields.

		@param normal  Optional. The unit normal. A zero vector when omitted.
		@param offset  Optional. The offset. Zero when omitted. */
	public function new(?normal:B2Vec2, offset = 0.) {
		helix.box2d.internal.Init.initB2Plane(this);
		if (normal != null)
			this.normal = normal;
		this.offset = offset;
	}
}
