package helix.jolt;

import helix.jolt.internal.Hj;
import helix.jolt.internal.Io;

/** Represents a sphere, centered on its body. */
class SphereShape extends ConvexShape {
	/** Creates a sphere.

		@param inRadius  The radius, in meters. */
	public function new(inRadius:Float) {
		super();
		register(Hj.shapeSphere(inRadius));
	}

	/** Returns the radius.

		@return  The radius, in meters. */
	public function GetRadius():Float {
		Hj.shapeGetDimensions(handle);
		return Io.f(0);
	}
}
