package helix.jolt;

/** Represents a body's mass and inertia, set in `BodyCreationSettings.mMassPropertiesOverride`. */
class MassProperties {
	/** Gets or sets the mass, in kilograms. */
	public var mMass:Float = 0;

	/** Gets or sets the inertia tensor, about the center of mass. */
	public var mInertia:Mat44;

	/** Creates mass properties of no mass. */
	public function new() {
		throw "not built yet";
	}

	/** Sets the mass and inertia of a solid box.

		@param inBoxSize  The box's full size.
		@param inDensity  The density, in kilograms a cubic meter. */
	public function SetMassAndInertiaOfSolidBox(inBoxSize:Vec3, inDensity:Float):Void {
		throw "not built yet";
	}

	/** Scales the mass to a value, and the inertia with it.

		@param inMass  The mass, in kilograms. */
	public function ScaleToMass(inMass:Float):Void {
		throw "not built yet";
	}
}
