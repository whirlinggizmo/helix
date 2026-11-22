package helix.jolt;

/** Represents a plane, by its normal and its distance from the origin. */
class Plane {
	/** Creates a plane: the points p where `inNormal.Dot(p) + inConstant` is 0.

		@param inNormal  The normal, of length 1.
		@param inConstant  The plane's signed distance from the origin, along the normal, negated. */
	public function new(inNormal:Vec3, inConstant:Float) {
		normal = inNormal;
		constant = inConstant;
	}

	/** Returns the normal.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The normal. */
	public function GetNormal(?out:Vec3):Vec3 {
		return (normal : helix.math.Vector3).copy(out);
	}

	/** Returns the plane's constant.

		@return  The constant. */
	public function GetConstant():Float {
		return constant;
	}

	var normal:Vec3;
	var constant:Float;
}
