package helix.raylib.extras;

/** Represents where around a 3D emitter's position its particles are born. */
enum abstract EmitterShape3D(Int) {
	/** At the position itself. */
	var Point;

	/** In a box, `spawnHalfSize` to each side, or on its surface with `spawnShell`. */
	var Box;

	/** In an ellipsoid of radii `spawnHalfSize`, or on its surface with `spawnShell`. */
	var Ellipsoid;
}
