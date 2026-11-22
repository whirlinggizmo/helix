package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Represents a cylinder along y, centered on its body. */
class CylinderShape extends ConvexShape {
	/** Creates a cylinder.

		@param inHalfHeight  Half the height, in meters.
		@param inRadius  The radius, in meters.
		@param inConvexRadius  Optional. The rounding of the edges, in meters; defaults to 0.05. */
	public function new(inHalfHeight:Float, inRadius:Float, inConvexRadius = 0.05) {
		super();
		register(Hj.shapeCylinder(inHalfHeight, inRadius, inConvexRadius));
	}

	/** Returns the radius.

		@return  The radius, in meters. */
	public function GetRadius():Float {
		Hj.shapeGetDimensions(handle);
		return Io.f(0);
	}

	/** Returns half the height.

		@return  The half height, in meters. */
	public function GetHalfHeight():Float {
		Hj.shapeGetDimensions(handle);
		return Io.f(1);
	}
}
