package helix.raylib;

/** Represents raylib's `Vector4`, also its `Quaternion`: four components.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
@:structInit
class Vector4 {
	/** Gets or sets the x component. */
	public var x:Float;

	/** Gets or sets the y component. */
	public var y:Float;

	/** Gets or sets the z component. */
	public var z:Float;

	/** Gets or sets the w component. */
	public var w:Float;

	/** Creates a vector.

		@param x  Gets or sets the x component.
		@param y  Gets or sets the y component.
		@param z  Gets or sets the z component.
		@param w  Gets or sets the w component. */
	public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
		this.w = w;
	}

	/** Returns a separate copy.

		@param out  Optional. The Vector4 to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:Vector4):Vector4 {
		if (out == null)
			return new Vector4(x, y, z, w);
		out.x = x;
		out.y = y;
		out.z = z;
		out.w = w;
		return out;
	}
}
