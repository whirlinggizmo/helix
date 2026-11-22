package helix.box2d;

/** Low level ray cast input data. */
class B2RayCastInput {
	/** Start point of the ray cast. */
	public var origin:B2Vec2;

	/** Translation of the ray cast. */
	public var translation:B2Vec2;

	/** The maximum fraction of the translation to consider, typically 1. */
	public var maxFraction:Float;

	/** Creates one, as C's initializer lists its fields.

		@param origin  Optional. Start point of the ray cast.
		@param translation  Optional. Translation of the ray cast.
		@param maxFraction  Optional. The maximum fraction of the translation to consider, typically 1. */
	public function new(?origin:B2Vec2, ?translation:B2Vec2, maxFraction = 0.) {
		helix.box2d.internal.Init.initB2RayCastInput(this);
		if (origin != null)
			this.origin = origin;
		if (translation != null)
			this.translation = translation;
		this.maxFraction = maxFraction;
	}
}
