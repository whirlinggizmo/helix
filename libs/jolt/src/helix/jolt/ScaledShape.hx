package helix.jolt;

/** Represents another shape scaled. */
class ScaledShape extends Shape {
	/** Creates a scaled shape, holding the shape it scales.

		@param inShape  The shape.
		@param inScale  The scale along each axis. A sphere or capsule scales by the same amount along every axis. */
	public function new(inShape:Shape, inScale:Vec3) {
		super();
		throw "not built yet";
	}

	/** Returns the scale.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The scale along each axis. */
	public function GetScale(?out:Vec3):Vec3 {
		throw "not built yet";
	}
}
