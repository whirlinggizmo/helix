package helix.jolt;

/** Specifies what happened between two bodies in a step: an extra of helix-jolt's, read from a `ContactEvent`. */
enum abstract EContactEventType(Int) {
	/** The bodies started touching, as Jolt's `ContactListener.OnContactAdded` reports. A sensor's body entering it. */
	var EContactEventType_Added = 0;

	/** The bodies were touching and still are, as Jolt's `ContactListener.OnContactPersisted` reports. */
	var EContactEventType_Persisted = 1;

	/** The bodies stopped touching, as Jolt's `ContactListener.OnContactRemoved` reports. A sensor's body leaving it. */
	var EContactEventType_Removed = 2;
}
