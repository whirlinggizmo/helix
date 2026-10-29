package helix.math;

/** Represents an axis-aligned box in 2 dimensions: its least and greatest coordinate on each axis.

	A new box is empty (its least coordinates past its greatest), so expanding it by a first point makes it that point. Its space is its
	maker's. */
class Bounds2D {
	/** Gets or sets the least x coordinate; infinity while empty. */
	public var minX:Float = Math.POSITIVE_INFINITY;

	/** Gets or sets the greatest x coordinate; minus infinity while empty. */
	public var maxX:Float = Math.NEGATIVE_INFINITY;

	/** Gets or sets the least y coordinate; infinity while empty. */
	public var minY:Float = Math.POSITIVE_INFINITY;

	/** Gets or sets the greatest y coordinate; minus infinity while empty. */
	public var maxY:Float = Math.NEGATIVE_INFINITY;

	/** Creates an empty box. */
	public function new() {}

	/** Sets the box's coordinates.

		@param minX  The least x coordinate.
		@param minY  The least y coordinate.
		@param maxX  The greatest x coordinate.
		@param maxY  The greatest y coordinate.
		@return  This box. */
	public function set(minX:Float, minY:Float, maxX:Float, maxY:Float):Bounds2D {
		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;
		return this;
	}

	/** Empties the box.

		@return  This box. */
	public function clear():Bounds2D {
		minX = Math.POSITIVE_INFINITY;
		maxX = Math.NEGATIVE_INFINITY;
		minY = Math.POSITIVE_INFINITY;
		maxY = Math.NEGATIVE_INFINITY;
		return this;
	}

	/** Sets the box's coordinates to another box's.

		@param other  The box to copy.
		@return  This box. */
	public function copyFrom(other:Bounds2D):Bounds2D {
		minX = other.minX;
		maxX = other.maxX;
		minY = other.minY;
		maxY = other.maxY;
		return this;
	}

	/** Gets a value indicating whether the box holds nothing: its least coordinate is past its greatest on an axis, as when made or cleared. */
	public var isEmpty(get, never):Bool;

	function get_isEmpty():Bool
		return !(minX <= maxX) || !(minY <= maxY);

	/** Gets the width, maxX - minX; 0 while empty. */
	public var width(get, never):Float;

	function get_width():Float
		return isEmpty ? 0 : maxX - minX;

	/** Gets the height, maxY - minY; 0 while empty. */
	public var height(get, never):Float;

	function get_height():Float
		return isEmpty ? 0 : maxY - minY;

	/** Gets the center's x coordinate; NaN while empty. */
	public var centerX(get, never):Float;

	function get_centerX():Float
		return isEmpty ? Math.NaN : (minX + maxX) / 2;

	/** Gets the center's y coordinate; NaN while empty. */
	public var centerY(get, never):Float;

	function get_centerY():Float
		return isEmpty ? Math.NaN : (minY + maxY) / 2;

	/** Grows the box to hold a point.

		@param x  The point's x coordinate.
		@param y  The point's y coordinate.
		@return  This box. */
	public function expand(x:Float, y:Float):Bounds2D {
		if (x < minX)
			minX = x;
		if (x > maxX)
			maxX = x;
		if (y < minY)
			minY = y;
		if (y > maxY)
			maxY = y;
		return this;
	}

	/** Grows the box to hold another box too.

		An empty box leaves it unchanged.
		@param other  The other box.
		@return  This box. */
	public function union(other:Bounds2D):Bounds2D {
		if (other.isEmpty)
			return this;
		if (other.minX < minX)
			minX = other.minX;
		if (other.maxX > maxX)
			maxX = other.maxX;
		if (other.minY < minY)
			minY = other.minY;
		if (other.maxY > maxY)
			maxY = other.maxY;
		return this;
	}

	/** Returns whether a point is in the box, its edges included.

		@param x  The point's x coordinate.
		@param y  The point's y coordinate.
		@return  True when the point is in the box; false for an empty box. */
	public function contains(x:Float, y:Float):Bool
		return x >= minX && x <= maxX && y >= minY && y <= maxY;

	/** Returns whether the box and another overlap, touching edges included.

		@param other  The other box.
		@return  True when they overlap; false when either is empty. */
	public function intersects(other:Bounds2D):Bool
		return !isEmpty && !other.isEmpty && minX <= other.maxX && other.minX <= maxX && minY <= other.maxY && other.minY <= maxY;
}
