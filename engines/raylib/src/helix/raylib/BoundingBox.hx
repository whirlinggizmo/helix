package helix.raylib;

/** Represents raylib's `BoundingBox`: an axis-aligned box by its corners. */
@:structInit
class BoundingBox {
	/** Gets or sets the lowest corner. */
	public var min:Vector3;

	/** Gets or sets the highest corner. */
	public var max:Vector3;

	/** Creates a BoundingBox.

		@param min  Gets or sets the lowest corner.
		@param max  Gets or sets the highest corner. */
	public function new(?min:Vector3, ?max:Vector3) {
		this.min = min == null ? new Vector3() : min;
		this.max = max == null ? new Vector3() : max;
	}
}
