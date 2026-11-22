package helix.box2d;

/** A cosine and sine pair. Box2D computes it with its own implementation, designed to return the same result on every platform. */
class B2CosSin {
	/** The cosine. */
	public var cosine:Float;

	/** The sine. */
	public var sine:Float;

	/** Creates one, as C's initializer lists its fields.

		@param cosine  Optional. The cosine. Zero when omitted.
		@param sine  Optional. The sine. Zero when omitted. */
	public function new(cosine = 0., sine = 0.) {
		helix.box2d.internal.Init.initB2CosSin(this);
		this.cosine = cosine;
		this.sine = sine;
	}
}
