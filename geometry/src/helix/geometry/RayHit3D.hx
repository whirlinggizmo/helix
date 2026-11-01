package helix.geometry;

import helix.math.Vector3D;

/** Represents where a ray meets something (`Ray3D`'s tests): how far along it, the point, and the surface's normal there. */
class RayHit3D {
	/** Gets or sets how far along the ray, in its direction's lengths. */
	public var distance:Float = 0;

	/** Gets the point. */
	public final point = new Vector3D();

	/** Gets the surface's normal at the point, of length 1. */
	public final normal = new Vector3D();

	/** Gets or sets which of a mesh's triangles was met (`Ray3D.intersectMesh`), counted from 0; -1 for any other test. */
	public var triangle:Int = -1;

	/** Creates a hit at the origin, distance 0. */
	public function new() {}

	/** Copies another hit into this one.

		@param other  The hit.
		@return  This hit. */
	public function copyFrom(other:RayHit3D):RayHit3D {
		distance = other.distance;
		point.copyFrom(other.point);
		normal.copyFrom(other.normal);
		triangle = other.triangle;
		return this;
	}
}
