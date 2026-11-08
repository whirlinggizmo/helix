package helix.raylib;

/** Represents raylib's `Rectangle`: its top-left corner and its size.

	Assigning one gives a reference to it, not a copy. See `copy` for a separate one. */
@:structInit
class Rectangle {
	/** Gets or sets the left edge. */
	public var x:Float;

	/** Gets or sets the top edge. */
	public var y:Float;

	/** Gets or sets the width. */
	public var width:Float;

	/** Gets or sets the height. */
	public var height:Float;

	/** Creates a rectangle.

		@param x  The left edge.
		@param y  The top edge.
		@param width  The width.
		@param height  The height. */
	public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	/** Returns a separate copy.

		@param out  Optional. The Rectangle to copy into, so nothing is made; a new one when omitted.
		@return  The copy: out, when given. */
	public function copy(?out:Rectangle):Rectangle {
		if (out == null)
			return new Rectangle(x, y, width, height);
		out.x = x;
		out.y = y;
		out.width = width;
		out.height = height;
		return out;
	}
}
