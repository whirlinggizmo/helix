package helix.math;

/** An axis-aligned box in 2D, its least and most on each axis: a 2D node's and the like (Node2D.computeBounds), a trigger's region, a camera's limits. Empty
	when made (its least past its most), so expanding it by a first point makes that point; x, y in whatever space
	its maker says. Its 2D is its dimensions, as a Texture2D's is, not the display kind (docs/CONVENTIONS.md). */
class Bounds2D {
	/** Its least x; infinity while empty. */
	public var minX:Float = Math.POSITIVE_INFINITY;

	/** Its most x; minus infinity while empty. */
	public var maxX:Float = Math.NEGATIVE_INFINITY;

	/** Its least y; infinity while empty. */
	public var minY:Float = Math.POSITIVE_INFINITY;

	/** Its most y; minus infinity while empty. */
	public var maxY:Float = Math.NEGATIVE_INFINITY;

	/** An empty box. */
	public function new() {}

	/** Sets it to minX, minY to maxX, maxY; returns it. */
	public function set(minX:Float, minY:Float, maxX:Float, maxY:Float):Bounds2D {
		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;
		return this;
	}

	/** Empties it; returns it. */
	public function clear():Bounds2D {
		minX = Math.POSITIVE_INFINITY;
		maxX = Math.NEGATIVE_INFINITY;
		minY = Math.POSITIVE_INFINITY;
		maxY = Math.NEGATIVE_INFINITY;
		return this;
	}

	/** Sets it to other's; returns it. */
	public function copyFrom(other:Bounds2D):Bounds2D {
		minX = other.minX;
		maxX = other.maxX;
		minY = other.minY;
		maxY = other.maxY;
		return this;
	}

	/** Whether it holds nothing: its least past its most on an axis (as made, or cleared). */
	public var isEmpty(get, never):Bool;

	function get_isEmpty():Bool
		return !(minX <= maxX) || !(minY <= maxY);

	/** Its width, maxX - minX; 0 while empty. */
	public var width(get, never):Float;

	function get_width():Float
		return isEmpty ? 0 : maxX - minX;

	/** Its height, maxY - minY; 0 while empty. */
	public var height(get, never):Float;

	function get_height():Float
		return isEmpty ? 0 : maxY - minY;

	/** Its center's x; NaN while empty. */
	public var centerX(get, never):Float;

	function get_centerX():Float
		return isEmpty ? Math.NaN : (minX + maxX) / 2;

	/** Its center's y; NaN while empty. */
	public var centerY(get, never):Float;

	function get_centerY():Float
		return isEmpty ? Math.NaN : (minY + maxY) / 2;

	/** Grows it to hold the point x, y; returns it. */
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

	/** Grows it to hold other too (an empty other changes nothing); returns it. */
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

	/** Whether the point x, y is in it, its faces included. */
	public function contains(x:Float, y:Float):Bool
		return x >= minX && x <= maxX && y >= minY && y <= maxY;

	/** Whether it and other overlap, touching faces included; never for an empty one. */
	public function intersects(other:Bounds2D):Bool
		return !isEmpty && !other.isEmpty && minX <= other.maxX && other.minX <= maxX && minY <= other.maxY && other.minY <= maxY;
}
