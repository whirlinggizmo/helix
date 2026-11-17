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

	// The hashes of the seeded runs, the same on every target.
	static inline final SEEDED_3D = 127556419;
	static inline final SEEDED_2D = -1673772643;

	// A hash of numbers' bits, by shifts and exclusive ors alone, which every target computes alike.
	static function hashOf(rows:Array<Array<Float>>, h:Int):Int {
		for (row in rows)
			for (x in row) {
				var b = haxe.io.FPHelper.doubleToI64(x);
				h = scramble(h ^ b.low);
				h = scramble(h ^ b.high);
			}
		return h;
	}

	static inline function scramble(h:Int):Int {
		h ^= h << 13;
		h ^= h >>> 17;
		h ^= h << 5;
		return h;
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
		check(!e.spawnShell && e.speed == 1 && e.spread == 30 && e.speedVariance == 0 && e.inheritVelocity == 0 && e.drag == 0, "a new emitter's birth fields");
		check(e.wanderDistance == 0 && e.wanderRate == 1 && e.sizeVariance == 0 && e.pulseRate == 0 && e.pulseDepth == 1, "no wander, no pulse");
		check(e.sizeKeys.length == 2 && e.sizeKeys[0].at == 0 && e.sizeKeys[0].size == 0.25 && e.sizeKeys[1].at == 1 && e.sizeKeys[1].size == 0.25,
			"a 3D emitter's sizes: 0.25 at both ends");
		check(e.colorKeys.length == 2
			&& e.colorKeys[0].at == 0
			&& bits(e.colorKeys[0].color) == bits(new Color(255, 255, 255, 255))
			&& e.colorKeys[1].at == 1
			&& bits(e.colorKeys[1].color) == bits(new Color(255, 255, 255, 0)),
			"white, fading out");
		check(e.palette.length == 0 && e.texture == null && e.source == null, "no palette, the dot");
		check(e.frameColumns == 1 && e.frameRows == 1 && e.frameCount == 0 && e.framesPerSecond == 0, "no flipbook");
		check(e.minSpin == 0 && e.maxSpin == 0 && e.stretch == 0 && e.blendMode == BLEND_ALPHA && !e.lit, "no spin, alpha");
		check(!e.localSpace, "particles left where they were born as the emitter moves");
		// Each load's seed drawn from raylib's random numbers: emitters differ, and SetRandomSeed repeats them.
		SetRandomSeed(41);
		var firstSeed = LoadEmitter3D(1).seed,
			secondSeed = LoadEmitter2D(1).seed;
		SetRandomSeed(41);
		check(firstSeed != secondSeed && LoadEmitter3D(1).seed == firstSeed && LoadEmitter2D(1).seed == secondSeed,
			'a seed drawn at each load, repeated by SetRandomSeed: $firstSeed, then $secondSeed');
		check(e.position.x == 0
			&& e.direction.x == 0
			&& e.direction.y == 1
			&& e.direction.z == 0
			&& e.gravity.y == 0
			&& e.spawnShape == EmitterShape3D.Point
			&& e.spawnHalfSize.x == 0,
			"at the origin, 1 a second up");
		var flat = LoadEmitter2D(64);
		check(flat.sizeKeys[0].size == 16 && flat.sizeKeys[1].size == 16 && flat.direction.x == 0 && flat.direction.y == -1 && flat.speed == 60
			&& !flat.alignToMotion,
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
		moving.speed = 0;
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
			x.spawnShape = Ellipsoid;
			x.spawnHalfSize = new Vector3(2, 2, 2);
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
		later.direction = new Vector2(1, 0);
		later.speed = 100;
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
		range.speed = 10;
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
		inherit.speed = 0;
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

		// The size and color keys: the ends among them, the first's value before it and the last's after; past 8 keys ignored.
		var curves = LoadEmitter2D(4);
		curves.sizeKeys = [{at: 0, size: 2}, {at: 0.5, size: 20}, {at: 1, size: 10}];
		curves.colorKeys = [
			{at: 0, color: new Color(0, 0, 0, 255)},
			{at: 0.25, color: new Color(100, 100, 100, 255)},
			{at: 1, color: new Color(200, 100, 0, 0)}
		];
		Emitters.readCurves(curves, true);
		near(Emitters.sizeAt(0), 2, "the size at birth");
		near(Emitters.sizeAt(0.25), 11, "between birth and the key");
		near(Emitters.sizeAt(0.5), 20, "at the key");
		near(Emitters.sizeAt(0.75), 15, "between the key and death");
		near(Emitters.sizeAt(1), 10, "at death");
		check(Emitters.colorAt(0.125) == bits(new Color(50, 50, 50, 255)), "a color between birth and the key");
		check(Emitters.colorAt(0.625) == bits(new Color(150, 100, 50, 128)), 'a color between the key and death');
		// Keys inside the life: the first's value before it, the last's after.
		curves.sizeKeys = [{at: 0.25, size: 4}, {at: 0.75, size: 8}];
		Emitters.readCurves(curves, true);
		near(Emitters.sizeAt(0), 4, "before the first key, the first's size");
		near(Emitters.sizeAt(0.5), 6, "between the keys");
		near(Emitters.sizeAt(1), 8, "after the last key, the last's size");
		// One key: its value for the whole life.
		curves.sizeKeys = [{at: 0.4, size: 7}];
		curves.colorKeys = [{at: 0.9, color: ORANGE}];
		Emitters.readCurves(curves, true);
		check(Emitters.sizeAt(0) == 7 && Emitters.sizeAt(0.4) == 7 && Emitters.sizeAt(1) == 7, "one size key, one size");
		check(Emitters.colorAt(0) == bits(ORANGE) && Emitters.colorAt(1) == bits(ORANGE), "one color key, one color");
		// No keys: the default's.
		curves.sizeKeys = [];
		curves.colorKeys = [];
		Emitters.readCurves(curves, true);
		check(Emitters.sizeAt(0) == 16 && Emitters.sizeAt(1) == 16, "no size keys, a 2D emitter's 16");
		check(Emitters.colorAt(0) == bits(new Color(255, 255, 255, 255)) && Emitters.colorAt(1) == bits(new Color(255, 255, 255, 0)),
			"no color keys, white fading out");
		Emitters.readCurves(LoadEmitter3D(1), false);
		check(Emitters.sizeAt(0.5) == 0.25, "a 3D emitter's default, 0.25");
		var empty3 = LoadEmitter3D(1);
		empty3.sizeKeys = [];
		Emitters.readCurves(empty3, false);
		check(Emitters.sizeAt(0.5) == 0.25, "no size keys in 3D, 0.25");
		// Keys out of order: read sorted, those of one time in the list's order.
		curves.sizeKeys = [{at: 1, size: 10}, {at: 0.5, size: 20}, {at: 0, size: 2}];
		curves.colorKeys = [{at: 1, color: BLUE}, {at: 0, color: RED}];
		Emitters.readCurves(curves, true);
		near(Emitters.sizeAt(0.25), 11, "out of order, read sorted");
		near(Emitters.sizeAt(0.75), 15, "out of order, read sorted, after the middle");
		check(Emitters.colorAt(0) == bits(RED) && Emitters.colorAt(1) == bits(BLUE), "colors out of order, read sorted");
		curves.sizeKeys = [{at: 0.5, size: 1}, {at: 0.5, size: 3}];
		Emitters.readCurves(curves, true);
		check(Emitters.sizeTimes[0] == 0.5 && Emitters.sizeValues[0] == 1 && Emitters.sizeValues[1] == 3, "keys of one time in the list's order");
		curves.sizeKeys = [for (i in 0...12) {at: i / 12, size: i}];
		Emitters.readCurves(curves, true);
		check(Emitters.sizeCount == 8 && Emitters.sizeAt(1) == 7, "8 size keys at most, the first 8");
		curves.sizeKeys = [{at: 2, size: 5}, {at: -1, size: 1}];
		Emitters.readCurves(curves, true);
		check(Emitters.sizeTimes[0] == 0 && Emitters.sizeTimes[1] == 1, "a key's time held to 0 to 1");
		// Spawn shapes: inside a box and an ellipsoid of the half sizes, or on the surface with spawnShell; a half size of 0 flattens them.
		function shaped(shape:EmitterShape3D, hx:Float, hy:Float, hz:Float, shell:Bool):Array<Array<Float>> {
			var s = LoadEmitter3D(400);
			s.rate = 0;
			s.speed = 0;
			s.seed = 3;
			s.spawnShape = shape;
			s.spawnHalfSize = new Vector3(hx, hy, hz);
			s.spawnShell = shell;
			EmitParticles3D(s, 400);
			return alive(s);
		}
		function shaped2D(shape:EmitterShape2D, hx:Float, hy:Float, shell:Bool):Array<Array<Float>> {
			var s = LoadEmitter2D(400);
			s.rate = 0;
			s.speed = 0;
			s.seed = 3;
			s.spawnShape = shape;
			s.spawnHalfSize = new Vector2(hx, hy);
			s.spawnShell = shell;
			EmitParticles2D(s, 400);
			return alive(s);
		}
		// How far each birth is from an ellipsoid's surface, by its radii: 1 on it.
		function radial(p:Array<Float>, a:Float, b:Float, c:Float):Float {
			var x = p[Emitters.X] / a,
				y = p[Emitters.Y] / b,
				z = c > 0 ? p[Emitters.Z] / c : 0;
			return Math.sqrt(x * x + y * y + z * z);
		}
		var tolerance = 1e-9;
		var inside = shaped(Ellipsoid, 3, 2, 1, false);
		check([for (p in inside) if (radial(p, 3, 2, 1) > 1 + tolerance) p].length == 0, "inside the ellipsoid");
		check([for (p in inside) if (radial(p, 3, 2, 1) < 0.5) p].length > 25, "throughout the ellipsoid");
		var shell = shaped(Ellipsoid, 3, 2, 1, true);
		check([for (p in shell) if (Math.abs(radial(p, 3, 2, 1) - 1) > 1e-6) p].length == 0, "on the ellipsoid's surface");
		// Spread over the surface as it looks, by area: of 400, about 162 where |z| is over 0.7 of its radius, the broad faces, and about 90
		// where |x| is, the narrow ends (the surface's areas there, integrated apart); a sphere's points stretched would give about 120 each.
		var broad = [for (p in shell) if (Math.abs(p[Emitters.Z]) > 0.7) p].length,
			ends = [for (p in shell) if (Math.abs(p[Emitters.X]) > 2.1) p].length;
		check(Math.abs(broad - 162) < 30 && Math.abs(ends - 90) < 30, 'by area over the surface: $broad on the broad faces and $ends on the ends');
		var ring = shaped(Ellipsoid, 3, 0, 2, true);
		check([
			for (p in ring)
				if (p[Emitters.Y] != 0
					|| Math.abs(Math.sqrt(Math.pow(p[Emitters.X] / 3, 2) + Math.pow(p[Emitters.Z] / 2, 2)) - 1) > 1e-6) p
		].length == 0, "an ellipsoid of height 0 with a shell: a ring on the ground");
		var disc = shaped(Ellipsoid, 3, 0, 2, false);
		check([
			for (p in disc)
				if (p[Emitters.Y] != 0 || Math.pow(p[Emitters.X] / 3, 2) + Math.pow(p[Emitters.Z] / 2, 2) > 1 + tolerance) p
		].length == 0 && [
			for (p in disc)
				if (Math.pow(p[Emitters.X] / 3, 2) + Math.pow(p[Emitters.Z] / 2, 2) < 0.25) p
		].length > 50, "an ellipsoid of height 0: a flat ellipse on the ground, filled");
		var line = shaped(Ellipsoid, 2, 0, 0, true);
		check([
			for (p in line)
				if (Math.abs(p[Emitters.X]) != 2 || p[Emitters.Y] != 0 || p[Emitters.Z] != 0) p
		].length == 0, "an ellipsoid of one radius, its ends");
		var surface = shaped(Box, 2, 1, 0.5, true);
		check([
			for (p in surface)
				if (Math.abs(Math.abs(p[Emitters.X]) - 2) > tolerance
					&& Math.abs(Math.abs(p[Emitters.Y]) - 1) > tolerance
					&& Math.abs(Math.abs(p[Emitters.Z]) - 0.5) > tolerance) p
		].length == 0 && [
			for (p in surface)
				if (Math.abs(p[Emitters.X]) > 2 + tolerance
					|| Math.abs(p[Emitters.Y]) > 1 + tolerance
					|| Math.abs(p[Emitters.Z]) > 0.5 + tolerance) p
		].length == 0, "on the box's faces");
		// By area: the 4 x 2 faces (z) hold about 8 / 14 of them.
		var zFaces = [for (p in surface) if (Math.abs(Math.abs(p[Emitters.Z]) - 0.5) <= tolerance) p].length;
		check(zFaces > 180 && zFaces < 280, 'the faces by their area: $zFaces of 400 on the largest');
		var outline = shaped(Box, 2, 0, 1, true);
		check([
			for (p in outline)
				if (p[Emitters.Y] != 0
					|| (Math.abs(Math.abs(p[Emitters.X]) - 2) > tolerance && Math.abs(Math.abs(p[Emitters.Z]) - 1) > tolerance)) p
		].length == 0, "a box of height 0 with a shell: a rectangle's outline");
		var flatBox = shaped(Box, 2, 0, 1, false);
		check([for (p in flatBox) if (p[Emitters.Y] != 0) p].length == 0, "a box of height 0: flat");
		var pointShell = shaped(Point, 2, 2, 2, true);
		check([
			for (p in pointShell)
				if (p[Emitters.X] != 0 || p[Emitters.Y] != 0 || p[Emitters.Z] != 0) p
		].length == 0, "a point ignores the shell");
		var ellipse = shaped2D(Ellipse, 30, 10, true);
		check([
			for (p in ellipse)
				if (Math.abs(Math.sqrt(Math.pow(p[Emitters.X] / 30, 2) + Math.pow(p[Emitters.Y] / 10, 2)) - 1) > 1e-6) p
		].length == 0, "on the ellipse's outline");
		var sides = [for (p in ellipse) if (Math.abs(p[Emitters.Y]) > 7) p].length;
		check(sides > 200, 'spread along the outline as it looks, most on its long sides: $sides of 400');
		var filled = shaped2D(Ellipse, 30, 10, false);
		check([
			for (p in filled)
				if (Math.pow(p[Emitters.X] / 30, 2) + Math.pow(p[Emitters.Y] / 10, 2) > 1 + tolerance) p
		].length == 0, "inside the ellipse");
		var flatEllipse = shaped2D(Ellipse, 30, 0, false);
		check([for (p in flatEllipse) if (p[Emitters.Y] != 0 || Math.abs(p[Emitters.X]) > 30) p].length == 0, "an ellipse of height 0: a line");
		var rectangleOutline = shaped2D(EmitterShape2D.Rectangle, 30, 10, true);
		check([
			for (p in rectangleOutline)
				if (Math.abs(Math.abs(p[Emitters.X]) - 30) > tolerance && Math.abs(Math.abs(p[Emitters.Y]) - 10) > tolerance) p
		].length == 0, "a rectangle's outline");
		var longSides = [
			for (p in rectangleOutline)
				if (Math.abs(Math.abs(p[Emitters.Y]) - 10) <= tolerance) p
		].length;
		check(longSides > 240 && longSides < 360, 'the outline by length: $longSides of 400 on the long sides');

		// The direction: its length ignored; of no length, up.
		var aimed = LoadEmitter3D(4);
		aimed.rate = 0;
		aimed.spread = 0;
		aimed.direction = new Vector3(0, 0, 5);
		aimed.speed = 3;
		EmitParticles3D(aimed, 1);
		aimed.direction = new Vector3(0, 0, 0);
		EmitParticles3D(aimed, 1);
		var thrown = alive(aimed);
		near(thrown[0][Emitters.VZ], 3, "the direction's length ignored: speed 3 along it");
		check(thrown[1][Emitters.VY] == 3 && thrown[1][Emitters.VX] == 0, "a direction of no length is up");
		var aimed2 = LoadEmitter2D(4);
		aimed2.rate = 0;
		aimed2.spread = 0;
		aimed2.direction = new Vector2(0, 0);
		EmitParticles2D(aimed2, 1);
		near(alive(aimed2)[0][Emitters.VY], -60, "in 2D, up the screen at 60");
		aimed2.speed = -5;
		EmitParticles2D(aimed2, 1);
		check(alive(aimed2)[1][Emitters.VY] == 0, "a speed under 0 is 0");

		// The orbit: a 3D particle keeps where the emitter was at its birth, its orbit and the axis, the direction, for the GPU to turn.
		var whirl = LoadEmitter3D(8);
		whirl.rate = 0;
		whirl.speed = 0;
		whirl.position = new Vector3(5, 0, 0);
		whirl.spawnShape = Box;
		whirl.spawnHalfSize = new Vector3(2, 0, 0);
		whirl.spawnShell = true;
		whirl.direction = new Vector3(0, 0, 4);
		whirl.minOrbit = 90;
		whirl.maxOrbit = 30;
		EmitParticles3D(whirl, 1);
		var w = alive(whirl)[0];
		check(w[Emitters.CX] == 5 && w[Emitters.CY] == 0 && w[Emitters.CZ] == 0 && Math.abs(w[Emitters.X] - 5) == 2, "where the emitter was, kept");
		near(w[Emitters.ORBIT], Math.PI / 2, "a fastest orbit under the slowest is the slowest, in radians a second");
		check(w[Emitters.AX] == 0 && w[Emitters.AY] == 0 && w[Emitters.AZ] == 1, "the axis, the direction");
		// A 2D particle: a quarter turn a second, clockwise on screen, about where the emitter was at its birth.
		var vortex = LoadEmitter2D(8);
		vortex.rate = 0;
		vortex.speed = 0;
		vortex.position = new Vector2(100, 100);
		vortex.spawnShape = EmitterShape2D.Rectangle;
		vortex.spawnHalfSize = new Vector2(40, 0);
		vortex.spawnShell = true;
		vortex.minOrbit = vortex.maxOrbit = 90;
		vortex.minLife = vortex.maxLife = 2;
		EmitParticles2D(vortex, 1);
		var born = alive(vortex)[0][Emitters.X] - 100;
		vortex.position = new Vector2(500, 500);
		UpdateEmitter2D(vortex, 1);
		DrawEmitter2D(vortex);
		var turned = records()[0];
		var cx = (turned[0] + turned[4]) / 2, cy = (turned[1] + turned[5]) / 2;
		near(cx, 100, "a quarter turn on: across, over where the emitter was", 1e-4);
		near(cy, 100 + born, "and down by its offset: clockwise on screen", 1e-4);
		next();
		near(Emitters.orbited(1, 0, Math.PI / 2, 0), -1, "a quarter turn from across: back across");
		near(Emitters.orbited(1, 0, Math.PI / 2, 1), 1, "and down, clockwise on screen");
		// A particle born at the emitter and thrown outward spirals: its whole path turns.
		var spiral = LoadEmitter2D(8);
		spiral.rate = 0;
		spiral.position = new Vector2(100, 100);
		spiral.direction = new Vector2(1, 0);
		spiral.spread = 0;
		spiral.minOrbit = spiral.maxOrbit = 90;
		spiral.minLife = spiral.maxLife = 2;
		EmitParticles2D(spiral, 1);
		UpdateEmitter2D(spiral, 1);
		DrawEmitter2D(spiral);
		var thrown = records()[0];
		near((thrown[0] + thrown[4]) / 2, 100, "thrown 60 across and a quarter turn on: over the emitter", 1e-4);
		near((thrown[1] + thrown[5]) / 2, 160, "and 60 down", 1e-4);
		next();
		// Local space: every particle alive moves with the emitter, and none is thrown along by its motion.
		var aura = LoadEmitter2D(8);
		aura.rate = 0;
		aura.speed = 0;
		aura.localSpace = true;
		aura.inheritVelocity = 1;
		aura.minLife = aura.maxLife = 5;
		aura.position = new Vector2(100, 100);
		UpdateEmitter2D(aura, 0.5);
		EmitParticles2D(aura, 1);
		aura.position = new Vector2(300, 140);
		UpdateEmitter2D(aura, 0.5);
		check(alive(aura)[0][Emitters.VX] == 0 && alive(aura)[0][Emitters.VY] == 0, "in local space, not thrown along by the emitter's motion");
		DrawEmitter2D(aura);
		var carried = records()[0];
		near((carried[0] + carried[4]) / 2, 300, "in local space, carried across with the emitter", 1e-4);
		near((carried[1] + carried[5]) / 2, 140, "and down", 1e-4);
		next();
		aura.localSpace = false;
		DrawEmitter2D(aura);
		var left = records()[0];
		near((left[0] + left[4]) / 2, 100, "in world space, left where it was born", 1e-4);
		next();

		// The pulse: each particle on a phase of its own, from the seed.
		var pulsing = LoadEmitter3D(64), again = LoadEmitter3D(64);
		for (p in [pulsing, again]) {
			p.rate = 0;
			p.seed = 11;
			p.pulseRate = 2;
			p.pulseDepth = 0.5;
			EmitParticles3D(p, 20);
		}
		var phases = [for (p in alive(pulsing)) p[Emitters.PHASE]];
		var distinct = [for (x in phases) if (phases.indexOf(x) == phases.lastIndexOf(x)) x].length;
		check(distinct == 20, 'a phase each: $distinct of 20 apart');
		check(same(alive(pulsing), alive(again)), "the same phases from the same seed");
		var beat = Emitters.pulseAt(pulsing, 0.25, 0),
			low = Emitters.pulseAt(pulsing, 0.75, 0);
		near(beat, 0.5, "at the beat's low point, the alpha down by the depth");
		near(low, 1, "at its high point, all of it");
		near(Emitters.pulseAt(pulsing, 0.25, 0.5), 0.5, "a beat later, the same");
		pulsing.pulseDepth = 3;
		near(Emitters.pulseAt(pulsing, 0.25, 0), 0, "a depth held to 1");
		pulsing.pulseRate = 0;
		near(Emitters.pulseAt(pulsing, 0.25, 0), 1, "no beat at a rate of 0");

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

		// The same seed gives the same particles on every target: hashes of a seeded run's births and particles, written here, the same on
		// Node and in hxcpp. The fields reach every random number and every transcendental of the simulation.
		var seeded3 = LoadEmitter3D(256);
		seeded3.seed = 1234;
		seeded3.spawnShape = Ellipsoid;
		seeded3.spawnHalfSize = new Vector3(1.5, 0.7, 1.1);
		seeded3.spread = 60;
		seeded3.direction = new Vector3(0.3, 2, -0.4);
		seeded3.speed = 2.1;
		seeded3.pulseRate = 2;
		seeded3.minOrbit = -45;
		seeded3.maxOrbit = 300;
		seeded3.speedVariance = 0.4;
		seeded3.sizeVariance = 0.3;
		seeded3.minLife = 0.5;
		seeded3.maxLife = 2;
		seeded3.minSpin = -120;
		seeded3.maxSpin = 200;
		seeded3.inheritVelocity = 0.5;
		seeded3.palette = [RED, GREEN, BLUE];
		seeded3.rate = 37;
		for (i in 0...30) {
			seeded3.position.x = i * 0.1;
			UpdateEmitter3D(seeded3, 1 / 60);
		}
		EmitParticles3D(seeded3, 9);
		var boxed = LoadEmitter3D(64);
		boxed.seed = 99;
		boxed.spawnShape = Box;
		boxed.spawnHalfSize = new Vector3(1, 2, 3);
		boxed.spread = 180;
		EmitParticles3D(boxed, 20);
		var hash3 = hashOf(alive(seeded3), hashOf(alive(boxed), 17));
		check(hash3 == SEEDED_3D, 'a seeded 3D emitter\'s births: hash $hash3, not $SEEDED_3D');
		var seeded2 = LoadEmitter2D(256);
		seeded2.seed = 4321;
		seeded2.spawnShape = Ellipse;
		seeded2.spawnHalfSize = new Vector2(20, 12);
		seeded2.spawnShell = true;
		seeded2.pulseRate = 1.5;
		seeded2.pulseDepth = 0.6;
		seeded2.minOrbit = 30;
		seeded2.maxOrbit = 200;
		seeded2.spread = 75;
		seeded2.speedVariance = 0.5;
		seeded2.sizeVariance = 0.25;
		seeded2.drag = 0.7;
		seeded2.wanderDistance = 6;
		seeded2.wanderRate = 1.3;
		seeded2.minSpin = -90;
		seeded2.maxSpin = 270;
		seeded2.gravity = new Vector2(10, 120);
		seeded2.inheritVelocity = 0.3;
		seeded2.palette = [ORANGE, SKYBLUE];
		seeded2.minLife = 0.4;
		seeded2.maxLife = 1.5;
		seeded2.sizeKeys = [{at: 1, size: 12}, {at: 0, size: 4}, {at: 0.3, size: 9}];
		seeded2.colorKeys = [
			{at: 0.6, color: new Color(30, 200, 90, 180)},
			{at: 0, color: WHITE},
			{at: 1, color: new Color(255, 0, 0, 0)}
		];
		seeded2.rate = 53;
		for (i in 0...40) {
			seeded2.position.y = 100 + i * 2;
			UpdateEmitter2D(seeded2, 1 / 60);
		}
		EmitParticles2D(seeded2, 7);
		var rectangle = LoadEmitter2D(64);
		rectangle.seed = 5;
		rectangle.spawnShape = EmitterShape2D.Rectangle;
		rectangle.spawnHalfSize = new Vector2(30, 10);
		EmitParticles2D(rectangle, 20);
		// Each particle's simulation, then where it's drawn, how big and its color: its wander, size and color curves at its age.
		Emitters.readCurves(seeded2, true);
		var drawn2:Array<Array<Float>> = [];
		for (p in alive(seeded2)) {
			var age = seeded2.clock - p[Emitters.BORN],
				t = age / p[Emitters.LIFE];
			var turn = 6.283185307179586 * seeded2.wanderRate * age;
			drawn2.push(p.concat([
				p[Emitters.X] + seeded2.wanderDistance * Emitters.wander(p[Emitters.RANDOM], 0, turn),
				p[Emitters.Y] + seeded2.wanderDistance * Emitters.wander(p[Emitters.RANDOM], 1, turn),
				Emitters.sizeAt(t) * p[Emitters.SCALE],
				Emitters.colorAt(t),
				Emitters.pulseAt(seeded2, p[Emitters.PHASE], age),
				Emitters.orbited(p[Emitters.X] - p[Emitters.CX], p[Emitters.Y] - p[Emitters.CY], p[Emitters.ORBIT] * age, 0),
				Emitters.orbited(p[Emitters.X] - p[Emitters.CX], p[Emitters.Y] - p[Emitters.CY], p[Emitters.ORBIT] * age, 1),
				p[Emitters.SPIN] * age
			]));
		}
		var hash2 = hashOf(drawn2, hashOf(alive(rectangle), 17));
		check(hash2 == SEEDED_2D, 'a seeded 2D emitter\'s particles: hash $hash2, not $SEEDED_2D');

		// A 2D emitter's draws: the quads of its particles in the batch, in a run with a DrawTexture of its texture.
		next();
		var image = GenImageColor(64, 16, WHITE);
		var sheet = LoadTextureFromImage(image);
		UnloadImage(image);
		var quads = LoadEmitter2D(16);
		quads.rate = 0;
		quads.texture = sheet;
		quads.position = new Vector2(32, 32);
		quads.speed = 0;
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
		// The color: the first color key's at birth, white.
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
		quads.colorKeys = [{at: 0, color: WHITE}, {at: 1, color: new Color(255, 0, 0, 255)}];
		next();
		DrawEmitter2D(quads);
		check(records()[0][13] == 89 && records()[0][12] == 255, "a new end color reaches those alive");
		next();
		var streak = LoadEmitter2D(4);
		streak.rate = 0;
		streak.spread = 0;
		streak.direction = new Vector2(1, 0);
		streak.speed = 100;
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
		aligned.direction = new Vector2(0, 1);
		aligned.speed = 100;
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
		wandering.speed = 0;
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
		// With no light, the particle's color times the ambient, a dim grey by default; another ambient reaches the next draw.
		var ambient = lit.shader.findUniform("ambient"),
			ambientAt = lit.shader.findUniformPlace(ambient);
		function drawnAmbient(component:Int):Float
			return frame.pass.draws[frame.pass.draws.length - 1].uniforms[ambientAt.blockSlot].getFloat(ambientAt.offset + component * 4);
		check(bits(cloud.ambient) == bits(new Color(26, 26, 26, 255)), "a dim grey ambient by default");
		near(drawnAmbient(0), 26 / 255, "the ambient drawn", 1e-6);
		cloud.ambient = new Color(255, 128, 0, 7);
		DrawEmitter3D(cloud);
		near(drawnAmbient(0), 1, "a new ambient drawn: red", 1e-6);
		near(drawnAmbient(1), 128 / 255, "green", 1e-6);
		near(drawnAmbient(2), 0, "blue", 1e-6);
		near(drawnAmbient(3), 1, "its alpha ignored", 1e-6);
		cloud.ambient = new Color(26, 26, 26, 255);
		helix.raylib.extras.Lighting.CreateLight(helix.raylib.extras.Lighting.LIGHT_POINT, new Vector3(0, 1, 0), new Vector3(0, 0, 0), WHITE, null);
		DrawEmitter3D(cloud);
		check(lightOn() == 1, "a light made lights it");
		cloud.lit = false;
		next();
		// In stereo, as DrawCube: once an eye; once with stereo off.
		helix.raylib.Rlgl.rlSetFramebufferWidth(64);
		helix.raylib.Rlgl.rlSetFramebufferHeight(64);
		helix.raylib.Rlgl.rlEnableStereoRender();
		var before = frame.pass.draws.length;
		DrawEmitter3D(cloud);
		check(frame.pass.draws.length == before + 2, 'once an eye in stereo: ${frame.pass.draws.length - before}');
		helix.raylib.Rlgl.rlDisableStereoRender();
		before = frame.pass.draws.length;
		DrawEmitter3D(cloud);
		check(frame.pass.draws.length == before + 1, "once with stereo off");
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
