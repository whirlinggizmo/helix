# helix.particles

[Back to the index](README.md)

## Emitter

*class* in `src/helix/particles/Emitter.hx`

A particle emitter, after wgrender-c's: many particles from one texture, each decided when it's born (where, how fast, how long it lives, how big, how it spins, within the ranges set here) and never touched again: the GPU works out where it is from its age (gravity and drag move it; its size and color follow their curves over its life). Spawning is all the CPU does, so thousands cost about what spawning them does. A node places it on a stage (Node.emitter, Node2D.emitter), which advances it by the stage's clock each draw; particles stay where they were born when it moves (trails), face the camera, and aren't sorted among themselves. Its random numbers are its own (setSeed): the same seed and settings give the same particles. Colors are 0xRRGGBBAA, sRGB values, as sprites' are.

```haxe
function new(texture:Null<Texture2D>, ?maxParticles:Int = 1024, ?flat:Bool = false)
function getTexture():Null<Texture2D>
function setTexture(value:Null<Texture2D>):Void
function getMaxParticles():Int
function getRegionX():Float
function getRegionY():Float
function getRegionWidth():Float
function getRegionHeight():Float
function setRegion(x:Float, y:Float, width:Float, height:Float):Void
function getFrameColumns():Int
function getFrameRows():Int
function getFrameCount():Int
function getFramesPerSecond():Float
function setFrames(columns:Int, rows:Int, ?frameCount:Int = 0, ?perSecond:Float = 0.):Bool
function getRate():Float
function setRate(perSecond:Float):Bool
function isEmitting():Bool
function setEmitting(value:Bool):Void
function getMinLife():Float
function getMaxLife():Float
function setLife(min:Float, max:Float):Bool
function getSpawnHalfX():Float
function getSpawnHalfY():Float
function getSpawnHalfZ():Float
function setSpawnBox(halfX:Float, halfY:Float, halfZ:Float):Void
function getSpawnRadius():Float
function setSpawnSphere(radius:Float):Bool
function getVelocityX():Float
function getVelocityY():Float
function getVelocityZ():Float
function getSpread():Float
function getSpeedVariance():Float
function setVelocity(x:Float, y:Float, z:Float, ?spread:Float = 0., ?variance:Float = 0.):Bool
function getGravityX():Float
function getGravityY():Float
function getGravityZ():Float
function setGravity(x:Float, y:Float, z:Float):Void
function getDrag():Float
function setDrag(perSecond:Float):Bool
function getInheritVelocity():Float
function setInheritVelocity(fraction:Float):Void
function getSizeVariance():Float
function getSizeKeyCount():Int
function getSizeKeyTime(index:Int):Float
function getSizeKeySize(index:Int):Float
function setSize(start:Float, end:Float, ?variance:Float = 0.):Bool
function clearSizeKeys():Void
function addSizeKey(t:Float, size:Float):Bool
function getColorKeyCount():Int
function getColorKeyTime(index:Int):Float
function getColorKeyColor(index:Int):Int
function setColor(start:Int, end:Int):Void
function clearColorKeys():Void
function addColorKey(t:Float, color:Int):Bool
function getPaletteColorCount():Int
function getPaletteColor(index:Int):Int
function addPaletteColor(color:Int):Bool
function clearPalette():Void
function getMinSpin():Float
function getMaxSpin():Float
function setSpin(min:Float, max:Float):Bool
function getStretch():Float
function setStretch(seconds:Float):Bool
function getAlphaCutoff():Float
function setAlphaMode(mode:SpriteAlpha, ?cutoff:Float = .5):Bool
function getAlphaMode():SpriteAlpha
function getSeed():Int
function setSeed(seed:Int):Void
function getParticleCount():Int
function clear():Void
function burst(count:Int):Bool
function prewarm(seconds:Float):Void
function jump(x:Float, y:Float, z:Float):Void
function advance(dt:Float, x:Float, y:Float, z:Float):Void
function writeRecords(out:haxe.io.Bytes, at:Int):Int
function isDrawable():Bool
function writeUniforms(out:haxe.io.Bytes, viewProjection:Mat4, axisX:Array<Float>, axisY:Array<Float>):Void
```

