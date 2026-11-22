package helix.box2d;

/** A 2D rotation stored as its cosine and sine, like a unit complex number. Make one from an angle with `b2MakeRot`. */
class B2Rot {
	/** The cosine of the angle. */
	public var c:Float;

	/** The sine of the angle. */
	public var s:Float;

	/** Creates one, as C's initializer lists its fields.

		@param c  Optional. The cosine; 1 when omitted.
		@param s  Optional. The sine; 0 when omitted. Both omitted, the rotation turns nothing. */
	public function new(c = 1., s = 0.) {
		helix.box2d.internal.Init.initB2Rot(this);
		this.c = c;
		this.s = s;
	}
}
