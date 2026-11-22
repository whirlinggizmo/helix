package helix.jolt;

/** Represents a cylinder along y, centered on its body. */
class CylinderShape extends ConvexShape {
	/** Creates a cylinder.

		@param inHalfHeight  Half the height, in meters.
		@param inRadius  The radius, in meters.
		@param inConvexRadius  Optional. The rounding of the edges, in meters; defaults to 0.05. */
	public function new(inHalfHeight:Float, inRadius:Float, inConvexRadius = 0.05) {
		super();
		throw "not built yet";
	}

	/** Returns the radius.

		@return  The radius, in meters. */
	public function GetRadius():Float {
		throw "not built yet";
	}

	/** Returns half the height.

		@return  The half height, in meters. */
	public function GetHalfHeight():Float {
		throw "not built yet";
	}
}
