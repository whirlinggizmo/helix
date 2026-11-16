package helix.raylib.extras;

/** Represents where around a 2D emitter's position its particles are born. */
enum abstract EmitterShape2D(Int) {
	/** At the position itself. */
	var Point;

	/** Anywhere in a rectangle, `spawnHalfSize` to each side. */
	var Rectangle;

	/** Anywhere in a circle of `spawnRadius`. */
	var Circle;
}
