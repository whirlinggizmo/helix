package helix.box2d;

/** The output of a time of impact computation. Box2D fills it. */
class B2TOIOutput {
	/** The type of result. */
	public var state:B2TOIState;

	/** The hit point. */
	public var point:B2Vec2;

	/** The hit normal. */
	public var normal:B2Vec2;

	/** The sweep time of the collision. */
	public var fraction:Float;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
