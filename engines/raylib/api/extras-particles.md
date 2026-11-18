# Particles

[Back to the library](README.md)

## Particles

*class* in [`engines/raylib/src/helix/raylib/extras/Particles.hx`](../src/helix/raylib/extras/Particles.hx), `import helix.raylib.extras.Particles;`

Provides particle emitters, in 3D and in 2D. An emitter's settings are its fields, read each frame, so a program changes one by assigning it. A new emitter already gives off a small fountain of soft white dots that fade. Imported apart: `import helix.raylib.extras.Particles.*;`.

The examples `engines/raylib/examples/extras/particles3d` and `engines/raylib/examples/extras/particles2d` use it.

```haxe
var smoke = LoadEmitter3D(256);
smoke.texture = puff;
smoke.rate = 12;
smoke.minLife = 2;
smoke.maxLife = 3;
smoke.sizeKeys = [{at: 0, size: 0.25}, {at: 1, size: 0.9}];
// each frame
smoke.position = chimneyTop;
smoke.gravity.x = wind;
UpdateEmitter3D(smoke, GetFrameTime());
BeginMode3D(camera);
DrawEmitter3D(smoke);
EndMode3D();
```

A 3D emitter's particles are worked out on the GPU from their age, so thousands cost about what spawning them does. Each emitter draws in a call of its own, its particles facing the camera. A 2D emitter's particles are moved on the CPU and drawn as quads in the same batch as `DrawTexture`, so they layer in draw order with sprites and share their draw calls when they share a texture.

A particle stays where it was born when the emitter moves, so a moving emitter leaves a trail. Particles aren't sorted among themselves: `BLEND_ALPHA` suits soft, pale particles such as smoke and dust, and `BLEND_ADDITIVE` suits glows, sparks and fire.

A field read at a particle's birth (life, spawn, direction, speed, size variance, spin, orbit, palette) changes the particles born after. A field read over a particle's life (gravity, drag, wander, sizes, colors, pulse, texture, blend mode) changes every particle alive. A value out of its range is held to it where it's read. A program that calls none of this links none of it.

### particles: emitters in 3D, drawn on the GPU, and in 2D, drawn in the batch

```haxe
static function LoadEmitter3D(maxParticles:Int):Emitter3D
static function UnloadEmitter3D(emitter:Emitter3D):Void
static function UpdateEmitter3D(emitter:Emitter3D, deltaTime:Float):Void
static function DrawEmitter3D(emitter:Emitter3D):Void
static function EmitParticles3D(emitter:Emitter3D, count:Int):Void
static function PrewarmEmitter3D(emitter:Emitter3D, seconds:Float):Void
static function ClearEmitter3D(emitter:Emitter3D):Void
static function LoadEmitter2D(maxParticles:Int):Emitter2D
static function UnloadEmitter2D(emitter:Emitter2D):Void
static function UpdateEmitter2D(emitter:Emitter2D, deltaTime:Float):Void
static function DrawEmitter2D(emitter:Emitter2D):Void
static function EmitParticles2D(emitter:Emitter2D, count:Int):Void
static function PrewarmEmitter2D(emitter:Emitter2D, seconds:Float):Void
static function ClearEmitter2D(emitter:Emitter2D):Void
```

- `LoadEmitter3D`: Returns a 3D emitter of at most `maxParticles` alive at once, at the origin, every field at its default. A particle born past the most alive takes the oldest one's place.
  - `maxParticles`: The most alive at once, 1 or more.
  - returns: The emitter, the program's until `UnloadEmitter3D`.

  A `maxParticles` over 524288 is held to 524288.
- `UnloadEmitter3D`: Frees a 3D emitter and its particles.
  - `emitter`: The emitter.
- `UpdateEmitter3D`: Advances a 3D emitter by the frame's time. The particles its rate owes are born along the way from where it was to its `position`, so a fast emitter leaves an even trail. Call it once a frame, before `DrawEmitter3D`. An emitter not updated holds still.
  - `emitter`: The emitter.
  - `deltaTime`: The seconds since its last update, as `GetFrameTime` gives them.
- `DrawEmitter3D`: Draws a 3D emitter's particles through the current camera, as `DrawCube` draws: inside `BeginMode3D`, in world units facing the camera, hidden by what's drawn before them but not hiding what's drawn after. Outside it, through the screen's, a unit a pixel.
  - `emitter`: The emitter.
