package helix.jolt;

/** Represents a capsule along y, centered on its body: a cylinder with a half sphere on each end, as a standing character. */
class CapsuleShape extends ConvexShape {
	/** Creates a capsule.

		@param inHalfHeightOfCylinder  Half the cylinder's height, without the ends, in meters.
		@param inRadius  The radius, in meters. */
	public function new(inHalfHeightOfCylinder:Float, inRadius:Float) {
		super();
		throw "not built yet";
	}

	/** Returns the radius.

		@return  The radius, in meters. */
	public function GetRadius():Float {
		throw "not built yet";
	}

	/** Returns half the cylinder's height, without the ends.

		@return  The half height, in meters. */
	public function GetHalfHeightOfCylinder():Float {
		throw "not built yet";
	}
}
