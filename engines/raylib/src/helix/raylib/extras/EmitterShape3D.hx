package helix.raylib.extras;

/** Represents where around a 3D emitter's position its particles are born. */
enum abstract EmitterShape3D(Int) {
	/** At the position itself. */
	var Point;

	/** Anywhere in a box, `spawnHalfSize` to each side. */
	var Box;

	/** Anywhere in a sphere of `spawnRadius`. */
	var Sphere;
}
