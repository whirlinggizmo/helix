package helix.math;

/** Represents a point in 2 dimensions.

	A method that computes a point writes it into one given to it, so a caller can reuse the same point every frame. Its space is the
	method's. */
class Point2D {
	/** Gets or sets the x coordinate. */
	public var x:Float;

	/** Gets or sets the y coordinate. */
	public var y:Float;

	/** Creates a point.

		@param x  Optional. The x coordinate; defaults to 0.
		@param y  Optional. The y coordinate; defaults to 0. */
	public function new(x = 0., y = 0.) {
		this.x = x;
		this.y = y;
	}

	/** Sets the point's coordinates.

		@param x  The x coordinate.
		@param y  The y coordinate.
		@return  This point. */
	public function set(x:Float, y:Float):Point2D {
		this.x = x;
		this.y = y;
		return this;
	}

	/** Sets the point's coordinates to another point's.

		@param other  The point to copy.
		@return  This point. */
	public function copyFrom(other:Point2D):Point2D {
		x = other.x;
		y = other.y;
		return this;
	}
}
