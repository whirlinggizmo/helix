package helix.raylib;

/** Represents raylib's `Ray`: an origin and a direction. */
@:structInit
class Ray {
	/** Gets or sets the origin. */
	public var position:Vector3;

	/** Gets or sets the direction, of length 1. */
	public var direction:Vector3;

	/** Creates a Ray.

		@param position  Gets or sets the origin.
		@param direction  Gets or sets the direction, of length 1. */
	public function new(?position:Vector3, ?direction:Vector3) {
		this.position = position == null ? new Vector3() : position;
		this.direction = direction == null ? new Vector3() : direction;
	}
}
