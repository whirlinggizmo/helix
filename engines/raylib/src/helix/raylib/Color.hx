package helix.raylib;

/** Represents raylib's `Color`: red, green, blue and alpha, each 0 to 255.

	A value, as in C: assigning one copies it, so changing the copy leaves the original as it was. `c.a = 128` changes the variable or
	field `c` names. */
abstract Color(Int) {
	/** Gets or sets the red, 0 to 255. */
	public var r(get, set):Int;

	/** Gets or sets the green, 0 to 255. */
	public var g(get, set):Int;

	/** Gets or sets the blue, 0 to 255. */
	public var b(get, set):Int;

	/** Gets or sets the alpha, 0 (clear) to 255 (opaque). */
	public var a(get, set):Int;

	/** Creates a color.

		@param r  The red, 0 to 255.
		@param g  The green, 0 to 255.
		@param b  The blue, 0 to 255.
		@param a  The alpha, 0 to 255. */
	public inline function new(r:Int = 0, g:Int = 0, b:Int = 0, a:Int = 255)
		this = (r & 255) | (g & 255) << 8 | (b & 255) << 16 | (a & 255) << 24;

	inline function get_r():Int
		return this & 255;

	inline function get_g():Int
		return (this >> 8) & 255;

	inline function get_b():Int
		return (this >> 16) & 255;

	inline function get_a():Int
		return this >>> 24;

	inline function set_r(value:Int):Int {
		this = (this & ~0xFF) | (value & 255);
		return value;
	}

	inline function set_g(value:Int):Int {
		this = (this & ~0xFF00) | (value & 255) << 8;
		return value;
	}

	inline function set_b(value:Int):Int {
		this = (this & ~0xFF0000) | (value & 255) << 16;
		return value;
	}

	inline function set_a(value:Int):Int {
		this = (this & 0xFFFFFF) | (value & 255) << 24;
		return value;
	}
}
