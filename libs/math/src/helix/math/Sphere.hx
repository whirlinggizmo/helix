package helix.math;

/** Represents a sphere: a center and a radius.

	```haxe
	var reach = new Sphere(tower.x, tower.y, tower.z, 12);
	if (reach.contains(enemy.x, enemy.y, enemy.z))
		fire();
	```

	A sphere with a radius below 0 is empty: the sphere holds no point and touches no shape. `set`, `copyFrom`, `makeEmpty` and `expand`
	change this sphere and return it. The others write their result into an optional out, the last argument, and return it: a new value
	when omitted. */
class Sphere {
	/** Gets the center. */
	public final center:Vector3;

	/** Gets or sets the radius; below 0 while empty. */
	public var radius:Float;

	/** Creates a sphere, of radius 1 at the origin unless told.

		@param x  Optional. The center's x; defaults to 0.
		@param y  Optional. The center's y; defaults to 0.
		@param z  Optional. The center's z; defaults to 0.
		@param radius  Optional. The radius; defaults to 1. */
	public function new(x = 0., y = 0., z = 0., radius = 1.) {
		center = new Vector3(x, y, z);
		this.radius = radius;
	}

	/** Sets the sphere's center and radius.

		@param x  The center's x.
		@param y  The center's y.
		@param z  The center's z.
		@param radius  The radius.
		@return  This sphere. */
	public function set(x:Float, y:Float, z:Float, radius:Float):Sphere {
		center.set(x, y, z);
		this.radius = radius;
		return this;
	}

	/** Sets the sphere's center and radius to another sphere's.

		@param other  The sphere to copy.
		@return  This sphere. */
	public function copyFrom(other:Sphere):Sphere {
		center.copyFrom(other.center);
		radius = other.radius;
		return this;
	}

	/** Makes the sphere empty: at the origin, with a radius of -1.

		@return  This sphere. */
	public function makeEmpty():Sphere
		return set(0, 0, 0, -1);

	/** Gets a value indicating whether the sphere is empty: its radius is below 0. */
	public var isEmpty(get, never):Bool;

	inline function get_isEmpty():Bool
		return !(radius >= 0);

	/** Returns the smallest sphere around a box.

		@param bounds  The box.
		@param out  Optional. The sphere to fill; a new one when omitted.
		@return  The sphere; an empty sphere for an empty box. */
	public static function fromBounds(bounds:Aabb3D, ?out:Sphere):Sphere {
		if (out == null)
			out = new Sphere();
		if (bounds.isEmpty)
			return out.makeEmpty();
		var x = (bounds.maxX - bounds.minX) / 2,
			y = (bounds.maxY - bounds.minY) / 2,
			z = (bounds.maxZ - bounds.minZ) / 2;
		return out.set(bounds.minX + x, bounds.minY + y, bounds.minZ + z, Math.sqrt(x * x + y * y + z * z));
	}

	/** Returns a sphere around points: its center the middle of the points' bounds, its radius the distance to the farthest point.

		@param points  The points' numbers.
		@param pointCount  How many points.
		@param offset  Optional. Where the first point's x is in `points`; defaults to 0.
		@param stride  Optional. How many numbers from one point's x to the next point's; defaults to 3.
		@param out  Optional. The sphere to fill; a new one when omitted.
		@return  The sphere; an empty sphere for no points. */
	public static function fromPoints(points:Array<Float>, pointCount:Int, offset = 0, stride = 3, ?out:Sphere):Sphere {
		if (out == null)
			out = new Sphere();
		if (pointCount <= 0)
			return out.makeEmpty();
		var minX = Math.POSITIVE_INFINITY,
			minY = Math.POSITIVE_INFINITY,
			minZ = Math.POSITIVE_INFINITY;
		var maxX = Math.NEGATIVE_INFINITY,
			maxY = Math.NEGATIVE_INFINITY,
			maxZ = Math.NEGATIVE_INFINITY;
		for (index in 0...pointCount) {
			var at = offset + index * stride;
			var x = points[at], y = points[at + 1], z = points[at + 2];
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
		}
		var centerX = (minX + maxX) / 2,
			centerY = (minY + maxY) / 2,
			centerZ = (minZ + maxZ) / 2;
		var farthest = 0.;
		for (index in 0...pointCount) {
			var at = offset + index * stride;
			var x = points[at] - centerX,
				y = points[at + 1] - centerY,
				z = points[at + 2] - centerZ;
			var distance = x * x + y * y + z * z;
			if (distance > farthest)
				farthest = distance;
		}
		return out.set(centerX, centerY, centerZ, Math.sqrt(farthest));
	}

	/** Returns whether a point is inside the sphere or on its surface.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@return  true when the point is in the sphere; false for an empty sphere. */
	public function contains(x:Float, y:Float, z:Float):Bool {
		x -= center.x;
		y -= center.y;
		z -= center.z;
		return radius >= 0 && x * x + y * y + z * z <= radius * radius;
	}

