package helix.raylib;

/** Represents raylib's `BoundingBox`: an axis-aligned box by its corners.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
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

	/** Returns a separate copy. Its corners are copied too.

		@param out  Optional. The BoundingBox to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:BoundingBox):BoundingBox {
		if (out == null)
			return new BoundingBox(min.copy(), max.copy());
		min.copy(out.min);
		max.copy(out.max);
		return out;
	}
}
