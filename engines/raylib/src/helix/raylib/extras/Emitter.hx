package helix.raylib.extras;

import helix.raylib.*;

/** Represents the settings a 3D and a 2D emitter share. Lengths are in world units for an `Emitter3D` and in pixels for an
	`Emitter2D`. */
@:allow(helix.raylib)
class Emitter {
	/** Gets how many of its particles are alive. */
	public var particleCount(default, null):Int = 0;

	/** Gets or sets how many particles are born a second while it's updated, 0 or more: 10 by default. At 0 none are born, and those
		alive live on. */
	public var rate:Float = 10;

	/** Gets or sets the shortest a particle lives, in seconds: 1 by default. */
	public var minLife:Float = 1;

	/** Gets or sets the longest a particle lives, in seconds: 1 by default. At least `minLife`. */
	public var maxLife:Float = 1;

	/** Gets or sets the radius of a `Sphere` or `Circle` spawn shape: 0 by default. Particles are born evenly inside it. */
	public var spawnRadius:Float = 0;

	/** Gets or sets the half angle of the cone around `velocity` particles are thrown within, 0 to 180 degrees: 30 by default. 180
		throws them every way. */
	public var spread:Float = 30;

	/** Gets or sets how much a particle's speed varies either way, 0 to 1 of itself: 0 by default. */
	public var speedVariance:Float = 0;

	/** Gets or sets the share of the emitter's own motion particles are born with, 0 to 1: 0 by default. 1 throws them along as it
		moves. */
	public var inheritVelocity:Float = 0;

	/** Gets or sets how much the air slows particles, in proportion to their speed, a second: 0 by default. */
	public var drag:Float = 0;

	/** Gets or sets how far a particle strays from its path on a smooth wandering course: 0 by default. Dust motes and fireflies
		wander. */
	public var wanderDistance:Float = 0;

	/** Gets or sets how often a wandering particle's course turns, a second: 1 by default. */
	public var wanderRate:Float = 1;

	/** Gets or sets each particle's size at birth: 0.25 for an `Emitter3D` and 16 for an `Emitter2D` by default. */
	public var startSize:Float;

	/** Gets or sets each particle's size at death: 0.25 for an `Emitter3D` and 16 for an `Emitter2D` by default. */
	public var endSize:Float;

	/** Gets or sets sizes between birth and death, in order of `at`: none by default. 8 at most; past that, ignored. */
	public var sizeKeys:Array<EmitterSizeKey> = [];

	/** Gets or sets how much a particle's size varies at birth, 0 to 1 of itself: 0 by default. */
	public var sizeVariance:Float = 0;

	/** Gets or sets each particle's color at birth: white by default. */
	public var startColor:Color = new Color(255, 255, 255, 255);

	/** Gets or sets each particle's color at death: white of alpha 0 by default, fading it out. */
	public var endColor:Color = new Color(255, 255, 255, 0);

	/** Gets or sets colors between birth and death, in order of `at`: none by default. 8 at most; past that, ignored. */
	public var colorKeys:Array<EmitterColorKey> = [];

	/** Gets or sets colors a particle may be tinted by, one picked at its birth: none by default, untinted. 8 at most; past that, ignored. */
	public var palette:Array<Color> = [];

	/** Gets or sets the texture each particle draws: a soft round dot when null, the default. */
	public var texture:Null<Texture2D> = null;

	/** Gets or sets the part of `texture` drawn: all of it when null, the default. */
	public var source:Null<Rectangle> = null;

	/** Gets or sets the flipbook's frames across `source`: 1 by default. */
	public var frameColumns:Int = 1;

	/** Gets or sets the flipbook's frames down `source`: 1 by default. */
	public var frameRows:Int = 1;

	/** Gets or sets how many of the flipbook's frames are played: 0, all of them, by default. */
	public var frameCount:Int = 0;

	/** Gets or sets the flipbook's frames a second: 0 by default, playing them once over each particle's life. */
	public var framesPerSecond:Float = 0;

	/** Gets or sets the slowest a particle spins, in degrees a second, negative for the other way: 0 by default. */
	public var minSpin:Float = 0;

	/** Gets or sets the fastest a particle spins, in degrees a second: 0 by default. At least `minSpin`. */
	public var maxSpin:Float = 0;

	/** Gets or sets how far along its motion on screen a particle stretches, as a streak, in seconds of that motion: 0, square, by
		default. */
	public var stretch:Float = 0;

	/** Gets or sets how particles are drawn over what's behind: `BLEND_ALPHA` by default, or another of raylib's blend modes. */
	public var blendMode:Int = Raylib.BLEND_ALPHA;

	/** Gets or sets the seed of the emitter's random numbers: 0 by default. The same seed and fields give the same particles from its
		load or its clear. */
	public var seed:Int = 0;

	// The particles, a ring of `capacity` slots: SLOT floats each in `slots` (born, life, x, y, z, vx, vy, vz, size scale, spin in
	// radians a second, a random 0 to 1) and each one's tint in `tints`. `head` is the next slot written, and the `span` slots before it
	// run from the oldest that may be alive to the newest.
	var capacity = 1;
	var slots:haxe.ds.Vector<Float>;
	var tints:haxe.ds.Vector<Int>;
	var head = 0;
	var span = 0;
	// The emitter's clock, in seconds, and the births its rate owes, a fraction of one.
	var clock = 0.;
	var owed = 0.;
	// Where it was at its last update, whether it has been updated since its load or clear, and how fast it moved over that update.
	var placed = false;
	var lastX = 0.;
	var lastY = 0.;
	var lastZ = 0.;
	var moveX = 0.;
	var moveY = 0.;
	var moveZ = 0.;
	// Its random numbers, started from `seed` at the first birth after its load or clear.
	final random = new helix.math.Random(0);
	var seeded = false;
	// The births since its records were last written to the GPU (a 3D emitter's), at most `capacity`.
	var fresh = 0;

	function new(maxParticles:Int) {
		capacity = maxParticles < 1 ? 1 : maxParticles;
		slots = new haxe.ds.Vector(capacity * SLOT);
		tints = new haxe.ds.Vector(capacity);
		for (i in 0...capacity * SLOT)
			slots[i] = 0;
		for (i in 0...capacity)
			tints[i] = 0;
	}

	// The floats of a particle's slot.
	static inline final SLOT = 11;
}