	/** Returns whether this sphere and another overlap, touching included.

		@param other  The other sphere.
		@return  true when the spheres overlap; false when either is empty. */
	public function intersects(other:Sphere):Bool {
		var x = other.center.x - center.x,
			y = other.center.y - center.y,
			z = other.center.z - center.z;
		var reach = radius + other.radius;
		return radius >= 0 && other.radius >= 0 && x * x + y * y + z * z <= reach * reach;
	}

	/** Returns whether this sphere and a box overlap, touching included.

		@param bounds  The box.
		@return  true when the sphere and the box overlap; false when either is empty. */
	public inline function intersectsBounds(bounds:Aabb3D):Bool
		return bounds.intersectsSphere(this);

	/** Returns the point in the sphere nearest a point.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The nearest point: the point itself when inside the sphere, and the center for an empty sphere. */
	public function getClosestPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3 {
		var dx = x - center.x, dy = y - center.y, dz = z - center.z;
		var distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
		var reach = radius >= 0 ? radius : 0;
		if (distance > reach) {
			var scale = reach / distance;
			x = center.x + dx * scale;
			y = center.y + dy * scale;
			z = center.z + dz * scale;
		}
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	/** Grows this sphere to hold a point: the smallest sphere holding the sphere as it was and the point.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@return  This sphere. An empty sphere becomes the point, with a radius of 0. */
	public function expand(x:Float, y:Float, z:Float):Sphere {
		if (!(radius >= 0))
			return set(x, y, z, 0);
		var dx = x - center.x, dy = y - center.y, dz = z - center.z;
		var distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
		if (distance > radius) {
			// The far side of the sphere stays where it is, and the near side moves out to the point.
			var grown = (radius + distance) / 2,
				shift = (grown - radius) / distance;
			center.set(center.x + dx * shift, center.y + dy * shift, center.z + dz * shift);
			radius = grown;
		}
		return this;
	}

	/** Returns the smallest sphere holding this sphere and another.

		An empty sphere adds nothing: the union with one is the other sphere.
		@param other  The other sphere.
		@param out  Optional. The sphere to fill; a new one when omitted. It may be this sphere or the other.
		@return  The union. */
	public function union(other:Sphere, ?out:Sphere):Sphere {
		if (out == null)
			out = new Sphere();
		if (!(other.radius >= 0))
			return out.copyFrom(this);
		if (!(radius >= 0))
			return out.copyFrom(other);
		var dx = other.center.x - center.x,
			dy = other.center.y - center.y,
			dz = other.center.z - center.z;
		var distance = Math.sqrt(dx * dx + dy * dy + dz * dz);
		// One holds the other.
		if (distance + other.radius <= radius)
			return out.copyFrom(this);
		if (distance + radius <= other.radius)
			return out.copyFrom(other);
		var grown = (distance + radius + other.radius) / 2,
			shift = (grown - radius) / distance;
		return out.set(center.x + dx * shift, center.y + dy * shift, center.z + dz * shift, grown);
	}

	/** Returns this sphere moved by a matrix: its center moved, its radius scaled by the largest scale the matrix gives an axis.

		@param matrix  The matrix.
		@param out  Optional. The sphere to fill; a new one when omitted. It may be this sphere.
		@return  The moved sphere, which holds every moved point of this sphere unless the matrix shears. An empty sphere stays empty. */
	public function transform(matrix:Matrix4, ?out:Sphere):Sphere {
		if (out == null)
			out = new Sphere();
		if (!(radius >= 0))
			return out.makeEmpty();
		var x = matrix.m0 * matrix.m0 + matrix.m1 * matrix.m1 + matrix.m2 * matrix.m2,
			y = matrix.m4 * matrix.m4 + matrix.m5 * matrix.m5 + matrix.m6 * matrix.m6,
			z = matrix.m8 * matrix.m8 + matrix.m9 * matrix.m9 + matrix.m10 * matrix.m10;
		var scale = Math.sqrt(x > y ? (x > z ? x : z) : (y > z ? y : z));
		var moved = radius * scale;
		matrix.transformPoint(center.x, center.y, center.z, out.center);
		out.radius = moved;
		return out;
	}

	/** Returns the box around this sphere.

		@param out  Optional. The box to fill; a new one when omitted.
		@return  The box; an empty box for an empty sphere. */
	public function getBounds(?out:Aabb3D):Aabb3D {
		if (out == null)
			out = new Aabb3D();
		if (!(radius >= 0))
			return out.makeEmpty();
		return out.set(center.x - radius, center.y - radius, center.z - radius, center.x + radius, center.y + radius, center.z + radius);
	}
}
