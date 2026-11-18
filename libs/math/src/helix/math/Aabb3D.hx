package helix.math;

/** Represents an axis-aligned box in 3 dimensions: its least and greatest coordinate on each axis.

	A new box is empty (its least coordinates past its greatest), so expanding it by a first point makes it that point. `set`,
	`copyFrom`, `makeEmpty` and `expand` change this box and return it. `union` and `getClosestPoint` write their result into an optional
	out, the last argument, and return it: a new value when omitted, this box left unchanged. `union`'s out may be this box or the
	other. Its space is its maker's. */
class Aabb3D {
	/** Gets or sets the least x coordinate; infinity while empty. */
	public var minX:Float = Math.POSITIVE_INFINITY;

	/** Gets or sets the greatest x coordinate; minus infinity while empty. */
	public var maxX:Float = Math.NEGATIVE_INFINITY;

	/** Gets or sets the least y coordinate; infinity while empty. */
	public var minY:Float = Math.POSITIVE_INFINITY;

	/** Gets or sets the greatest y coordinate; minus infinity while empty. */
	public var maxY:Float = Math.NEGATIVE_INFINITY;

	/** Gets or sets the least z coordinate; infinity while empty. */
	public var minZ:Float = Math.POSITIVE_INFINITY;

	/** Gets or sets the greatest z coordinate; minus infinity while empty. */
	public var maxZ:Float = Math.NEGATIVE_INFINITY;

	/** Creates an empty box. */
	public function new() {}

	/** Sets the box's coordinates.

		@param minX  The least x coordinate.
		@param minY  The least y coordinate.
		@param minZ  The least z coordinate.
		@param maxX  The greatest x coordinate.
		@param maxY  The greatest y coordinate.
		@param maxZ  The greatest z coordinate.
		@return  This box. */
	public function set(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Aabb3D {
		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;
		this.minZ = minZ;
		this.maxZ = maxZ;
		return this;
	}

	/** Makes the box empty, holding nothing.

		@return  This box. */
	public function makeEmpty():Aabb3D {
		minX = Math.POSITIVE_INFINITY;
		maxX = Math.NEGATIVE_INFINITY;
		minY = Math.POSITIVE_INFINITY;
		maxY = Math.NEGATIVE_INFINITY;
		minZ = Math.POSITIVE_INFINITY;
		maxZ = Math.NEGATIVE_INFINITY;
		return this;
	}

	/** Sets the box's coordinates to another box's.

		@param other  The box to copy.
		@return  This box. */
	public function copyFrom(other:Aabb3D):Aabb3D {
		minX = other.minX;
		maxX = other.maxX;
		minY = other.minY;
		maxY = other.maxY;
		minZ = other.minZ;
		maxZ = other.maxZ;
		return this;
	}

	/** Gets a value indicating whether the box holds nothing: its least coordinate is past its greatest on an axis, as when made or made empty (`makeEmpty`). */
	public var isEmpty(get, never):Bool;

	function get_isEmpty():Bool
		return !(minX <= maxX) || !(minY <= maxY) || !(minZ <= maxZ);

	/** Gets the width, maxX - minX; 0 while empty. */
	public var width(get, never):Float;

	function get_width():Float
		return isEmpty ? 0 : maxX - minX;

	/** Gets the height, maxY - minY; 0 while empty. */
	public var height(get, never):Float;

	function get_height():Float
		return isEmpty ? 0 : maxY - minY;

	/** Gets the depth, maxZ - minZ; 0 while empty. */
	public var depth(get, never):Float;

	function get_depth():Float
		return isEmpty ? 0 : maxZ - minZ;

	/** Gets the center's x coordinate; NaN while empty. */
	public var centerX(get, never):Float;

	function get_centerX():Float
		return isEmpty ? Math.NaN : (minX + maxX) / 2;

	/** Gets the center's y coordinate; NaN while empty. */
	public var centerY(get, never):Float;

	function get_centerY():Float
		return isEmpty ? Math.NaN : (minY + maxY) / 2;

	/** Gets the center's z coordinate; NaN while empty. */
	public var centerZ(get, never):Float;

	function get_centerZ():Float
		return isEmpty ? Math.NaN : (minZ + maxZ) / 2;

	/** Grows the box to hold a point.

		@param x  The point's x coordinate.
		@param y  The point's y coordinate.
		@param z  The point's z coordinate.
		@return  This box. */
	public function expand(x:Float, y:Float, z:Float):Aabb3D {
		if (x < minX)
			minX = x;
		if (x > maxX)
			maxX = x;
		if (y < minY)
			minY = y;
		if (y > maxY)
			maxY = y;
		if (z < minZ)
			minZ = z;
		if (z > maxZ)
			maxZ = z;
		return this;
	}

	/** Returns the smallest box holding this box and another.

		An empty box adds nothing: the union with one is the other box.
		@param other  The other box.
		@param out  Optional. The box to fill; a new one when omitted. It may be this box or the other.
		@return  The union. */
	public function union(other:Aabb3D, ?out:Aabb3D):Aabb3D {
		if (out == null)
			out = new Aabb3D();
		if (other.isEmpty)
			return out.copyFrom(this);
		return out.set(minX < other.minX ? minX : other.minX, minY < other.minY ? minY : other.minY, minZ < other.minZ ? minZ : other.minZ,
			maxX > other.maxX ? maxX : other.maxX, maxY > other.maxY ? maxY : other.maxY, maxZ > other.maxZ ? maxZ : other.maxZ);
	}

	/** Returns whether a point is in the box, its faces included.

		@param x  The point's x coordinate.
		@param y  The point's y coordinate.
		@param z  The point's z coordinate.
		@return  True when the point is in the box; false for an empty box. */
	public function contains(x:Float, y:Float, z:Float):Bool
		return x >= minX && x <= maxX && y >= minY && y <= maxY && z >= minZ && z <= maxZ;

	/** Returns whether the box and another overlap, touching faces included.

		@param other  The other box.
		@return  True when they overlap; false when either is empty. */
	public function intersects(other:Aabb3D):Bool
		return !isEmpty && !other.isEmpty && minX <= other.maxX && other.minX <= maxX && minY <= other.maxY && other.minY <= maxY && minZ <= other.maxZ
			&& other.minZ <= maxZ;

	/** Returns whether the box and a sphere overlap, touching included.

		@param sphere  The sphere.
		@return  True when they overlap; false when either is empty. */
	public function intersectsSphere(sphere:Sphere):Bool {
		var x = sphere.center.x,
			y = sphere.center.y,
			z = sphere.center.z,
			radius = sphere.radius;
		if (isEmpty || !(radius >= 0))
			return false;
		// The distance squared from the center to the nearest point of the bounds.
		var dx = x < minX ? minX - x : x > maxX ? x - maxX : 0.;
		var dy = y < minY ? minY - y : y > maxY ? y - maxY : 0.;
		var dz = z < minZ ? minZ - z : z > maxZ ? z - maxZ : 0.;
		return dx * dx + dy * dy + dz * dz <= radius * radius;
	}

	/** Returns the point in the box nearest a point.

		@param x  The point's x coordinate.
		@param y  The point's y coordinate.
		@param z  The point's z coordinate.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The nearest point: the point itself when in the box, and NaN on each axis for an empty box. */
	public function getClosestPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3 {
		if (isEmpty) {
			x = Math.NaN;
			y = Math.NaN;
			z = Math.NaN;
		} else {
			x = x < minX ? minX : x > maxX ? maxX : x;
			y = y < minY ? minY : y > maxY ? maxY : y;
			z = z < minZ ? minZ : z > maxZ ? maxZ : z;
		}
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}
}
