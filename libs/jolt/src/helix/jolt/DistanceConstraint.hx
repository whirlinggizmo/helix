package helix.jolt;

/** Represents a distance constraint, made by `DistanceConstraintSettings`. */
class DistanceConstraint extends TwoBodyConstraint {
	function new() {
		super();
	}

	/** Sets the range of distances.

		@param inMinDistance  The shortest distance, in meters.
		@param inMaxDistance  The longest distance, in meters. */
	public function SetDistance(inMinDistance:Float, inMaxDistance:Float):Void {
		throw "not built yet";
	}

	/** Returns the shortest distance.

		@return  The distance, in meters. */
	public function GetMinDistance():Float {
		throw "not built yet";
	}

	/** Returns the longest distance.

		@return  The distance, in meters. */
	public function GetMaxDistance():Float {
		throw "not built yet";
	}
}
