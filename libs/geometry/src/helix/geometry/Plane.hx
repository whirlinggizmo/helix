package helix.geometry;

import helix.math.Matrix4;
import helix.math.Vector3;

/** Represents a plane: a point is on the plane when `normal` dot the point, plus `distance`, is 0, and in front of the plane when that
	sum is above 0.

	```haxe
	var floor = Plane.fromPointNormal(0, 2, 0, 0, 1, 0); // facing up, 2 above the origin
	var height = floor.getDistanceTo(player.x, player.y, player.z); // below 0 under the floor
	```

	`set` and `copyFrom` change this plane and return it. The others write their result into an optional out, the last argument, and
	return it: a new value when omitted. */
class Plane {
	/** Gets the direction the plane faces, of length 1. */
	public final normal:Vector3;

	/** Gets or sets how far the origin is in front of the plane. */
	public var distance:Float;

	/** Creates a plane, the ground facing up (+y) unless told.

		@param normalX  Optional. The x of the direction the plane faces, of length 1; defaults to 0.
		@param normalY  Optional. The direction's y; defaults to 1.
		@param normalZ  Optional. The direction's z; defaults to 0.
		@param distance  Optional. How far the origin is in front of the plane; defaults to 0. */
	public function new(normalX = 0., normalY = 1., normalZ = 0., distance = 0.) {
		normal = new Vector3(normalX, normalY, normalZ);
		this.distance = distance;
	}

	/** Sets the plane's normal and distance.

		@param normalX  The x of the direction the plane faces, of length 1.
		@param normalY  The direction's y.
		@param normalZ  The direction's z.
		@param distance  How far the origin is in front of the plane.
		@return  This plane. */
	public function set(normalX:Float, normalY:Float, normalZ:Float, distance:Float):Plane {
		normal.set(normalX, normalY, normalZ);
		this.distance = distance;
		return this;
	}

	/** Sets the plane's normal and distance to another plane's.

		@param other  The plane to copy.
		@return  This plane. */
	public function copyFrom(other:Plane):Plane {
		normal.copyFrom(other.normal);
		distance = other.distance;
		return this;
	}

	/** Returns the plane through a point, facing a direction.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param normalX  The x of the direction the plane faces, of any length.
		@param normalY  The direction's y.
		@param normalZ  The direction's z.
		@param out  Optional. The plane to fill; a new one when omitted.
		@return  The plane. A direction of length 0 gives a plane facing up (+y). */
	public static function fromPointNormal(x:Float, y:Float, z:Float, normalX:Float, normalY:Float, normalZ:Float, ?out:Plane):Plane {
		if (out == null)
			out = new Plane();
		var length = Math.sqrt(normalX * normalX + normalY * normalY + normalZ * normalZ);
		if (length == 0) {
			normalX = 0;
			normalY = 1;
			normalZ = 0;
		} else {
			normalX /= length;
			normalY /= length;
			normalZ /= length;
		}
		return out.set(normalX, normalY, normalZ, -(normalX * x + normalY * y + normalZ * z));
	}

	/** Returns the plane through three points, facing the side the points run counterclockwise on.

		@param ax  The first point's x.
		@param ay  The first point's y.
		@param az  The first point's z.
		@param bx  The second point's x.
		@param by  The second point's y.
		@param bz  The second point's z.
		@param cx  The third point's x.
		@param cy  The third point's y.
		@param cz  The third point's z.
		@param out  Optional. The plane to fill; a new one when omitted.
		@return  The plane. Three points in a line give a plane through the first point, facing up (+y). */
	public static function fromPoints(ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, cx:Float, cy:Float, cz:Float, ?out:Plane):Plane {
		var e1x = bx - ax, e1y = by - ay, e1z = bz - az;
		var e2x = cx - ax, e2y = cy - ay, e2z = cz - az;
		return fromPointNormal(ax, ay, az, e1y * e2z - e1z * e2y, e1z * e2x - e1x * e2z, e1x * e2y - e1y * e2x, out);
	}

	/** Returns how far a point is in front of the plane.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@return  The distance: 0 on the plane, below 0 behind the plane. */
	public inline function getDistanceTo(x:Float, y:Float, z:Float):Float
		return normal.x * x + normal.y * y + normal.z * z + distance;

