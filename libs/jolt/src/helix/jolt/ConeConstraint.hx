package helix.jolt;

import helix.jolt.internal.Hj;

/** Represents a cone constraint, made by `ConeConstraintSettings`. */
class ConeConstraint extends TwoBodyConstraint {
	@:allow(helix.jolt) function new(world:Int, handle:Int) {
		super(world, handle);
	}

	/** Sets half the cone's angle.

		@param inHalfConeAngle  The angle, in radians, 0 to pi. */
	public function SetHalfConeAngle(inHalfConeAngle:Float):Void {
		Hj.constraintSetFloat(world, handle, 30, inHalfConeAngle);
	}
}
