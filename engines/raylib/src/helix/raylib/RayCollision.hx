package helix.raylib;

/** Represents raylib's `RayCollision`: whether and where a ray hit. */
@:structInit
class RayCollision {
	/** Gets or sets whether it hit. */
	public var hit:Bool;

	/** Gets or sets the distance to the hit. */
	public var distance:Float;

	/** Gets or sets the point hit. */
	public var point:Vector3;

	/** Gets or sets the surface's normal there. */
	public var normal:Vector3;

	/** Creates a RayCollision.

		@param hit  Gets or sets whether it hit.
		@param distance  Gets or sets the distance to the hit.
		@param point  Gets or sets the point hit.
		@param normal  Gets or sets the surface's normal there. */
	public function new(hit:Bool = false, distance:Float = 0, ?point:Vector3, ?normal:Vector3) {
		this.hit = hit;
		this.distance = distance;
		this.point = point == null ? new Vector3() : point;
		this.normal = normal == null ? new Vector3() : normal;
	}
}