	/** Returns the point on the plane nearest a point.

		@param x  The point's x.
		@param y  The point's y.
		@param z  The point's z.
		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The nearest point. */
	public function getClosestPoint(x:Float, y:Float, z:Float, ?out:Vector3):Vector3 {
		var away = getDistanceTo(x, y, z);
		x -= normal.x * away;
		y -= normal.y * away;
		z -= normal.z * away;
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	/** Returns where the segment between two points crosses the plane.

		@param ax  The segment's start x.
		@param ay  The start's y.
		@param az  The start's z.
		@param bx  The segment's end x.
		@param by  The end's y.
		@param bz  The end's z.
		@param out  Optional. The vector to fill when the segment crosses; a new one when omitted.
		@return  The crossing, an end on the plane included; the start for a segment lying in the plane. null when both ends are on one
			side, the out unchanged. */
	public function intersectSegment(ax:Float, ay:Float, az:Float, bx:Float, by:Float, bz:Float, ?out:Vector3):Null<Vector3> {
		var start = getDistanceTo(ax, ay, az), end = getDistanceTo(bx, by, bz);
		if ((start > 0 && end > 0) || (start < 0 && end < 0))
			return null;
		var t = start == end ? 0 : start / (start - end);
		var x = ax + (bx - ax) * t,
			y = ay + (by - ay) * t,
			z = az + (bz - az) * t;
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	/** Returns the point three planes share.

		@param a  The first plane.
		@param b  The second plane.
		@param c  The third plane.
		@param out  Optional. The vector to fill when the planes share a point; a new one when omitted.
		@return  The point; null when the planes share no one point (two of them parallel, or all three along one line), the out
			unchanged. */
	public static function intersectPlanes(a:Plane, b:Plane, c:Plane, ?out:Vector3):Null<Vector3> {
		var n1 = a.normal, n2 = b.normal, n3 = c.normal;
		// The three normals crossed two at a time.
		var x23 = n2.y * n3.z - n2.z * n3.y,
			y23 = n2.z * n3.x - n2.x * n3.z,
			z23 = n2.x * n3.y - n2.y * n3.x;
		var x31 = n3.y * n1.z - n3.z * n1.y,
			y31 = n3.z * n1.x - n3.x * n1.z,
			z31 = n3.x * n1.y - n3.y * n1.x;
		var x12 = n1.y * n2.z - n1.z * n2.y,
			y12 = n1.z * n2.x - n1.x * n2.z,
			z12 = n1.x * n2.y - n1.y * n2.x;
		var determinant = n1.x * x23 + n1.y * y23 + n1.z * z23;
		if (Math.abs(determinant) < 1e-12)
			return null;
		var x = -(a.distance * x23 + b.distance * x31 + c.distance * x12) / determinant,
			y = -(a.distance * y23 + b.distance * y31 + c.distance * y12) / determinant,
			z = -(a.distance * z23 + b.distance * z31 + c.distance * z12) / determinant;
		return out == null ? new Vector3(x, y, z) : out.set(x, y, z);
	}

	/** Returns whether a sphere touches or crosses the plane.

		@param sphere  The sphere.
		@return  true when part of the sphere is on the plane; false for an empty sphere. */
	public function intersectsSphere(sphere:Sphere):Bool {
		var away = getDistanceTo(sphere.center.x, sphere.center.y, sphere.center.z);
		return (away < 0 ? -away : away) <= sphere.radius;
	}

	/** Returns whether a box touches or crosses the plane.

		@param bounds  The box.
		@return  true when part of the box is on the plane; false for an empty box. */
	public function intersectsBounds(bounds:Aabb3D):Bool {
		if (bounds.isEmpty)
			return false;
		// How far the box reaches along the normal from its center.
		var reach = (bounds.maxX - bounds.minX) / 2 * Math.abs(normal.x) + (bounds.maxY - bounds.minY) / 2 * Math.abs(normal.y)
			+ (bounds.maxZ - bounds.minZ) / 2 * Math.abs(normal.z);
		var away = getDistanceTo((bounds.minX + bounds.maxX) / 2, (bounds.minY + bounds.maxY) / 2, (bounds.minZ + bounds.maxZ) / 2);
		return (away < 0 ? -away : away) <= reach;
	}

	/** Returns this plane moved by a matrix: the plane through the moved points of this plane, its front the moved front.

		@param matrix  The matrix, which may scale each axis by its own amount, shear and mirror.
		@param out  Optional. The plane to fill; a new one when omitted. It may be this plane.
		@return  The moved plane. A matrix that flattens this plane to a line or a point keeps this plane's normal. */
	public function transform(matrix:Matrix4, ?out:Plane):Plane {
		if (out == null)
			out = new Plane();
		var m0 = matrix.m0, m1 = matrix.m1, m2 = matrix.m2;
		var m4 = matrix.m4, m5 = matrix.m5, m6 = matrix.m6;
		var m8 = matrix.m8, m9 = matrix.m9, m10 = matrix.m10;
		// A normal moves by the cofactors of the matrix's 3 x 3, which keep the normal square to the moved plane.
		var c00 = m5 * m10 - m9 * m6,
			c01 = m9 * m2 - m1 * m10,
			c02 = m1 * m6 - m5 * m2;
		var c10 = m8 * m6 - m4 * m10,
			c11 = m0 * m10 - m8 * m2,
			c12 = m4 * m2 - m0 * m6;
		var c20 = m4 * m9 - m8 * m5,
			c21 = m8 * m1 - m0 * m9,
			c22 = m0 * m5 - m4 * m1;
		var nx = normal.x, ny = normal.y, nz = normal.z;
		// A point of this plane, moved.
		var px = -nx * distance, py = -ny * distance, pz = -nz * distance;
		var x = m0 * px + m4 * py + m8 * pz + matrix.m12,
			y = m1 * px + m5 * py + m9 * pz + matrix.m13,
			z = m2 * px + m6 * py + m10 * pz + matrix.m14;
		// A matrix that mirrors turns the cofactors' normal to the back, so the determinant's sign turns the normal to the front again.
		var side = m0 * c00 + m4 * c01 + m8 * c02 < 0 ? -1. : 1.;
		var movedX = (c00 * nx + c01 * ny + c02 * nz) * side,
			movedY = (c10 * nx + c11 * ny + c12 * nz) * side,
			movedZ = (c20 * nx + c21 * ny + c22 * nz) * side;
		var length = Math.sqrt(movedX * movedX + movedY * movedY + movedZ * movedZ);
		if (length == 0) {
			movedX = nx;
			movedY = ny;
			movedZ = nz;
		} else {
			movedX /= length;
			movedY /= length;
			movedZ /= length;
		}
		return out.set(movedX, movedY, movedZ, -(movedX * x + movedY * y + movedZ * z));
	}
}
