package helix.jolt;

import helix.math.Vector3;

/** Represents an axis-aligned box, by its lowest and highest corners. */
class AABox {
	/** Gets or sets the lowest corner. */
	public var mMin:Vec3;

	/** Gets or sets the highest corner. */
	public var mMax:Vec3;

	/** Creates a box.

		@param inMin  Optional. The lowest corner; defaults to (0, 0, 0).
		@param inMax  Optional. The highest corner; defaults to (0, 0, 0). */
	public function new(?inMin:Vec3, ?inMax:Vec3) {
		mMin = inMin == null ? new Vec3() : inMin;
		mMax = inMax == null ? new Vec3() : inMax;
	}

	/** Returns the box's center.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The center. */
	public function GetCenter(?out:Vec3):Vec3 {
		return Vector3.lerp(mMin, mMax, 0.5, out);
	}

	/** Returns half the box's size along each axis.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The half extent. */
	public function GetExtent(?out:Vec3):Vec3 {
		var extent:Vector3 = (mMax : Vector3).subtract(mMin, out);
		return extent.scale(0.5, extent);
	}
}
