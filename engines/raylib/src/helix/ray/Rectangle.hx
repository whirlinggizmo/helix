package helix.ray;

/** Represents raylib's `Rectangle`: its top-left corner and its size. */
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
}
