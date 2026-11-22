package helix.jolt;

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
		throw "not built yet";
	}

	/** Returns the box's center.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The center. */
	public function GetCenter(?out:Vec3):Vec3 {
		throw "not built yet";
	}

	/** Returns half the box's size along each axis.

		@param out  Optional. The vector to fill; a new one when omitted.
		@return  The half extent. */
	public function GetExtent(?out:Vec3):Vec3 {
		throw "not built yet";
	}
}
