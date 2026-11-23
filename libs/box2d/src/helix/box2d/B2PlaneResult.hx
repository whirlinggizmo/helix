package helix.box2d;

/** A collision plane `b2World_CollideMover` finds between the mover and a shape. Box2D fills it. The plane and the point are relative to the query's origin, as the mover capsule is. */
class B2PlaneResult {
	/** The collision plane between the mover and a convex shape. */
	public var plane:B2Plane;

	/** The collision point on the shape. */
	public var point:B2Vec2;

	/** Whether the collision registered a hit. When false, the plane is to be ignored. */
	public var hit:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		helix.box2d.internal.Init.initB2PlaneResult(this);
	}
}
