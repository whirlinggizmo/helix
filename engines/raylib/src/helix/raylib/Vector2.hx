package helix.raylib;

/** Represents raylib's `Vector2`: a point or a direction in two dimensions. */
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
}
