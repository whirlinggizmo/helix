package helix.raylib;

/** Represents raylib's `Vector3`: a point or a direction in three dimensions.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
@:structInit
class Vector3 {
	/** Gets or sets the x component. */
	public var x:Float;

	/** Gets or sets the y component. */
	public var y:Float;

	/** Gets or sets the z component. */
	public var z:Float;

	/** Creates a vector.

		@param x  Gets or sets the x component.
		@param y  Gets or sets the y component.
		@param z  Gets or sets the z component. */
	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/** Returns a separate copy.

		@param out  Optional. The Vector3 to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:Vector3):Vector3 {
		if (out == null)
			return new Vector3(x, y, z);
		out.x = x;
		out.y = y;
		out.z = z;
		return out;
	}
}
