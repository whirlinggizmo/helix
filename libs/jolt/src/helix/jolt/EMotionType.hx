package helix.jolt;

/** Specifies how a body moves. */
enum abstract EMotionType(Int) {
	/** Never moves: the ground, a wall. */
	var EMotionType_Static = 0;

	/** Moved by the program (`BodyInterface.MoveKinematic`), pushing dynamic bodies aside. */
	var EMotionType_Kinematic = 1;

	/** Moved by the simulation: falling, pushed, thrown. */
	var EMotionType_Dynamic = 2;
}
