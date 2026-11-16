import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Emitter;
import helix.raylib.extras.Emitter2D;
import helix.raylib.extras.Emitter3D;
import helix.raylib.extras.EmitterShape2D;
import helix.raylib.extras.EmitterShape3D;
import helix.raylib.extras.Particles.*;
import helix.raylib.internal.Emitters;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.services.time.Time;

/** Checks the Particles extra on graphics that count what is live: an emitter's defaults; births by its rate over time, bursts and the
	most alive; a prewarm; a clear restarting from the seed, and a seed giving the same particles; a birth field changing only the
	particles born after it, and a field over a life changing those alive; each field held to its range where read; the size and color
	curves and the palette; the flipbook; a 2D emitter joining the batch of a `DrawTexture` of its texture; one instanced draw a 3D
	emitter; and an unload freeing what the GPU holds. Run by helix.py test on Node and in hxcpp. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.extras.Emitter)
@:access(helix.raylib.extras.Emitter3D)
class ParticlesTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static inline function bits(c:Color):Int
		return cast c;

	static function near(a:Float, b:Float, message:String, within = 1e-6):Void
		check(Math.abs(a - b) <= within, '$message: $a, not $b');

	// The emitter's particles alive, oldest first: each slot's floats then its tint.
	static function alive(e:Emitter):Array<Array<Float>> {
		var out = [], n = e.capacity;
		for (k in 0...e.span) {
			var slot = (e.head - e.span + k + n) % n,
				at = slot * Emitters.SLOT;
			if (e.clock - e.slots[at] >= e.slots[at + 1])
				continue;
			out.push([for (i in 0...Emitters.SLOT) e.slots[at + i]].concat([e.tints[slot]]));
		}
		return out;
	}

	static function same(a:Array<Array<Float>>, b:Array<Array<Float>>):Bool {
		if (a.length != b.length)
			return false;
		for (i in 0...a.length)
			for (k in 0...a[i].length)
				if (a[i][k] != b[i][k])
					return false;
		return true;
	}

	// The frame's sprite records so far, each its 12 floats then its color's four bytes.
	static function records():Array<Array<Float>> {
		var frame = Runtime.frame, out = [];
		for (s in 0...frame.sprites) {
			var at = s * 52;
			out.push([for (i in 0...12) frame.spriteData.getFloat(at + i * 4)].concat([for (i in 0...4) frame.spriteData.get(at + 48 + i)]));
		}
		return out;
	}

	// Draws the frame, so the next draws start a new one.
	static function next():Void
		Runtime.frame.draw(64, 64, true);

	static function run(e:Emitter3D, seconds:Float, step = 0.05):Void
		for (_ in 0...Math.round(seconds / step))
			UpdateEmitter3D(e, step);

	static function run2D(e:Emitter2D, seconds:Float, step = 0.05):Void
		for (_ in 0...Math.round(seconds / step))
			UpdateEmitter2D(e, step);

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		Runtime.system = new FakeSystem();
		Runtime.time = new Time(Runtime.system);
		Runtime.frame.begin(64, 64);

		// The defaults: a small fountain of soft white dots that fade.
		var e = LoadEmitter3D(64);
		check(e.particleCount == 0 && e.rate == 10 && e.minLife == 1 && e.maxLife == 1, "a new emitter: none alive, 10 a second, a second each");
		check(e.spawnRadius == 0 && e.spread == 30 && e.speedVariance == 0 && e.inheritVelocity == 0 && e.drag == 0, "a new emitter's birth fields");
		check(e.wanderDistance == 0 && e.wanderRate == 1 && e.startSize == 0.25 && e.endSize == 0.25 && e.sizeVariance == 0, "a 3D emitter's sizes");
		check(bits(e.startColor) == bits(new Color(255, 255, 255, 255))
			&& bits(e.endColor) == bits(new Color(255, 255, 255, 0)), "white, fading out");
		check(e.sizeKeys.length == 0 && e.colorKeys.length == 0 && e.palette.length == 0 && e.texture == null && e.source == null, "no keys");
		check(e.frameColumns == 1 && e.frameRows == 1 && e.frameCount == 0 && e.framesPerSecond == 0, "no flipbook");
		check(e.minSpin == 0 && e.maxSpin == 0 && e.stretch == 0 && e.blendMode == BLEND_ALPHA && e.seed == 0 && !e.lit, "no spin, alpha");
		check(e.position.x == 0
			&& e.velocity.y == 1
			&& e.gravity.y == 0
			&& e.spawnShape == EmitterShape3D.Point
			&& e.spawnHalfSize.x == 0,
			"at the origin, 1 a second up");
		var flat = LoadEmitter2D(64);
		check(flat.startSize == 16 && flat.endSize == 16 && flat.velocity.x == 0 && flat.velocity.y == -60 && !flat.alignToMotion,
			"a 2D emitter: 16 pixels, 60 a second up the screen");
		check(flat.spawnShape == EmitterShape2D.Point && flat.position.x == 0 && flat.gravity.y == 0, "a 2D emitter's place");

		// Births by the rate over time: 8 a second, each living a second, so 8 alive once a second has passed.
		e.rate = 8;
		run(e, 0.5, 0.0625);
		check(e.particleCount == 4, 'half a second at 8 a second: ${e.particleCount}');
		run(e, 1.5, 0.0625);
		check(e.particleCount == 8, 'the steady state: ${e.particleCount}');
		// An emitter not updated holds still; a time of 0, less, or NaN is no time.
		UpdateEmitter3D(e, 0);
		UpdateEmitter3D(e, -1);
		UpdateEmitter3D(e, Math.NaN);
		check(e.particleCount == 8 && e.clock == 2, 'no time passes: ${e.clock}');
		// Along the way it moved: births spread evenly from where it was to where it is.
		var moving = LoadEmitter3D(16);
		moving.velocity.y = 0;
		moving.rate = 40;
		UpdateEmitter3D(moving, 0.1);
		moving.position.x = 4;
		UpdateEmitter3D(moving, 0.1);
		var xs = [for (p in alive(moving)) p[Emitters.X]];
		check(xs.length == 8 && xs[4] == 1 && xs[5] == 2 && xs[6] == 3 && xs[7] == 4, 'an even trail: $xs');

		// A burst, whatever the rate; the most alive, the oldest giving way.
		var burst = LoadEmitter3D(8);
		burst.rate = 0;
		EmitParticles3D(burst, 3);
		check(burst.particleCount == 3, "a burst of 3");
		EmitParticles3D(burst, 0);
		EmitParticles3D(burst, -2);
		check(burst.particleCount == 3, "a burst of none");
		burst.position.x = 1;
		EmitParticles3D(burst, 20);
		check(burst.particleCount == 8 && alive(burst)[0][Emitters.X] == 1, "8 at most, the newest");
		run(burst, 0.5);
		check(burst.particleCount == 8, "the rate at 0 births none, and those alive live on");
		run(burst, 0.6);
		check(burst.particleCount == 0, "a second on, all dead");

		// A prewarm: already going, as if updated for its longest life.
		var warm = LoadEmitter3D(64);
		PrewarmEmitter3D(warm, 5);
		check(warm.particleCount >= 9 && warm.particleCount <= 10, 'prewarmed: ${warm.particleCount}');
		PrewarmEmitter3D(warm, -1);
		check(warm.particleCount >= 9, "a prewarm of no time");

		// The same seed and fields give the same particles; a clear starts again from the seed.
		var a = LoadEmitter3D(64), b = LoadEmitter3D(64);
		for (x in [a, b]) {
			x.seed = 7;
			x.spread = 90;
			x.speedVariance = 0.5;
			x.minLife = 0.5;
			x.maxLife = 2;
			x.spawnShape = Sphere;
			x.spawnRadius = 2;
			x.minSpin = -90;
			x.maxSpin = 90;
			x.sizeVariance = 0.5;
		}
		run(a, 1);
		run(b, 1);
		var first = alive(a);
		check(first.length > 5 && same(first, alive(b)), "the same seed, the same particles");
		ClearEmitter3D(a);
		check(a.particleCount == 0 && alive(a).length == 0, "a clear takes every particle");
		var clock = a.clock;
		run(a, 1);
		var again = alive(a);
		for (i => p in again) {
			check(i < first.length && Math.abs(p[Emitters.BORN] - clock - first[i][Emitters.BORN]) < 1e-9, "born at the same times again");
			p[Emitters.BORN] = first[i][Emitters.BORN];
		}
		check(same(first, again), "from a clear, the same particles again");
		var c = LoadEmitter3D(64);
		c.seed = 8;
		run(c, 1);
		check(!same(alive(c), first), "another seed, other particles");
		for (p in first) {
			check(p[Emitters.LIFE] >= 0.5 && p[Emitters.LIFE] <= 2, "a life between the shortest and longest");
			check(p[Emitters.SCALE] >= 0.5 && p[Emitters.SCALE] <= 1.5, "a size scale within the variance");
			check(Math.abs(p[Emitters.SPIN]) <= Math.PI / 2 + 1e-9, "a spin within its range, in radians");
			var dx = p[Emitters.X], dy = p[Emitters.Y], dz = p[Emitters.Z];
			check(dx * dx + dy * dy + dz * dz <= 4 + 1e-9, "born in the sphere");
		}

		// A birth field changes the particles born after it; a field over a life changes those alive.
		var later = LoadEmitter2D(16);
		later.rate = 0;
		later.spread = 0;
		EmitParticles2D(later, 2);
		later.velocity.x = 100;
		later.velocity.y = 0;
		EmitParticles2D(later, 2);
		var born = alive(later);
		check(born[0][Emitters.VX] == 0 && born[0][Emitters.VY] == -60 && born[3][Emitters.VX] == 100, "the velocity: the later births'");
		later.gravity.y = 100;
		UpdateEmitter2D(later, 0.1);
		var moved = alive(later);
		near(moved[0][Emitters.VY], -50, "gravity changes those alive");
		near(moved[0][Emitters.Y], -5, "and moves them");
		near(moved[3][Emitters.X], 10, "the later ones along their own velocity");
		later.drag = 1;
		UpdateEmitter2D(later, 0.1);
		near(alive(later)[3][Emitters.VX], 100 / 1.1, "drag slows those alive");

		// Each field held to its range where read.
		var held = LoadEmitter2D(0);
		check(held.capacity == 1, "1 at most alive, at least");
		held.rate = -5;
		run2D(held, 1);
		check(held.particleCount == 0, "a rate under 0 births none");
		var flood = LoadEmitter2D(16);
		flood.rate = Math.POSITIVE_INFINITY;
		UpdateEmitter2D(flood, 0.1);
		check(flood.particleCount == 16
			&& alive(flood)[15][Emitters.BORN] == flood.clock, "a rate past counting fills every slot, the newest last");
		var range = LoadEmitter2D(256);
		range.rate = 0;
		range.minLife = 2;
		range.maxLife = 1;
		range.spread = 400;
		range.speedVariance = 3;
		range.sizeVariance = -1;
		range.inheritVelocity = 5;
		range.drag = -3;
		range.velocity.y = -10;
		EmitParticles2D(range, 200);
		for (p in alive(range)) {
			check(p[Emitters.LIFE] == 2, "a longest life under the shortest is the shortest");
			var speed = Math.sqrt(p[Emitters.VX] * p[Emitters.VX] + p[Emitters.VY] * p[Emitters.VY]);
			check(speed <= 20 + 1e-9, 'a speed variance held to 1: $speed');
			check(p[Emitters.SCALE] == 1, "a size variance held to 0");
		}
		var down = [for (p in alive(range)) if (p[Emitters.VY] > 0) p].length;
		check(down > 50, 'a spread held to 180 throws them every way: $down down');
		var inherit = LoadEmitter2D(8);
		inherit.rate = 0;
		inherit.velocity.y = 0;
		inherit.inheritVelocity = 5;
		UpdateEmitter2D(inherit, 0.5);
		inherit.position.x = 10;
		UpdateEmitter2D(inherit, 0.5);
		EmitParticles2D(inherit, 1);
		near(alive(inherit)[0][Emitters.VX], 20, "an inherited share held to 1");
		var noDrag = LoadEmitter2D(4);
		noDrag.rate = 0;
		noDrag.spread = 0;
		noDrag.drag = -3;
		EmitParticles2D(noDrag, 1);
		UpdateEmitter2D(noDrag, 0.5);
		near(alive(noDrag)[0][Emitters.VY], -60, "a drag under 0 is none");

		// The size and color curves: start, keys, end; past 8 keys ignored.
		var curves = LoadEmitter2D(4);
		curves.startSize = 2;
		curves.endSize = 10;
		curves.sizeKeys = [{at: 0.5, size: 20}];
		curves.startColor = new Color(0, 0, 0, 255);
		curves.endColor = new Color(200, 100, 0, 0);
		curves.colorKeys = [{at: 0.25, color: new Color(100, 100, 100, 255)}];
		Emitters.readCurves(curves);
		near(Emitters.sizeAt(0), 2, "the size at birth");
		near(Emitters.sizeAt(0.25), 11, "between birth and the key");
		near(Emitters.sizeAt(0.5), 20, "at the key");
		near(Emitters.sizeAt(0.75), 15, "between the key and death");
		near(Emitters.sizeAt(1), 10, "at death");
		check(Emitters.colorAt(0.125) == bits(new Color(50, 50, 50, 255)), "a color between birth and the key");
		check(Emitters.colorAt(0.625) == bits(new Color(150, 100, 50, 128)), 'a color between the key and death');
		curves.sizeKeys = [for (i in 0...12) {at: i / 12, size: i}];
		Emitters.readCurves(curves);
		check(Emitters.sizeCount == 10, "8 size keys at most");
		curves.sizeKeys = [{at: 2, size: 5}];
		Emitters.readCurves(curves);
		check(Emitters.sizeTimes[1] == 1, "a key's time held to 0 to 1");
		// The palette: one color picked at birth, 8 at most.
		var tinted = LoadEmitter2D(64);
		tinted.rate = 0;
		tinted.palette = [RED, GREEN];
		EmitParticles2D(tinted, 40);
		var tints = [for (p in alive(tinted)) Std.int(p[Emitters.SLOT])];
		check(tints.indexOf(bits(RED)) >= 0
			&& tints.indexOf(bits(GREEN)) >= 0
			&& [for (t in tints) if (t != bits(RED) && t != bits(GREEN)) t].length == 0,
			"each a palette color");
		tinted.palette = [for (i in 0...12) new Color(i, 0, 0, 255)];
		ClearEmitter2D(tinted);
		EmitParticles2D(tinted, 60);
		check([for (p in alive(tinted)) if ((Std.int(p[Emitters.SLOT]) & 255) >= 8) p].length == 0, "8 palette colors at most");

		// A 2D emitter's draws: the quads of its particles in the batch, in a run with a DrawTexture of its texture.
		next();
		var image = GenImageColor(64, 16, WHITE);
		var sheet = LoadTextureFromImage(image);
		UnloadImage(image);
		var quads = LoadEmitter2D(16);
		quads.rate = 0;
		quads.texture = sheet;
		quads.position = new Vector2(32, 32);
		quads.velocity = new Vector2(0, 0);
		EmitParticles2D(quads, 3);
		DrawTexture(sheet, 0, 0, WHITE);
		DrawEmitter2D(quads);
		var frame = Runtime.frame;
		check(frame.batch.length == 1 && frame.batch[0].mode == Frame.SPRITES && frame.batch[0].count == 4,
			'one run of the texture: ${frame.batch.length} runs');
		var quad = records()[1];
		near(quad[0], 24, "a quad 16 pixels across, at the position");
		near(quad[1], 24, "its top");
		near(quad[4], 40, "its right");
		// The color: startColor at birth, white.
		check(quad[12] == 255 && quad[15] == 255, "white, opaque at birth");
		// Another blend mode is a run of its own, and the blend mode drawn after is the one before.
		quads.blendMode = BLEND_ADDITIVE;
		DrawEmitter2D(quads);
		check(frame.batch.length == 0 && frame.blendMode == BLEND_ALPHA, "a blend mode of its own, flushed");
		next();
		// The flipbook: four frames across a 64 by 16 sheet, played once over the life.
		quads.blendMode = BLEND_ALPHA;
		quads.frameColumns = 4;
		quads.minLife = quads.maxLife = 1;
		ClearEmitter2D(quads);
		EmitParticles2D(quads, 1);
		UpdateEmitter2D(quads, 0.65);
		DrawEmitter2D(quads);
		var cell = records()[0];
		near(cell[8], 0.5, "the third frame's left at 0.65 of the life");
		near(cell[10], 0.75, "its right");
		quads.framesPerSecond = 10;
		next();
		DrawEmitter2D(quads);
		near(records()[0][8], 0.5, "at 10 a second, frame 6 of 4 is the third");
		quads.frameCount = 9;
		quads.framesPerSecond = 0;
		next();
		DrawEmitter2D(quads);
		near(records()[0][8], 0.5, "a frame count past the frames is all of them");
		quads.frameColumns = 0;
		next();
		DrawEmitter2D(quads);
		near(records()[0][10], 1, "no columns are one");
		// Over the life: the end color reaches those alive, and stretch draws a streak along the motion.
		quads.endColor = new Color(255, 0, 0, 255);
		next();
		DrawEmitter2D(quads);
		check(records()[0][13] == 89 && records()[0][12] == 255, "a new end color reaches those alive");
		next();
		var streak = LoadEmitter2D(4);
		streak.rate = 0;
		streak.spread = 0;
		streak.velocity = new Vector2(100, 0);
		streak.stretch = 0.1;
		EmitParticles2D(streak, 1);
		DrawEmitter2D(streak);
		var long = records()[0];
		near(long[4] - long[0], 26, "16 pixels and a tenth of a second of motion long");
		near(long[0], -18, "trailing back from the position");
		next();
		// The part of the texture drawn: its source.
		quads.frameColumns = 1;
		quads.source = new Rectangle(16, 0, 16, 16);
		DrawEmitter2D(quads);
		var sourced = records()[0];
		near(sourced[8], 0.25, "the source's left");
		near(sourced[10], 0.5, "the source's right");
		next();
		// Turned to face its motion: the texture's width along the velocity, down the screen.
		var aligned = LoadEmitter2D(4);
		aligned.rate = 0;
		aligned.spread = 0;
		aligned.velocity = new Vector2(0, 100);
		aligned.alignToMotion = true;
		EmitParticles2D(aligned, 1);
		DrawEmitter2D(aligned);
		var turned = records()[0];
		near(turned[0], 8, "the top left corner turned a quarter clockwise", 1e-9);
		near(turned[1], -8, "its top", 1e-9);
		next();
		// Wandering: from its path, by at most twice the distance, starting on it.
		var wandering = LoadEmitter2D(4);
		wandering.rate = 0;
		wandering.velocity = new Vector2(0, 0);
		wandering.wanderDistance = 10;
		wandering.wanderRate = 2;
		EmitParticles2D(wandering, 1);
		DrawEmitter2D(wandering);
		var start = records()[0];
		near((start[0] + start[4]) / 2, 0, "on its path at birth");
		next();
		UpdateEmitter2D(wandering, 0.3);
		DrawEmitter2D(wandering);
		var strayed = records()[0];
		var sx = (strayed[0] + strayed[4]) / 2,
			sy = (strayed[1] + strayed[5]) / 2;
		check(sx * sx + sy * sy > 0.01 && Math.abs(sx) <= 20 && Math.abs(sy) <= 20, 'strayed off its path: $sx, $sy');
		next();

		// A 3D emitter: one instanced draw, its instances its particles' slots.
		var draws = frame.pass.draws.length;
		var cloud = LoadEmitter3D(32);
		cloud.rate = 0;
		EmitParticles3D(cloud, 12);
		DrawEmitter3D(cloud);
		check(frame.pass.draws.length == draws + 1, "one draw an emitter");
		var draw = frame.pass.draws[frame.pass.draws.length - 1];
		check(draw.instances == 12 && draw.count == 6, 'a quad an instance: ${draw.instances}');
		check(graphics.dataTextures.exists(cloud.records) && cloud.numbers != 0, "its records on the GPU");
		// A field over a life is read by each draw: the gravity drawn is the one set now.
		cloud.gravity.y = -9.8;
		DrawEmitter3D(cloud);
		var p = EmitterDrawsAccess.unlit();
		var fields = EmitterDrawsAccess.fields();
		var place = p.shader.findUniformPlace(fields[3]);
		var bytes:haxe.io.Bytes = frame.pass.draws[frame.pass.draws.length - 1].uniforms[place.blockSlot];
		near(bytes.getFloat(place.offset + 4), -9.8, "the gravity drawn", 1e-5);
		check(frame.depthMask && frame.cull && frame.blendMode == BLEND_ALPHA, "the state after as before");
		// Outside BeginMode3D, through the screen's matrices: the quad's right across the screen, its up up the screen.
		var right = p.shader.findUniformPlace(fields[0]),
			up = p.shader.findUniformPlace(fields[1]);
		check(bytes.getFloat(right.offset) == 1 && bytes.getFloat(up.offset + 4) == -1, "facing the screen, upright");
		near(bytes.getFloat(right.offset + 12), 0, "the oldest particle's slot");
		near(bytes.getFloat(up.offset + 12), 32, "the slots");
		// A lit emitter: through the lit program, lit by the scene's lights once a light is made.
		cloud.lit = true;
		DrawEmitter3D(cloud);
		var lit = EmitterDrawsAccess.lit();
		check(lit != null && frame.pass.draws[frame.pass.draws.length - 1].uniforms != null, "a lit emitter's own program");
		var enabled = lit.shader.findUniform("lights.enabled"),
			at = lit.shader.findUniformPlace(enabled);
		function lightOn():Int
			return frame.pass.draws[frame.pass.draws.length - 1].uniforms[at.blockSlot].getInt32(at.offset);
		check(lightOn() == 0, "no light made, none on");
		helix.raylib.Rlights.CreateLight(helix.raylib.Rlights.LIGHT_POINT, new Vector3(0, 1, 0), new Vector3(0, 0, 0), WHITE, null);
		DrawEmitter3D(cloud);
		check(lightOn() == 1, "a light made lights it");
		cloud.lit = false;
		next();
		// An unload frees the records and numbers once the frame is drawn.
		var textures = Lambda.count(graphics.dataTextures),
			buffers = Lambda.count(graphics.buffers);
		DrawEmitter3D(cloud);
		UnloadEmitter3D(cloud);
		check(cloud.particleCount == 0, "unloaded, none alive");
		next();
		check(Lambda.count(graphics.dataTextures) == textures - 1
			&& Lambda.count(graphics.buffers) == buffers - 1
			&& graphics.doubles == 0,
			"its records and numbers freed");
		var drawn = frame.pass.draws.length;
		DrawEmitter3D(cloud);
		check(frame.pass.draws.length == drawn, "an unloaded emitter draws nothing");
		UnloadEmitter2D(quads);
		check(quads.particleCount == 0, "a 2D emitter unloaded");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}

// The particle programs and the unlit one's uniforms, as EmitterDraws keeps them.

@:access(helix.raylib.internal.EmitterDraws)
private class EmitterDrawsAccess {
	public static function unlit():helix.raylib.internal.Program
		return helix.raylib.internal.EmitterDraws.unlit;

	public static function fields():Array<helix.services.shaders.ShaderUniform>
		return helix.raylib.internal.EmitterDraws.unlitFields;

	public static function lit():helix.raylib.internal.Program
		return helix.raylib.internal.EmitterDraws.lit;
}
