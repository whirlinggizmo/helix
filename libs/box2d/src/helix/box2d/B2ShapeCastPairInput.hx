package helix.box2d;

/** The input of `b2CastShape`, which casts one shape against another. */
class B2ShapeCastPairInput {
	/** The proxy for shape A. */
	public var proxyA:B2ShapeProxy;

	/** The proxy for shape B. */
	public var proxyB:B2ShapeProxy;

	/** The pose of shape B in the frame of shape A. */
	public var transform:B2Transform;

	/** The translation of shape B, in the frame of shape A. */
	public var translationB:B2Vec2;

	/** The largest fraction of the translation to consider, typically 1. */
	public var maxFraction:Float;

	/** Whether shapes with a radius may move slightly closer when they already touch. */
	public var canEncroach:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2ShapeCastPairInput(this);
	}
}
