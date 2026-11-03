package helix.geometry;

import helix.math.Bounds3D;
import helix.math.Matrix3D;
import helix.math.Vector3D;

/** Represents a ray: a point it starts from and a direction it goes in, for picking and line of sight.

	A ray meets a plane, a sphere, bounds, a triangle or a mesh at most once: the first point at or after its origin. Starting inside a
	sphere, bounds or a closed mesh, that is where it leaves. Each test returns where, as a `RayHit3D`, or null when the ray misses,
	its out unchanged. A hit's distance is how far along the direction it is, in the direction's lengths: with a direction of length 1,
	in world units. Shapes are given as plain numbers, as `Frustum3D` and `Bounds3D` take them. Given an out, no test allocates. */
class Ray3D {
	/** Gets the point it starts from. */
	public final origin = new Vector3D(0, 0, 0);

	/** Gets the way it goes; any length but 0. */
	public final direction = new Vector3D(0, 0, -1);

	/** Creates a ray from the origin along -z. */
	public function new() {}

	/** Sets the origin and the direction.

		@param x  The origin's x.
		@param y  Its y.
		@param z  Its z.
		@param dx  The direction's x.
		@param dy  Its y.
		@param dz  Its z.
		@return  This ray. */
	public function set(x:Float, y:Float, z:Float, dx:Float, dy:Float, dz:Float):Ray3D {
		origin.set(x, y, z);
		direction.set(dx, dy, dz);
		return this;
	}

	/** Copies another ray into this one.

		@param other  The ray.
		@return  This ray. */
	public function copyFrom(other:Ray3D):Ray3D {
		origin.copyFrom(other.origin);
		direction.copyFrom(other.direction);
		return this;
	}

	/** Returns the point a distance along the ray.

		@param distance  How far, in the direction's lengths.
		@param out  Optional. Set to the point.
		@return  The point. */
	public function computePoint(distance:Float, ?out:Vector3D):Vector3D {
		var x = origin.x + direction.x * distance,
			y = origin.y + direction.y * distance,
			z = origin.z + direction.z * distance;
		return out == null ? new Vector3D(x, y, z) : out.set(x, y, z);
	}

	/** Returns the ray moved by a transform: its origin as a point, its direction as a direction. A ray put into a mesh's own space with
		its transform's inverse meets the mesh where the world's ray meets the mesh drawn with the transform.

		@param matrix  The transform.
		@param out  Optional. Set to the moved ray; may be this one.
		@return  The moved ray. */
	public function transform(matrix:Matrix3D, ?out:Ray3D):Ray3D {
		if (out == null)
			out = new Ray3D();
		var dx = direction.x, dy = direction.y, dz = direction.z;
		matrix.transformPoint(origin.x, origin.y, origin.z, out.origin);
		matrix.transformDirection(dx, dy, dz, out.direction);
		return out;
	}

	/** Returns where the ray meets a plane, from either side. The hit's normal is the plane's, as given.

		@param x  A point on the plane's x.
		@param y  Its y.
		@param z  Its z.
		@param nx  The plane's normal's x.
		@param ny  Its y.
		@param nz  Its z.
		@param out  Optional. Set to the hit.
		@return  The hit; null when the ray runs along the plane or away from it. */
	public function intersectPlane(x:Float, y:Float, z:Float, nx:Float, ny:Float, nz:Float, ?out:RayHit3D):Null<RayHit3D> {
		var denominator = nx * direction.x + ny * direction.y + nz * direction.z;
		if (denominator == 0)
			return null;
		var t = (nx * (x - origin.x) + ny * (y - origin.y) + nz * (z - origin.z)) / denominator;
		if (!(t >= 0))
			return null;
		var length = Math.sqrt(nx * nx + ny * ny + nz * nz);
		return hit(t, nx / length, ny / length, nz / length, -1, out);
	}