- `EmitParticles3D`: Gives off particles at once at a 3D emitter's position, whatever its rate: a burst.
  - `emitter`: The emitter.
  - `count`: How many.
- `PrewarmEmitter3D`: Runs a 3D emitter ahead in time without drawing, so a fire is already going when first seen.
  - `emitter`: The emitter.
  - `seconds`: How far ahead.
- `ClearEmitter3D`: Takes away every particle alive, and starts the emitter's random numbers again from its `seed`.
  - `emitter`: The emitter.
- `LoadEmitter2D`: Returns a 2D emitter of at most `maxParticles` alive at once, at the origin, every field at its default. A particle born past the most alive takes the oldest one's place.
  - `maxParticles`: The most alive at once, 1 or more.
  - returns: The emitter, the program's until `UnloadEmitter2D`.
- `UnloadEmitter2D`: Frees a 2D emitter and its particles.
  - `emitter`: The emitter.
- `UpdateEmitter2D`: Advances a 2D emitter by the frame's time, moving each particle. The particles its rate owes are born along the way from where it was to its `position`. Call it once a frame, before `DrawEmitter2D`. An emitter not updated holds still.
  - `emitter`: The emitter.
  - `deltaTime`: The seconds since its last update, as `GetFrameTime` gives them.
- `DrawEmitter2D`: Draws a 2D emitter's particles into the batch through the current camera, as `DrawTexture` draws: in screen pixels, or through `BeginMode2D`'s camera. Inside `BeginMode3D`, flat in the world's XY plane, a pixel a unit.
  - `emitter`: The emitter.
- `EmitParticles2D`: Gives off particles at once at a 2D emitter's position, whatever its rate: a burst.
  - `emitter`: The emitter.
  - `count`: How many.
- `PrewarmEmitter2D`: Runs a 2D emitter ahead in time without drawing.
  - `emitter`: The emitter.
  - `seconds`: How far ahead.
- `ClearEmitter2D`: Takes away every particle alive, and starts the emitter's random numbers again from its `seed`.
  - `emitter`: The emitter.

## Emitter2D

*class* in [`engines/raylib/src/helix/raylib/extras/Emitter2D.hx`](../src/helix/raylib/extras/Emitter2D.hx), `import helix.raylib.extras.Emitter2D;`, extends `Emitter`

Represents a 2D particle emitter, made by `LoadEmitter2D`.

```haxe
var position:Vector2
var direction:Vector2
var gravity:Vector2
var spawnShape:EmitterShape2D
var spawnHalfSize:Vector2
var alignToMotion:Bool
```

- `position`: Gets or sets where the emitter is, in pixels. `UpdateEmitter2D` gives birth along the way from where it was.
- `direction`: Gets or sets the direction particles are born moving in, its length ignored: up the screen by default. A direction of no length is up the screen.
- `gravity`: Gets or sets the acceleration every particle feels, in pixels a second squared: none by default.
- `spawnShape`: Gets or sets where around the position particles are born: `Point` by default.
- `spawnHalfSize`: Gets or sets the half width and height of a `Rectangle` spawn shape, or the radii of an `Ellipse` across and down, in pixels: 0 by default. A half size of 0 flattens the shape.
- `alignToMotion`: Gets or sets whether each particle turns to face along its motion, as sparks and arrows do, its spin added: false by default.

## Emitter3D

*class* in [`engines/raylib/src/helix/raylib/extras/Emitter3D.hx`](../src/helix/raylib/extras/Emitter3D.hx), `import helix.raylib.extras.Emitter3D;`, extends `Emitter`

Represents a 3D particle emitter, made by `LoadEmitter3D`.

```haxe
var position:Vector3
var direction:Vector3
var gravity:Vector3
var spawnShape:EmitterShape3D
var spawnHalfSize:Vector3
var lit:Bool
var ambient:Color
```

- `position`: Gets or sets where the emitter is, in world units. `UpdateEmitter3D` gives birth along the way from where it was.
- `direction`: Gets or sets the direction particles are born moving in, its length ignored: up by default. A direction of no length is up.
- `gravity`: Gets or sets the acceleration every particle feels, in units a second squared: none by default. `(0, -9.8, 0)` for falling sparks.
- `spawnShape`: Gets or sets where around the position particles are born: `Point` by default.
- `spawnHalfSize`: Gets or sets the half width, height and depth of a `Box` spawn shape, or the radii of an `Ellipsoid` across, up and through, in world units: 0 by default. A half size of 0 flattens the shape.
- `lit`: Gets or sets whether the scene's lights (the Lighting extra) light the particles, each by the lights at its place: false by default.
- `ambient`: Gets or sets the light a lit particle gets from all around, added to the scene lights': a dim grey by default. Its alpha is ignored. Ignored unless `lit`.

