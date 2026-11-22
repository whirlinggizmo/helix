package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents a distance constraint, made by `DistanceConstraintSettings`. */
class DistanceConstraint extends TwoBodyConstraint {
	@:allow(helix.jolt) function new(world:Int, handle:Int) {
		super(world, handle);
	}

	/** Sets the range of distances.

		@param inMinDistance  The shortest distance, in meters.
		@param inMaxDistance  The longest distance, in meters. */
	public function SetDistance(inMinDistance:Float, inMaxDistance:Float):Void {
		Hj.constraintSetRange(world, handle, inMinDistance, inMaxDistance);
	}

	/** Returns the shortest distance.

		@return  The distance, in meters. */
	public function GetMinDistance():Float {
		return Hj.constraintGetFloat(world, handle, 20);
	}

	/** Returns the longest distance.

		@return  The distance, in meters. */
	public function GetMaxDistance():Float {
		return Hj.constraintGetFloat(world, handle, 21);
	}
}