- `new`: An emitter of particles drawn from texture (null for none yet: it draws nothing), at most maxParticles alive at once (newer replace the oldest; clamped to 1..65536), flat for a 2D stage (its particles in the x-y plane, a sphere a circle). By default: no steady rate (bursts only), a life of 1 second, born at a point, moving up at 1 unit a second, size 1, white, added.
- `getTexture`: Its texture, or null.
- `setTexture`: Sets its texture (null: it draws nothing).
- `getMaxParticles`: The most particles alive at once.
- `getRegionX`: The region's left, in texels.
- `getRegionY`: The region's top, in texels.
- `getRegionWidth`: The region's width in texels (0 or less: the whole texture).
- `getRegionHeight`: The region's height in texels (0 or less: the whole texture).
- `setRegion`: The region of the texture each particle shows, in texels from its top-left (an atlas cell); a width or height of 0 or less (the default) is the whole texture.
- `getFrameColumns`: The flipbook's columns (1: none).
- `getFrameRows`: The flipbook's rows (1: none).
- `getFrameCount`: The flipbook frames used.
- `getFramesPerSecond`: The flipbook frames a second (0: once over a life).
- `setFrames`: A flipbook: the region split into columns x rows frames (left to right, top to bottom), of which the first frameCount are used (0 or less, or more than there are: all). With perSecond 0 each particle plays them once over its life (puffs, explosions); above 0 it loops at that rate from a random frame (flames). False for columns or rows below 1.
- `getRate`: Its steady rate, particles a second.
- `setRate`: Its steady rate, particles a second (0: bursts only). False below 0.
- `isEmitting`: Whether the steady rate runs.
- `setEmitting`: Starts or stops the steady rate; the particles alive finish their lives.
- `getMinLife`: The shortest life, seconds.
- `getMaxLife`: The longest life, seconds.
- `setLife`: Each particle's life, seconds, between min and max. False unless 0 < min <= max.
- `getSpawnHalfX`: The spawn box's half size along x (0 with a sphere set).
- `getSpawnHalfY`: The spawn box's half size along y.
- `getSpawnHalfZ`: The spawn box's half size along z.
- `setSpawnBox`: Born anywhere in a box of these half sizes around its position (a point by default); a half size's sign is ignored (the same box).
- `getSpawnRadius`: The spawn sphere's radius (0: born in the box).
- `setSpawnSphere`: Born evenly within a sphere (a circle, flat) of radius around its position. False below 0.
- `getVelocityX`: The velocity's x, units a second.
- `getVelocityY`: The velocity's y, units a second.
- `getVelocityZ`: The velocity's z, units a second (0 when flat).
- `getSpread`: How far a particle may turn off the velocity, radians.
- `getSpeedVariance`: How much faster or slower a particle may be, 0..1 of the speed.
- `setVelocity`: Moving along x, y, z at its length's speed, turned up to spread radians off it (a cone; flat, a fan; its sign is ignored, the same cone), faster or slower by up to variance (0..1) of it. False, changing nothing, for a variance outside 0..1.
- `getGravityX`: Gravity's x, units a second squared.
- `getGravityY`: Gravity's y, units a second squared.
- `getGravityZ`: Gravity's z, units a second squared (0 when flat).
- `setGravity`: An acceleration on every particle, units a second squared (none by default).
- `getDrag`: Its drag, a second.
- `setDrag`: Slowing in proportion to speed, a second (1 loses about 63% of the speed in a second, less gravity's pull; gravity / drag is how fast they end up falling). False below 0.
- `getInheritVelocity`: The fraction of its own movement particles take at birth.
- `setInheritVelocity`: The fraction of its own movement (where its node went over the last advance) particles take at birth: 1 carries them along with it.
- `getSizeVariance`: How much each particle's size may be scaled, 0..1.
- `getSizeKeyCount`: The size keys.
- `getSizeKeyTime`: Size key index's time, 0..1 of a life (0 for an index out of range).
- `getSizeKeySize`: Size key index's size, world units (0 for an index out of range).
- `setSize`: Size over life, world units: start at birth to end at death, each particle's scaled by up to variance (0..1). Replaces the size keys. False, changing nothing, for a variance outside 0..1.
- `clearSizeKeys`: Clears the size keys (a curve without keys draws nothing until one is added).
- `addSizeKey`: Adds a size key at t (0..1 of a life), in order: between keys the size moves in a line; before the first and after the last it holds. False past 8 keys, or for a t before the last key's or outside 0..1.
- `getColorKeyCount`: The color keys.
- `getColorKeyTime`: Color key index's time, 0..1 of a life (0 for an index out of range).
- `getColorKeyColor`: Color key index's color, 0xRRGGBBAA (0 for an index out of range).
- `setColor`: Color over life (alpha included, so a fade): start at birth to end at death. Replaces the color keys.
- `clearColorKeys`: Clears the color keys.
- `addColorKey`: Adds a color key at t, as addSizeKey.
- `getPaletteColorCount`: The palette colors.
- `getPaletteColor`: Palette color index, 0xRRGGBBAA (0 for an index out of range).
- `addPaletteColor`: Adds a palette color (at most 8): each particle picks one at birth, tinting its color over life (confetti from one emitter). False past 8.
- `clearPalette`: Clears the palette: no tint.
- `getMinSpin`: The slowest spin, radians a second.
- `getMaxSpin`: The fastest spin, radians a second.
- `setSpin`: Spin, radians a second between min and max (positive clockwise on screen), from a random angle. None by default. False, changing nothing, unless min <= max.
- `getStretch`: How long the stretch is, seconds of movement (0: off).
- `setStretch`: Stretched along the motion (sparks, rain): each particle's texture points its top along its velocity across the screen, as long as the distance it moves in seconds (plus its size); stretched ones don't spin. 0 (the default) is off. False, changing nothing, below 0.
- `getAlphaCutoff`: A Mask's alpha cutoff, 0..1.
- `setAlphaMode`: How it uses its texels' alpha (Add by default: glows, sparks, fire), and a Mask's cutoff. False for a cutoff outside 0..1.
- `getAlphaMode`: How it uses its texels' alpha.
- `getSeed`: The seed it was last given (or its own, unseeded).
- `setSeed`: Where its random numbers start: the same seed and settings give the same particles. 0 is taken as 1 (the generator needs a seed other than 0).
- `getParticleCount`: Particles that may still be alive.
- `clear`: All of them gone.
- `burst`: Bursts count particles at once, where it is now. False below 0.
- `prewarm`: Starts over as if the steady rate had run for seconds: those it would have made and still alive now are made where it is.
- `jump`: Puts it at x, y, z without a move: nothing spawns along the way, and particles inherit no velocity from it.
- `advance`: Advances its clock by dt seconds, it being at x, y, z now (its node's world position): the steady rate's particles due are born along the way it moved, and the dead are let go. A stage calls this each draw.
- `writeRecords`: Copies the particles that may still be alive, oldest first, into out at byte at (48 bytes each); how many.
- `isDrawable`: Whether it draws: a texture, particles alive, and a size and color key each.
- `writeUniforms`: Writes its draw's uniforms (the particle program's block) into out: viewProjection, the quad's axes before spin (3D: the camera's right and up; 2D: across and up the screen), and its settings, its clock now.