	/** Returns where the ray meets a sphere: where it goes in, or from inside, where it comes out. The hit's normal points out of the
		sphere.

		@param x  The center's x.
		@param y  Its y.
		@param z  Its z.
		@param radius  The radius.
		@param out  Optional. Set to the hit.
		@return  The hit; null when it misses or the sphere is behind it. */
	public function intersectSphere(x:Float, y:Float, z:Float, radius:Float, ?out:RayHit3D):Null<RayHit3D> {
		var ox = origin.x - x, oy = origin.y - y, oz = origin.z - z;
		var a = direction.lengthSquared;
		if (a == 0)
			return null;
		var b = ox * direction.x + oy * direction.y + oz * direction.z;
		var c = ox * ox + oy * oy + oz * oz - radius * radius;
		var discriminant = b * b - a * c;
		if (discriminant < 0)
			return null;
		var root = Math.sqrt(discriminant);
		var t = (-b - root) / a;
		if (t < 0)
			t = (-b + root) / a;
		if (t < 0)
			return null;
		var px = ox + direction.x * t,
			py = oy + direction.y * t,
			pz = oz + direction.z * t;
		var length = Math.sqrt(px * px + py * py + pz * pz);
		return length == 0 ? hit(t, 0, 0, 0, -1, out) : hit(t, px / length, py / length, pz / length, -1, out);
	}

	/** Returns where the ray meets bounds: where it goes in, or from inside, where it comes out. The hit's normal points out of the face
		it is on.

		@param bounds  The bounds; empty ones are never met.
		@param out  Optional. Set to the hit.
		@return  The hit; null when it misses or the bounds are behind it. */
	public function intersectBounds(bounds:Bounds3D, ?out:RayHit3D):Null<RayHit3D> {
		if (bounds.isEmpty || direction.lengthSquared == 0)
			return null;
		var near = Math.NEGATIVE_INFINITY, far = Math.POSITIVE_INFINITY;
		var nearAxis = -1, farAxis = -1, nearSign = 0., farSign = 0.;
		for (axis in 0...3) {
			var o = axis == 0 ? origin.x : axis == 1 ? origin.y : origin.z;
			var d = axis == 0 ? direction.x : axis == 1 ? direction.y : direction.z;
			var min = axis == 0 ? bounds.minX : axis == 1 ? bounds.minY : bounds.minZ;
			var max = axis == 0 ? bounds.maxX : axis == 1 ? bounds.maxY : bounds.maxZ;
			if (d == 0) {
				if (o < min || o > max)
					return null;
				continue;
			}
			// Going in through the face the direction meets first, out through the other.
			var enter = ((d > 0 ? min : max) - o) / d,
				leave = ((d > 0 ? max : min) - o) / d;
			if (enter > near) {
				near = enter;
				nearAxis = axis;
				nearSign = d > 0 ? -1 : 1;
			}
			if (leave < far) {
				far = leave;
				farAxis = axis;
				farSign = d > 0 ? 1 : -1;
			}
		}
		if (near > far || far < 0)
			return null;
		var t = near >= 0 ? near : far,
			axis = near >= 0 ? nearAxis : farAxis,
			sign = near >= 0 ? nearSign : farSign;
		return hit(t, axis == 0 ? sign : 0, axis == 1 ? sign : 0, axis == 2 ? sign : 0, -1, out);
	}

	/** Returns where the ray meets a triangle, from either side. The hit's normal is the triangle's front's: the side its corners are
		counterclockwise from.

		@param ax  The first corner's x.
		@param ay  Its y.
		@param az  Its z.
		@param bx  The second corner's x.
		@param by  Its y.
		@param bz  Its z.
		@param cx  The third corner's x.
		@param cy  Its y.
		@param cz  Its z.
		@param out  Optional. Set to the hit.
		@return  The hit; null when it misses, runs along it, or the triangle has no area. */
	public function intersectTriangle(ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float, cy:Float, cz:Float, ?out:RayHit3D):Null<RayHit3D> {
		var t = triangleDistance(ax, ay, az, bx, by, bz, cx, cy, cz);
		if (t < 0)
			return null;
		return triangleHit(t, ax, ay, az, bx, by, bz, cx, cy, cz, -1, out);
	}

