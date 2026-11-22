package helix.jolt;

/** Represents a plane, solid below it, for the ground of a static body. */
class PlaneShape extends Shape {
	/** Creates the shape.

		@param inPlane  The plane.
		@param inHalfExtent  Optional. Half the size of the square of the plane used for the broad phase, in meters; defaults to 1000. */
	public function new(inPlane:Plane, inHalfExtent = 1000.) {
		super();
		throw "not built yet";
	}
}
