package helix.jolt;

/** Specifies how a body's mass and inertia are found. */
enum abstract EOverrideMassProperties(Int) {
	/** Both from the shape and its density. */
	var EOverrideMassProperties_CalculateMassAndInertia = 0;

	/** The mass from `BodyCreationSettings.mMassPropertiesOverride`, the inertia from the shape scaled to it. */
	var EOverrideMassProperties_CalculateInertia = 1;

	/** Both from `BodyCreationSettings.mMassPropertiesOverride`. */
	var EOverrideMassProperties_MassAndInertiaProvided = 2;
}
