package helix.raylib.extras;

import helix.raylib.*;

/** Represents a 2D particle emitter, made by `LoadEmitter2D`. */
@:allow(helix.raylib)
class Emitter2D extends Emitter {
	/** Gets or sets where the emitter is, in pixels. `UpdateEmitter2D` gives birth along the way from where it was. */
	public var position:Vector2 = new Vector2(0, 0);

	/** Gets or sets the direction and speed particles are born with, in pixels a second: 60 a second up the screen by default. */
	public var velocity:Vector2 = new Vector2(0, -60);

	/** Gets or sets the acceleration every particle feels, in pixels a second squared: none by default. */
	public var gravity:Vector2 = new Vector2(0, 0);

	/** Gets or sets where around the position particles are born: `Point` by default. */
	public var spawnShape:EmitterShape2D = Point;

	/** Gets or sets the half width and height of a `Rectangle` spawn shape, in pixels: 0 by default. */
	public var spawnHalfSize:Vector2 = new Vector2(0, 0);

	/** Gets or sets whether each particle turns to face along its motion, as sparks and arrows do, its spin added: false by default. */
	public var alignToMotion:Bool = false;

	function new(maxParticles:Int) {
		super(maxParticles);
		startSize = 16;
		endSize = 16;
	}
}
