package helix.jolt;

/** Represents a body's mass and inertia, set in `BodyCreationSettings.mMassPropertiesOverride`. */
class MassProperties {
	/** Gets or sets the mass, in kilograms. */
	public var mMass:Float = 0;

	/** Gets or sets the inertia tensor, about the center of mass. */
	public var mInertia:Mat44;

	/** Creates mass properties of no mass. */
	public function new() {
		mInertia = new Mat44();
		mInertia.m0 = mInertia.m5 = mInertia.m10 = 0;
	}

	/** Sets the mass and inertia of a solid box.

		@param inBoxSize  The box's full size.
		@param inDensity  The density, in kilograms a cubic meter. */
	public function SetMassAndInertiaOfSolidBox(inBoxSize:Vec3, inDensity:Float):Void {
		mMass = inBoxSize.x * inBoxSize.y * inBoxSize.z * inDensity;
		var x2 = inBoxSize.x * inBoxSize.x,
			y2 = inBoxSize.y * inBoxSize.y,
			z2 = inBoxSize.z * inBoxSize.z;
		mInertia.makeIdentity();
		mInertia.m0 = mMass / 12 * (y2 + z2);
		mInertia.m5 = mMass / 12 * (x2 + z2);
		mInertia.m10 = mMass / 12 * (x2 + y2);
	}

	/** Scales the mass to a value, and the inertia with it.

		@param inMass  The mass, in kilograms. */
	public function ScaleToMass(inMass:Float):Void {
		if (mMass > 0) {
			var factor = inMass / mMass;
			mInertia.m0 *= factor;
			mInertia.m1 *= factor;
			mInertia.m2 *= factor;
			mInertia.m4 *= factor;
			mInertia.m5 *= factor;
			mInertia.m6 *= factor;
			mInertia.m8 *= factor;
			mInertia.m9 *= factor;
			mInertia.m10 *= factor;
		}
		mMass = inMass;
	}
}
