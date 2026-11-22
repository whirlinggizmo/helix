package helix.box2d;

/** The result of `b2World_CastRayClosest`. Box2D fills it. If the ray starts overlapping a shape, the fraction and normal are zero and the point is an arbitrary point in the overlap. */
class B2RayResult {
	/** The shape hit. */
	public var shapeId:B2ShapeId;

	/** The point of contact, on the surface of the hit shape. */
	public var point:B2Pos;

	/** The unit normal vector at the point of contact. */
	public var normal:B2Vec2;

	/** The fraction of the input ray. */
	public var fraction:Float;

	/** The number of BVH nodes visited. Diagnostic. */
	public var nodeVisits:Int;

	/** The number of BVH leaves visited. Diagnostic. */
	public var leafVisits:Int;

	/** Did the ray hit? If false, all other data is invalid. */
	public var hit:Bool;

	/** Creates one, its fields zero. */
	public function new() {
		throw "not built yet";
	}
}
