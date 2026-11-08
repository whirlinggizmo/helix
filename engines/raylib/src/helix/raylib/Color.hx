package helix.raylib;

/** Represents raylib's `Color`: red, green, blue and alpha, each 0 to 255.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
@:structInit
class Color {
	/** Gets or sets the red, 0 to 255. */
	public var r:Int;

	/** Gets or sets the green, 0 to 255. */
	public var g:Int;

	/** Gets or sets the blue, 0 to 255. */
	public var b:Int;

	/** Gets or sets the alpha, 0 (clear) to 255 (opaque). */
	public var a:Int;

	/** Creates a color.

		@param r  The red, 0 to 255.
		@param g  The green, 0 to 255.
		@param b  The blue, 0 to 255.
		@param a  The alpha, 0 to 255. */
	public function new(r:Int = 0, g:Int = 0, b:Int = 0, a:Int = 255) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}

	/** Returns a separate copy.

		@param out  Optional. The Color to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:Color):Color {
		if (out == null)
			return new Color(r, g, b, a);
		out.r = r;
		out.g = g;
		out.b = b;
		out.a = a;
		return out;
	}
}
