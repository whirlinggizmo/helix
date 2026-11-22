package helix.box2d;

/** A solid circle. */
class B2Circle {
	/** The local center. */
	public var center:B2Vec2;

	/** The radius. */
	public var radius:Float;

	/** Creates one, as C's initializer lists its fields.

		@param center  Optional. The local center.
		@param radius  Optional. The radius. */
	public function new(?center:B2Vec2, radius = 0.) {
		helix.box2d.internal.Init.initB2Circle(this);
		if (center != null)
			this.center = center;
		this.radius = radius;
	}
}
