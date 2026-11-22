package helix.box2d;

/** The body simulation type. */
enum abstract B2BodyType(Int) to Int {
	/** Zero mass, zero velocity, may be manually moved. */
	var b2_staticBody = 0;

	/** Zero mass, velocity set by user, moved by solver. */
	var b2_kinematicBody = 1;

	/** Positive mass, velocity determined by forces, moved by solver. */
	var b2_dynamicBody = 2;

	/** Number of body types. */
	var b2_bodyTypeCount = 3;
}
