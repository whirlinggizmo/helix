package helix.box2d;

/** A 2D rigid transform, a rotation and a translation. */
class B2Transform {
	/** The translation, in length units. */
	public var p:B2Vec2;

	/** The rotation. */
	public var q:B2Rot;

	/** Creates one, as C's initializer lists its fields.

		@param p  Optional. The translation. A zero vector when omitted.
		@param q  Optional. The rotation. When omitted, the rotation that turns nothing (`b2Rot_identity`). */
	public function new(?p:B2Vec2, ?q:B2Rot) {
		helix.box2d.internal.Init.initB2Transform(this);
		if (p != null)
			this.p = p;
		if (q != null)
			this.q = q;
	}
}