## EmitterShape2D

*abstract* in [`engines/raylib/src/helix/raylib/extras/EmitterShape2D.hx`](../src/helix/raylib/extras/EmitterShape2D.hx), `import helix.raylib.extras.EmitterShape2D;`

Represents where around a 2D emitter's position its particles are born.

- `EmitterShape2D.Point`: At the position itself.
- `EmitterShape2D.Rectangle`: In a rectangle, `spawnHalfSize` to each side, or on its outline with `spawnShell`.
- `EmitterShape2D.Ellipse`: In an ellipse of radii `spawnHalfSize`, or on its outline with `spawnShell`.

## EmitterShape3D

*abstract* in [`engines/raylib/src/helix/raylib/extras/EmitterShape3D.hx`](../src/helix/raylib/extras/EmitterShape3D.hx), `import helix.raylib.extras.EmitterShape3D;`

Represents where around a 3D emitter's position its particles are born.

- `EmitterShape3D.Point`: At the position itself.
- `EmitterShape3D.Box`: In a box, `spawnHalfSize` to each side, or on its surface with `spawnShell`.
- `EmitterShape3D.Ellipsoid`: In an ellipsoid of radii `spawnHalfSize`, or on its surface with `spawnShell`.

## Emitter

*class* in [`engines/raylib/src/helix/raylib/extras/Emitter.hx`](../src/helix/raylib/extras/Emitter.hx), `import helix.raylib.extras.Emitter;`

Represents the settings a 3D and a 2D emitter share. Lengths are in world units for an `Emitter3D` and in pixels for an `Emitter2D`.

```haxe
var particleCount(default, null):Int
var rate:Float
var minLife:Float
var maxLife:Float
var spawnShell:Bool
var spread:Float
var speed:Float
var speedVariance:Float
var inheritVelocity:Float
var localSpace:Bool
var drag:Float
var wanderDistance:Float
var wanderRate:Float
var sizeKeys:Array<EmitterSizeKey>
var sizeVariance:Float
var colorKeys:Array<EmitterColorKey>
var pulseRate:Float
var pulseDepth:Float
var palette:Array<Color>
var texture:Null<Texture2D>
var source:Null<Rectangle>
var frameColumns:Int
var frameRows:Int
var frameCount:Int
var framesPerSecond:Float
var minSpin:Float
var maxSpin:Float
var minOrbit:Float
var maxOrbit:Float
var stretch:Float
var blendMode:Int
var seed:Int
```

