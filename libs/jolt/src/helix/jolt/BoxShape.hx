package helix.jolt;

/** Represents a box, centered on its body. */
class BoxShape extends ConvexShape {
	/** Creates a box.

		@param inHalfExtent  Half the box's size along each axis, in meters.
		@param inConvexRadius  Optional. The rounding of the box's edges, in meters, no more than the smallest half extent; defaults to
		0.05. */
	public function new(inHalfExtent:Vec3, inConvexRadius = 0.05) {
		super();
		throw "not built yet";
	}

	/** Returns half the box's size along each axis.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The half extent, in meters. */
	public function GetHalfExtent(?out:Vec3):Vec3 {
		throw "not built yet";
	}
}
