package helix.raylib;

/** Represents raylib's `Vector2`: a point or a direction in two dimensions.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
@:structInit
class Vector2 {
	/** Gets or sets the x component. */
	public var x:Float;

	/** Gets or sets the y component. */
	public var y:Float;

	/** Creates a vector.

		@param x  The x component.
		@param y  The y component. */
	public function new(x:Float = 0, y:Float = 0) {
		this.x = x;
		this.y = y;
	}

	/** Returns a separate copy.

		@param out  Optional. The Vector2 to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:Vector2):Vector2 {
		if (out == null)
			return new Vector2(x, y);
		out.x = x;
		out.y = y;
		return out;
	}
}
