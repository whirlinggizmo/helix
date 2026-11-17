package helix.raylib.extras;

/** Represents where around a 2D emitter's position its particles are born. */
enum abstract EmitterShape2D(Int) {
	/** At the position itself. */
	var Point;

	/** In a rectangle, `spawnHalfSize` to each side, or on its outline with `spawnShell`. */
	var Rectangle;

	/** In an ellipse of radii `spawnHalfSize`, or on its outline with `spawnShell`. */
	var Ellipse;
}