- `particleCount`: Gets how many of its particles are alive.
- `rate`: Gets or sets how many particles are born a second while it's updated, 0 or more: 10 by default. At 0 none are born, and those alive live on.
- `minLife`: Gets or sets the shortest a particle lives, in seconds: 1 by default.
- `maxLife`: Gets or sets the longest a particle lives, in seconds: 1 by default. At least `minLife`.
- `spawnShell`: Gets or sets whether particles are born on the spawn shape's surface rather than inside it: false by default. They are spread evenly over the surface as it looks: a shape flattened by a half size of 0 is its outline, so an ellipsoid of height 0 gives a ring. A `Point` ignores it.
- `spread`: Gets or sets the half angle of the cone around `direction` particles are thrown within, 0 to 180 degrees: 30 by default. 180 throws them every way.
- `speed`: Gets or sets how fast particles are born moving, 0 or more: 1 unit a second for an `Emitter3D` and 60 pixels a second for an `Emitter2D` by default.
- `speedVariance`: Gets or sets how much a particle's speed varies either way, 0 to 1 of `speed`: 0 by default.
- `inheritVelocity`: Gets or sets the share of the emitter's own motion particles are born with, 0 to 1: 0 by default. 1 throws them along as it moves. Ignored with `localSpace`.
- `localSpace`: Gets or sets whether particles move with the emitter: false by default, each particle left on its own path as the emitter moves. True moves every particle alive by the emitter's motion, as an aura around a moving character does. The orbit then circles where the emitter is now, and `inheritVelocity` does nothing.
- `drag`: Gets or sets how much the air slows particles, in proportion to their speed, a second: 0 by default.
- `wanderDistance`: Gets or sets how far a particle strays from its path on a smooth wandering course: 0 by default. Dust motes and fireflies wander.
- `wanderRate`: Gets or sets how often a wandering particle's course turns, a second: 1 by default.
- `sizeKeys`: Gets or sets each particle's size over its life, the keys read in order of `at`: 0.25 for an `Emitter3D` and 16 for an `Emitter2D` at 0 and at 1 by default. Before the first key the first key's size holds, and after the last the last's. One key is a size for the whole life, and none is the default's. 8 at most; past that, ignored.
- `sizeVariance`: Gets or sets how much a particle's size varies at birth, 0 to 1 of itself: 0 by default.
- `colorKeys`: Gets or sets each particle's color over its life, the keys read in order of `at`: white at 0 and white of alpha 0 at 1 by default, fading it out. Before the first key the first key's color holds, and after the last the last's. One key is a color for the whole life, and none is the default's. 8 at most; past that, ignored.
- `pulseRate`: Gets or sets how many times a second each particle's alpha beats, on a phase of its own picked at its birth: 0 by default, no beat.
- `pulseDepth`: Gets or sets how far a particle's alpha falls at a beat's low point, 0 to 1 of itself: 1 by default, to clear.
- `palette`: Gets or sets colors a particle may be tinted by, one picked at its birth: none by default, untinted. 8 at most; past that, ignored.
- `texture`: Gets or sets the texture each particle draws: a soft round dot when null, the default.
- `source`: Gets or sets the part of `texture` drawn: all of it when null, the default.
- `frameColumns`: Gets or sets the flipbook's frames across `source`: 1 by default.
- `frameRows`: Gets or sets the flipbook's frames down `source`: 1 by default.
- `frameCount`: Gets or sets how many of the flipbook's frames are played: 0, all of them, by default.
- `framesPerSecond`: Gets or sets the flipbook's frames a second: 0 by default, playing them once over each particle's life.
- `minSpin`: Gets or sets the slowest a particle spins, in degrees a second, negative for the other way: 0 by default.
- `maxSpin`: Gets or sets the fastest a particle spins, in degrees a second: 0 by default. At least `minSpin`.
- `minOrbit`: Gets or sets the slowest a particle travels around the emitter, in degrees a second: 0 by default. A 3D emitter's particle circles the line along `direction` through where the emitter was at its birth, positive counterclockwise seen from where `direction` points. A 2D emitter's particle circles where the emitter was at its birth, positive clockwise on screen. The whole path turns, its own motion included, so a particle thrown outward spirals. Its spin turns it as well.
- `maxOrbit`: Gets or sets the fastest a particle travels around the emitter, in degrees a second: 0 by default. At least `minOrbit`.
- `stretch`: Gets or sets how far along its motion on screen a particle stretches, as a streak, in seconds of that motion: 0, square, by default.
- `blendMode`: Gets or sets how particles are drawn over what's behind: `BLEND_ALPHA` by default, or another of raylib's blend modes.
- `seed`: Gets or sets the seed of the emitter's random numbers: drawn at its load from raylib's random numbers (`GetRandomValue`'s, which `SetRandomSeed` sets), so emitters differ unless given one. The same seed and fields give the same particles from its load or its clear.

## EmitterColorKey

*class* in [`engines/raylib/src/helix/raylib/extras/EmitterColorKey.hx`](../src/helix/raylib/extras/EmitterColorKey.hx), `import helix.raylib.extras.EmitterColorKey;`

Represents a particle's color at a point of its life.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{at:Float, color:Color}
```

```haxe
var at:Float
var color:Color
```

- `at`: Gets or sets when, 0 at birth to 1 at death.
- `color`: Gets or sets the color then.

## EmitterSizeKey

*class* in [`engines/raylib/src/helix/raylib/extras/EmitterSizeKey.hx`](../src/helix/raylib/extras/EmitterSizeKey.hx), `import helix.raylib.extras.EmitterSizeKey;`

Represents a particle's size at a point of its life.

Written as an object where one is expected; a field marked `?` may be left out, for its default:

```haxe
{at:Float, size:Float}
```

```haxe
var at:Float
var size:Float
```

- `at`: Gets or sets when, 0 at birth to 1 at death.
- `size`: Gets or sets the size then.
