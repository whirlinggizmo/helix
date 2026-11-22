package helix.box2d;

/** This holds the mass data computed for a shape. */
class B2MassData {
	/** The mass of the shape, usually in kilograms. */
	public var mass:Float;

	/** The position of the shape's centroid relative to the shape's origin. */
	public var center:B2Vec2;

	/** The rotational inertia of the shape about the shape center. */
	public var rotationalInertia:Float;

	/** Creates one, as C's initializer lists its fields.

		@param mass  Optional. The mass of the shape, usually in kilograms.
		@param center  Optional. The position of the shape's centroid relative to the shape's origin.
		@param rotationalInertia  Optional. The rotational inertia of the shape about the shape center. */
	public function new(mass = 0., ?center:B2Vec2, rotationalInertia = 0.) {
		helix.box2d.internal.Init.initB2MassData(this);
		this.mass = mass;
		if (center != null)
			this.center = center;
		this.rotationalInertia = rotationalInertia;
	}
}
