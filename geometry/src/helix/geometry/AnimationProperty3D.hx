package helix.geometry;

/** Specifies which part of a bone's transform an animation's track moves. */
enum AnimationProperty3D {
	/** Its position: three numbers a key. */
	Translation;

	/** Its rotation, a quaternion: four numbers a key, x, y, z and w. */
	Rotation;

	/** Its scale: three numbers a key. */
	Scale;
}