	/** Returns where the ray first meets a mesh's triangles, from either side, as `intersectTriangle` meets each. With a transform,
		the hit's point, normal and distance are in the ray's space, the world's, as the other tests' are.

		@param mesh  The mesh.
		@param transform  Optional. Where the mesh is: its positions are moved by it. Omitted, they are as they are.
		@param out  Optional. Set to the hit; its `triangleIndex` says which, counted in the order the indices (or the vertices) give them.
		@return  The nearest hit; null when it meets none. */
	public function intersectMesh(mesh:Mesh3D, ?transform:Matrix3D, ?out:RayHit3D):Null<RayHit3D> {
		var p = mesh.positions,
			indices = mesh.indices,
			m = transform == null ? null : transform.values;
		var best = Math.POSITIVE_INFINITY, bestTriangle = -1;
		var corners = scratch;
		for (k in 0...mesh.triangleCount) {
			for (c in 0...3) {
				var i = (indices == null ? k * 3 + c : indices[k * 3 + c]) * 3;
				var x = p[i], y = p[i + 1], z = p[i + 2];
				if (m != null) {
					corners[c * 3] = m[0] * x + m[4] * y + m[8] * z + m[12];
					corners[c * 3 + 1] = m[1] * x + m[5] * y + m[9] * z + m[13];
					corners[c * 3 + 2] = m[2] * x + m[6] * y + m[10] * z + m[14];
				} else {
					corners[c * 3] = x;
					corners[c * 3 + 1] = y;
					corners[c * 3 + 2] = z;
				}
			}
			var t = triangleDistance(corners[0], corners[1], corners[2], corners[3], corners[4], corners[5], corners[6], corners[7], corners[8]);
			if (t >= 0 && t < best) {
				best = t;
				bestTriangle = k;
				for (i in 0...9)
					found[i] = corners[i];
			}
		}
		if (bestTriangle < 0)
			return null;
		var f = found;
		return triangleHit(best, f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8], bestTriangle, out);
	}

	// A triangle's corners as intersectMesh moves them, and the nearest one's.
	static final scratch = [for (_ in 0...9) 0.];

	static final found = [for (_ in 0...9) 0.];

	// How far along the ray it meets a triangle, Möller and Trumbore's test from either side; -1 for not at all.
	function triangleDistance(ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float, cy:Float, cz:Float):Float {
		var e1x = bx - ax, e1y = by - ay, e1z = bz - az;
		var e2x = cx - ax, e2y = cy - ay, e2z = cz - az;
		var dx = direction.x, dy = direction.y, dz = direction.z;
		var px = dy * e2z - dz * e2y,
			py = dz * e2x - dx * e2z,
			pz = dx * e2y - dy * e2x;
		var det = e1x * px + e1y * py + e1z * pz;
		// Along it, or a triangle of no area, to the precision of its sizes.
		var scale = Math.sqrt((e1x * e1x + e1y * e1y + e1z * e1z) * (e2x * e2x + e2y * e2y + e2z * e2z) * (dx * dx + dy * dy + dz * dz));
		if (scale == 0 || Math.abs(det) <= scale * 1e-12)
			return -1;
		var inverse = 1 / det;
		var tx = origin.x - ax, ty = origin.y - ay, tz = origin.z - az;
		var u = (tx * px + ty * py + tz * pz) * inverse;
		if (u < 0 || u > 1)
			return -1;
		var qx = ty * e1z - tz * e1y,
			qy = tz * e1x - tx * e1z,
			qz = tx * e1y - ty * e1x;
		var v = (dx * qx + dy * qy + dz * qz) * inverse;
		if (v < 0 || u + v > 1)
			return -1;
		var t = (e2x * qx + e2y * qy + e2z * qz) * inverse;
		return t >= 0 ? t : -1;
	}

	// The hit on a triangle at a distance, its normal the front's.
	function triangleHit(t:Float, ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float, cy:Float, cz:Float, triangle:Int,
			out:Null<RayHit3D>):RayHit3D {
		var e1x = bx - ax, e1y = by - ay, e1z = bz - az;
		var e2x = cx - ax, e2y = cy - ay, e2z = cz - az;
		var nx = e1y * e2z - e1z * e2y,
			ny = e1z * e2x - e1x * e2z,
			nz = e1x * e2y - e1y * e2x;
		var length = Math.sqrt(nx * nx + ny * ny + nz * nz);
		return hit(t, nx / length, ny / length, nz / length, triangle, out);
	}

	function hit(t:Float, nx:Float, ny:Float, nz:Float, triangle:Int, out:Null<RayHit3D>):RayHit3D {
		if (out == null)
			out = new RayHit3D();
		out.distance = t;
		computePoint(t, out.point);
		out.normal.set(nx, ny, nz);
		out.triangleIndex = triangle;
		return out;
	}
}
