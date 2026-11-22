package helix.jolt;

/** Represents a cone constraint, made by `ConeConstraintSettings`. */
class ConeConstraint extends TwoBodyConstraint {
	function new() {
		super();
	}

	/** Sets half the cone's angle.

		@param inHalfConeAngle  The angle, in radians, 0 to pi. */
	public function SetHalfConeAngle(inHalfConeAngle:Float):Void {
		throw "not built yet";
	}
}
