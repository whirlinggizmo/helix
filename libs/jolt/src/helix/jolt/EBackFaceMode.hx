package helix.jolt;

/** Specifies whether a query hits a face from behind. */
enum abstract EBackFaceMode(Int) {
	/** Only a face's front is hit. */
	var EBackFaceMode_IgnoreBackFaces = 0;

	/** Both sides of a face are hit. */
	var EBackFaceMode_CollideWithBackFaces = 1;
}
