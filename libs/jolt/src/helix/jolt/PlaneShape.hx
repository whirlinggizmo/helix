package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents a plane, solid below it, for the ground of a static body. */
class PlaneShape extends Shape {
	/** Creates the shape.

		@param inPlane  The plane.
		@param inHalfExtent  Optional. Half the size of the square of the plane used for the broad phase, in meters; defaults to 1000. */
	public function new(inPlane:Plane, inHalfExtent = 1000.) {
		super();
		var normal = inPlane.GetNormal();
		register(Hj.shapePlane(normal.x, normal.y, normal.z, inPlane.GetConstant(), inHalfExtent));
	}
}
