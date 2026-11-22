package helix.jolt;

/** Specifies a kind of body. */
enum abstract EBodyType(Int) {
	/** A rigid body. */
	var EBodyType_RigidBody = 0;

	/** A soft body, which this module doesn't make. */
	var EBodyType_SoftBody = 1;
}
