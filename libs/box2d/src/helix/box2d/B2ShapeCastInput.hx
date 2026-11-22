package helix.box2d;

/** The input of a shape cast against one shape, in a general form. */
class B2ShapeCastInput {
	/** The shape to cast. */
	public var proxy:B2ShapeProxy;

	/** The translation of the cast. */
	public var translation:B2Vec2;

	/** The largest fraction of the translation to consider, typically 1. */
	public var maxFraction:Float;

	/** Whether a shape with a radius may move slightly closer when it already touches. */
	public var canEncroach:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2ShapeCastInput(this);
	}
}
