package helix.raylib.extras;

import helix.raylib.*;

/** Represents a 2D particle emitter, made by `LoadEmitter2D`. */
@:allow(helix.raylib)
class Emitter2D extends Emitter {
	/** Gets or sets where the emitter is, in pixels. `UpdateEmitter2D` spawns particles along the way from where it was. */
	public var position:Vector2 = new Vector2(0, 0);

	/** Gets or sets the direction particles are born moving in, its length ignored: up the screen by default. A direction of no
		length is up the screen. */
	public var direction:Vector2 = new Vector2(0, -1);

	/** Gets or sets the acceleration every particle feels, in pixels a second squared: none by default. */
	public var gravity:Vector2 = new Vector2(0, 0);

	/** Gets or sets where around the position particles are born: `Point` by default. */
	public var spawnShape:EmitterShape2D = Point;

	/** Gets or sets the half width and height of a `Rectangle` spawn shape, or the radii of an `Ellipse` across and down, in pixels: 0 by
		default. A half size of 0 flattens the shape. */
	public var spawnHalfSize:Vector2 = new Vector2(0, 0);

	/** Gets or sets whether each particle turns to face along its motion, as sparks and arrows do, its spin added: false by default. */
	public var alignToMotion:Bool = false;

	function new(maxParticles:Int) {
		super(maxParticles);
		speed = 60;
		sizeKeys = [{at: 0, size: 16}, {at: 1, size: 16}];
	}
}
