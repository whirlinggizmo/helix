package helix.box2d;

/** The output of a low level ray cast or shape cast. Box2D fills it. */
class B2CastOutput {
	/** The surface normal at the hit point. */
	public var normal:B2Vec2;

	/** The surface hit point. */
	public var point:B2Vec2;

	/** The fraction of the input translation at collision. */
	public var fraction:Float;

	/** The number of iterations used. */
	public var iterations:Int;

	/** Did the cast hit? */
	public var hit:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2CastOutput(this);
	}
}
