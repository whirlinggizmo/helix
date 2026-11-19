package helix.raylib;

/** Represents raylib's `Ray`: an origin and a direction.

	_Note that a `Ray` is assigned by reference. `copy()` copies into `out` when provided, otherwise into a new `Ray`._ */
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

	/** Returns a separate copy. Its position and direction are copied too.

		@param out  Optional. The Ray to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when provided. */
	public function copy(?out:Ray):Ray {
		if (out == null)
			return new Ray(position.copy(), direction.copy());
		position.copy(out.position);
		direction.copy(out.direction);
		return out;
	}
}
