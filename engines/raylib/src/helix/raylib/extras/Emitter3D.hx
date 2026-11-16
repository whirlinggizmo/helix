package helix.raylib.extras;

import helix.raylib.*;

/** Represents a 3D particle emitter, made by `LoadEmitter3D`. */
@:allow(helix.raylib)
class Emitter3D extends Emitter {
	/** Gets or sets where the emitter is, in world units. `UpdateEmitter3D` gives birth along the way from where it was. */
	public var position:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets the direction and speed particles are born with, in units a second: 1 a second upward by default. */
	public var velocity:Vector3 = new Vector3(0, 1, 0);

	/** Gets or sets the acceleration every particle feels, in units a second squared: none by default. `(0, -9.8, 0)` for falling
		sparks. */
	public var gravity:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets where around the position particles are born: `Point` by default. */
	public var spawnShape:EmitterShape3D = Point;

	/** Gets or sets the half width, height and depth of a `Box` spawn shape, in world units: 0 by default. */
	public var spawnHalfSize:Vector3 = new Vector3(0, 0, 0);

	/** Gets or sets whether the scene's lights (the Lighting extra) light the particles, each by the lights at its place: false by
		default. */
	public var lit:Bool = false;

	/** Gets or sets the light a lit particle gets from all around, added to the scene lights': a dim grey by default. Its alpha is
		ignored. Ignored unless `lit`. */
	public var ambient:Color = new Color(26, 26, 26, 255);

	// The particles' records on the GPU (helix.raylib.internal.EmitterDraws): a data texture of four texels a particle, the bytes it is
	// written from, the instances' numbers (a static buffer of 0 to capacity - 1, one float each), the draw's buffers, the graphics they
	// were made on, and the clock their birth times count from.
	var records = 0;
	var recordBytes:Null<haxe.io.Bytes> = null;
	var numbers = 0;
	final drawBuffers = [0, 0];
	var gpu:Null<helix.platform.IGraphics> = null;
	var epoch = 0.;

	function new(maxParticles:Int) {
		// The records' texture holds 256 particles a row, 2048 rows at most, as every WebGL2 allows.
		super(maxParticles > 524288 ? 524288 : maxParticles);
		startSize = 0.25;
		endSize = 0.25;
	}
}
