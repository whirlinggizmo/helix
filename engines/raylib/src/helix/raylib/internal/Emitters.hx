package helix.raylib.internal;

import helix.math.Trig;
import helix.raylib.Color;
import helix.raylib.extras.Emitter;
import helix.raylib.extras.Emitter2D;
import helix.raylib.extras.Emitter3D;

/** Runs the Particles extra's emitters on the CPU: births (where, how fast, how long each lives, within the emitter's fields), and a 2D
	emitter's motion and its quads in the frame's batch. A 3D emitter's particles are drawn from their births by `EmitterDraws`.

	Births draw from the emitter's own random numbers and take their trigonometry from `Trig`, so a seed gives the same particles on
	every target. Linked by the Particles extra's calls alone. */
@:noCompletion
@:access(helix.raylib.extras.Emitter)
@:access(helix.raylib.extras.Emitter2D)
@:access(helix.raylib.extras.Emitter3D)
class Emitters {
	/** The floats of a particle's slot, and where each is in it. */
	public static inline final SLOT = 19;

	public static inline final BORN = 0;
	public static inline final LIFE = 1;
	public static inline final X = 2;
	public static inline final Y = 3;
	public static inline final Z = 4;
	public static inline final VX = 5;
	public static inline final VY = 6;
	public static inline final VZ = 7;
	public static inline final SCALE = 8;
	public static inline final SPIN = 9;
	public static inline final RANDOM = 10;
	public static inline final PHASE = 11;
	public static inline final CX = 12;
	public static inline final CY = 13;
	public static inline final CZ = 14;
	public static inline final ORBIT = 15;
	public static inline final AX = 16;
	public static inline final AY = 17;
	public static inline final AZ = 18;

	/** The most keys and palette colors read. */
	public static inline final MAX_KEYS = 8;

	/** The steps a second a prewarm runs in, and the most it runs. */
	static inline final PREWARM_RATE = 30;

	static inline final MAX_PREWARM_STEPS = 1000;

	static inline final TAU = 6.283185307179586;
	static inline final DEGREES = 0.017453292519943295;

	/** Advances an emitter by a time, at a position now: the births its rate owes, along the way from where it was, each at the time it
		passed there; a 2D emitter's particles moved; and the dead let go.

		@param e  The emitter.
		@param dt  The seconds since its last update; none for 0, less, or NaN.
		@param x  Its position now.
		@param y  Its position now.
		@param z  Its position now, 0 for a 2D emitter.
		@param flat  Whether it is a 2D emitter. */
	public static function update(e:Emitter, dt:Float, x:Float, y:Float, z:Float, flat:Bool):Void {
		if (!(dt > 0))
			return;
		if (!e.placed) {
			e.placed = true;
			e.lastX = x;
			e.lastY = y;
			e.lastZ = z;
		}
		var fromX = e.lastX, fromY = e.lastY, fromZ = e.lastZ, start = e.clock;
		e.moveX = (x - fromX) / dt;
		e.moveY = (y - fromY) / dt;
		e.moveZ = (z - fromZ) / dt;
		var rate = e.rate > 0 ? e.rate : 0.;
		// More births than a billion an update are a billion, as all but the newest are skipped anyway.
		var births = rate * dt;
		e.owed += births < 1e9 ? births : 1e9;
		var owed = Math.ffloor(e.owed);
		e.owed -= owed;
		// Past the most alive, only the newest live: the births before them are skipped.
		var n = owed > e.capacity ? e.capacity : Std.int(owed);
		var skipped = owed - n;
		for (i in 0...n) {
			var along = (skipped + i + 1) / owed;
			birth(e, start + dt * along, fromX + (x - fromX) * along, fromY + (y - fromY) * along, fromZ + (z - fromZ) * along, flat);
		}
		e.clock = start + dt;
		e.lastX = x;
		e.lastY = y;
		e.lastZ = z;
		if (flat)
			move(cast e, dt);
		settle(e);
	}

	/** Gives off particles at once at a position, at the emitter's time now.

		@param e  The emitter.
		@param count  How many; none for 0 or less.
		@param x  The position.
		@param y  The position.
		@param z  The position, 0 for a 2D emitter.
		@param flat  Whether it is a 2D emitter. */
	public static function emit(e:Emitter, count:Int, x:Float, y:Float, z:Float, flat:Bool):Void {
		if (count <= 0)
			return;
		var n = count > e.capacity ? e.capacity : count;
		for (_ in 0...n)
			birth(e, e.clock, x, y, z, flat);
		settle(e);
	}

	/** Runs an emitter ahead in time at a position, in steps of a thirtieth of a second at most: no further than its longest life, as the
		particles born before that are dead.

		@param e  The emitter.
		@param seconds  How far ahead; none for 0, less, or NaN.
		@param x  The position.
		@param y  The position.
		@param z  The position, 0 for a 2D emitter.
		@param flat  Whether it is a 2D emitter. */
	public static function prewarm(e:Emitter, seconds:Float, x:Float, y:Float, z:Float, flat:Bool):Void {
		var longest = longestLife(e);
		if (seconds > longest)
			seconds = longest;
		if (!(seconds > 0))
			return;
		var steps = Math.ceil(seconds * PREWARM_RATE);
		if (steps > MAX_PREWARM_STEPS)
			steps = MAX_PREWARM_STEPS;
		for (_ in 0...steps)
			update(e, seconds / steps, x, y, z, flat);
	}

	/** Takes away every particle, and starts the emitter's random numbers again from its seed at the next birth.

		@param e  The emitter. */
	public static function clear(e:Emitter):Void {
		e.head = 0;
		e.span = 0;
		e.owed = 0;
		e.particleCount = 0;
		e.placed = false;
		e.seeded = false;
		e.moveX = e.moveY = e.moveZ = 0;
		e.fresh = e.capacity;
	}

	// The longest a particle lives, its maxLife at least its minLife, 0 or more.
	static function longestLife(e:Emitter):Float {
		var low = e.minLife > 0 ? e.minLife : 0.;
		return e.maxLife > low ? e.maxLife : low;
	}

	// Lets the oldest go while they're dead, and counts those alive.
	static function settle(e:Emitter):Void {
		var s = e.slots, n = e.capacity;
		while (e.span > 0) {
			var at = ((e.head - e.span + n) % n) * SLOT;
			if (e.clock - s[at + BORN] < s[at + LIFE])
				break;
			e.span--;
		}
		var alive = 0;
		for (k in 0...e.span) {
			var at = ((e.head - e.span + k + n) % n) * SLOT;
			if (e.clock - s[at + BORN] < s[at + LIFE])
				alive++;
		}
		e.particleCount = alive;
	}

	// The next random number from 0 up to 1, the emitter's random numbers started from its seed at the first after its load or clear.
	static inline function next(e:Emitter):Float {
		if (!e.seeded) {
			e.seeded = true;
			e.random.seed = e.seed;
		}
		return e.random.nextFloat();
	}

	// A number from -1 up to 1.
	static inline function signed(e:Emitter):Float
		return next(e) * 2 - 1;

	static inline function clamp(x:Float, low:Float, high:Float):Float
		return x > low ? (x < high ? x : high) : low;

	// A particle born at a time and place, in the slot after the newest, the oldest's when every slot is taken; its offset, velocity,
	// life, size, spin, phase and tint from the emitter's birth fields.
	static function birth(e:Emitter, when:Float, x:Float, y:Float, z:Float, flat:Bool):Void {
		var e3:Null<Emitter3D> = flat ? null : cast e;
		var e2:Null<Emitter2D> = flat ? cast e : null;
		// Where around the position.
		var shape:Int = flat ? cast e2.spawnShape : cast e3.spawnShape;
		half[0] = Math.abs(flat ? e2.spawnHalfSize.x : e3.spawnHalfSize.x);
		half[1] = Math.abs(flat ? e2.spawnHalfSize.y : e3.spawnHalfSize.y);
		half[2] = flat ? 0 : Math.abs(e3.spawnHalfSize.z);
		offset[0] = offset[1] = offset[2] = 0;
		if (shape == 1)
			box(e, e.spawnShell, flat);
		else if (shape == 2)
			ellipsoid(e, e.spawnShell, flat);
		// The velocity: its direction, of no length up, turned up to spread off it, its speed varied, and the emitter's own motion added.
		var dx = flat ? e2.direction.x : e3.direction.x,
			dy = flat ? e2.direction.y : e3.direction.y,
			dz = flat ? 0 : e3.direction.z;
		var length = Math.sqrt(dx * dx + dy * dy + dz * dz), vx = 0., vy = 0., vz = 0.;
		if (!(length > 0)) {
			dx = dz = 0;
			dy = flat ? -1 : 1;
			length = 1;
		}
		var spread = clamp(e.spread, 0, 180) * DEGREES;
		dx /= length;
		dy /= length;
		dz /= length;
		if (flat) {
			var a = signed(e) * spread, c = Trig.cos(a), s = Trig.sin(a);
			vx = dx * c - dy * s;
			vy = dx * s + dy * c;
		} else {
			// Two directions across it, from a helper not along it, then a turn off it up to spread, around it at random, evenly over the
			// cone's cap.
			var hx = Math.abs(dy) < .9 ? 0. : 1.,
				hy = Math.abs(dy) < .9 ? 1. : 0.;
			var px = -dz * hy, py = dz * hx, pz = dx * hy - dy * hx;
			var pl = Math.sqrt(px * px + py * py + pz * pz);
			px /= pl;
			py /= pl;
			pz /= pl;
			var qx = dy * pz - dz * py,
				qy = dz * px - dx * pz,
				qz = dx * py - dy * px;
			var around = next(e) * TAU,
				co = 1 - next(e) * (1 - Trig.cos(spread));
			var so = Math.sqrt(1 - co * co > 0 ? 1 - co * co : 0),
				ca = Trig.cos(around),
				sa = Trig.sin(around);
			vx = dx * co + (px * ca + qx * sa) * so;
			vy = dy * co + (py * ca + qy * sa) * so;
			vz = dz * co + (pz * ca + qz * sa) * so;
		}
		var v = (e.speed > 0 ? e.speed : 0) * (1 + signed(e) * clamp(e.speedVariance, 0, 1));
		vx *= v;
		vy *= v;
		vz *= v;
		var ox = offset[0], oy = offset[1], oz = offset[2];
		var inherit = clamp(e.inheritVelocity, 0, 1);
		vx += e.moveX * inherit;
		vy += e.moveY * inherit;
		vz += e.moveZ * inherit;
		var low = e.minLife > 0 ? e.minLife : 0., high = longestLife(e);
		var life = low + (high - low) * next(e);
		var scale = 1 + signed(e) * clamp(e.sizeVariance, 0, 1);
		var slow = e.minSpin, fast = e.maxSpin > slow ? e.maxSpin : slow;
		var spin = (slow + (fast - slow) * next(e)) * DEGREES;
		var random = next(e), phase = next(e);
		var slowOrbit = e.minOrbit,
			fastOrbit = e.maxOrbit > slowOrbit ? e.maxOrbit : slowOrbit;
		var orbit = (slowOrbit + (fastOrbit - slowOrbit) * next(e)) * DEGREES;
		var colors = e.palette.length < MAX_KEYS ? e.palette.length : MAX_KEYS;
		var tint = 0xffffffff;
		if (colors > 0) {
			var pick = Std.int(next(e) * colors);
			tint = cast e.palette[pick < colors ? pick : colors - 1];
		}
		var slot = e.head, s = e.slots, at = slot * SLOT;
		e.head = (slot + 1) % e.capacity;
		if (e.span < e.capacity)
			e.span++;
		if (e.fresh < e.capacity)
			e.fresh++;
		s[at + BORN] = when;
		s[at + LIFE] = life;
		s[at + X] = x + ox;
		s[at + Y] = y + oy;
		s[at + Z] = flat ? 0 : z + oz;
		s[at + VX] = vx;
		s[at + VY] = vy;
		s[at + VZ] = flat ? 0 : vz;
		s[at + SCALE] = scale;
		s[at + SPIN] = spin;
		s[at + RANDOM] = random;
		s[at + PHASE] = phase;
		s[at + CX] = x;
		s[at + CY] = y;
		s[at + CZ] = flat ? 0 : z;
		s[at + ORBIT] = orbit;
		s[at + AX] = flat ? 0 : dx;
		s[at + AY] = flat ? 0 : dy;
		s[at + AZ] = flat ? 0 : dz;
		e.tints[slot] = tint;
	}

	// The spawn shape's half sizes, read at a birth, and the offset a shape gives it.
	static final half:Array<Float> = [0, 0, 0];
	static final offset:Array<Float> = [0, 0, 0];
	// The axes of the half sizes over 0, and their count: the shape's own dimensions.
	static final axes:Array<Int> = [0, 0, 0];
	static var axisCount = 0;

	// Finds the axes whose half size is over 0.
	static function findAxes():Void {
		axisCount = 0;
		for (i in 0...3)
			if (half[i] > 0)
				axes[axisCount++] = i;
	}

	// The most tries at a point over a curved surface, before the last tried is taken.
	static inline final TRIES = 32;

	// An offset in a box (a rectangle in 2D) of the half sizes, or on its surface: a face picked by its area (an edge by its length, an
	// end of a line), then a point on it.
	static function box(e:Emitter, shell:Bool, flat:Bool):Void {
		for (i in 0...(flat ? 2 : 3))
			offset[i] = signed(e) * half[i];
		if (!shell)
			return;
		findAxes();
		if (axisCount == 0)
			return;
		// Each face pair's area: the product of the full sizes across it, 1 for a line's ends.
		var total = 0.;
		for (k in 0...axisCount)
			total += faceArea(k);
		var pick = next(e) * total, side = next(e) < .5 ? -1 : 1;
		for (k in 0...axisCount) {
			var area = faceArea(k);
			if (pick < area || k == axisCount - 1) {
				offset[axes[k]] = side * half[axes[k]];
				return;
			}
			pick -= area;
		}
	}

	static function faceArea(k:Int):Float {
		var area = 1.;
		for (j in 0...axisCount)
			if (j != k)
				area *= 2 * half[axes[j]];
		return area;
	}

	// An offset in an ellipsoid (an ellipse in 2D) of the half sizes as radii, or on its surface: a ball of the shape's dimensions
	// stretched to them, inside; on the surface, a point of the unit sphere (circle) kept as often as the stretched surface's area there.
	static function ellipsoid(e:Emitter, shell:Bool, flat:Bool):Void {
		findAxes();
		if (axisCount == 0)
			return;
		var a = half[axes[0]],
			b = axisCount > 1 ? half[axes[1]] : 0.,
			c = axisCount > 2 ? half[axes[2]] : 0.;
		if (axisCount == 1) {
			offset[axes[0]] = (shell ? (next(e) < .5 ? -1 : 1) : signed(e)) * a;
			return;
		}
		if (axisCount == 2) {
			var angle = 0., r = 1.;
			if (shell) {
				var most = a > b ? a : b;
				for (_ in 0...TRIES) {
					angle = next(e) * TAU;
					var s = Trig.sin(angle), co = Trig.cos(angle);
					if (next(e) * most <= Math.sqrt(a * a * s * s + b * b * co * co))
						break;
				}
			} else {
				angle = next(e) * TAU;
				r = Math.sqrt(next(e));
			}
			offset[axes[0]] = Trig.cos(angle) * r * a;
			offset[axes[1]] = Trig.sin(angle) * r * b;
			return;
		}
		var ux = 0., uy = 0., uz = 0., r = 1.;
		var most = Math.max(b * c, Math.max(a * c, a * b));
		for (_ in 0...TRIES) {
			var height = signed(e), phi = next(e) * TAU;
			var ring = Math.sqrt(1 - height * height > 0 ? 1 - height * height : 0);
			ux = Trig.cos(phi) * ring;
			uy = Trig.sin(phi) * ring;
			uz = height;
			if (!shell)
				break;
			var bc = b * c * ux, ac = a * c * uy, ab = a * b * uz;
			if (next(e) * most <= Math.sqrt(bc * bc + ac * ac + ab * ab))
				break;
		}
		if (!shell)
			r = Math.pow(next(e), 1 / 3);
		offset[axes[0]] = ux * r * a;
		offset[axes[1]] = uy * r * b;
		offset[axes[2]] = uz * r * c;
	}

	// Moves a 2D emitter's particles alive over a time, each by the part of it since its birth: gravity, then drag.
	static function move(e:Emitter2D, dt:Float):Void {
		var s = e.slots, n = e.capacity;
		var gx = e.gravity.x,
			gy = e.gravity.y,
			drag = e.drag > 0 ? e.drag : 0.;
		for (k in 0...e.span) {
			var at = ((e.head - e.span + k + n) % n) * SLOT;
			var age = e.clock - s[at + BORN];
			if (age >= s[at + LIFE])
				continue;
			var step = age < dt ? age : dt;
			if (step <= 0)
				continue;
			var vx = (s[at + VX] + gx * step) / (1 + drag * step),
				vy = (s[at + VY] + gy * step) / (1 + drag * step);
			s[at + VX] = vx;
			s[at + VY] = vy;
			s[at + X] += vx * step;
			s[at + Y] += vy * step;
		}
	}

	/** Returns a particle's offset along one axis on its wandering course, from where its path is: 0 at its birth.

		@param random  The particle's random number.
		@param axis  The axis: 0, 1 or 2.
		@param turn  Its course's turn so far: its age times the wander rate, times two pi. */
	public static function wander(random:Float, axis:Int, turn:Float):Float {
		var a = axis == 0 ? 1.0 : axis == 1 ? 7.31 : 13.7,
			b = axis == 0 ? 3.17 : axis == 1 ? 5.93 : 11.1;
		var first = fraction(random * a) * TAU,
			second = fraction(random * b) * TAU;
		return .6 * Trig.sin(turn + first) + .4 * Trig.sin(2.3 * turn + second) - .6 * Trig.sin(first) - .4 * Trig.sin(second);
	}

	/** Returns how far a 2D particle's orbit has moved it along one axis: where it is from where the emitter was at its birth, turned
		clockwise on screen by an angle, less where it is.

		@param ox  How far across it is from where the emitter was, in pixels.
		@param oy  How far down.
		@param angle  The angle, in radians.
		@param axis  0 across, 1 down. */
	public static function orbited(ox:Float, oy:Float, angle:Float, axis:Int):Float {
		var c = Trig.cos(angle), s = Trig.sin(angle);
		return axis == 0 ? ox * c - oy * s - ox : ox * s + oy * c - oy;
	}

	static inline function fraction(x:Float):Float
		return x - Math.ffloor(x);

	/** The size curve read for a draw: its keys' times and sizes, in order of time, and their count. */
	public static final sizeTimes:Array<Float> = [for (_ in 0...MAX_KEYS) 0.];

	public static final sizeValues:Array<Float> = [for (_ in 0...MAX_KEYS) 0.];
	public static var sizeCount = 0;

	/** The color curve read for a draw: its keys' times and colors, in order of time, and their count. */
	public static final colorTimes:Array<Float> = [for (_ in 0...MAX_KEYS) 0.];

	public static final colorValues:Array<Int> = [for (_ in 0...MAX_KEYS) 0];
	public static var colorCount = 0;

	/** Reads an emitter's size and color keys into `sizeTimes` and the rest: its first 8 keys, each time held to 0 to 1, sorted by time,
		those of one time in the list's order. No keys read as the default's: a 3D emitter's size 0.25 or a 2D emitter's 16, and white
		fading to clear.

		@param e  The emitter.
		@param flat  Whether it is a 2D emitter. */
	public static function readCurves(e:Emitter, flat:Bool):Void {
		var keys = e.sizeKeys == null ? 0 : e.sizeKeys.length < MAX_KEYS ? e.sizeKeys.length : MAX_KEYS;
		if (keys == 0) {
			sizeTimes[0] = 0;
			sizeValues[0] = flat ? 16 : 0.25;
			sizeCount = 1;
		} else {
			for (i in 0...keys) {
				var t = clamp(e.sizeKeys[i].at, 0, 1), v = e.sizeKeys[i].size, j = i;
				// Inserted in order of time, after those of the same time.
				while (j > 0 && sizeTimes[j - 1] > t) {
					sizeTimes[j] = sizeTimes[j - 1];
					sizeValues[j] = sizeValues[j - 1];
					j--;
				}
				sizeTimes[j] = t;
				sizeValues[j] = v;
			}
			sizeCount = keys;
		}
		keys = e.colorKeys == null ? 0 : e.colorKeys.length < MAX_KEYS ? e.colorKeys.length : MAX_KEYS;
		if (keys == 0) {
			colorTimes[0] = 0;
			colorValues[0] = 0xffffffff;
			colorTimes[1] = 1;
			colorValues[1] = 0x00ffffff;
			colorCount = 2;
			return;
		}
		for (i in 0...keys) {
			var t = clamp(e.colorKeys[i].at, 0, 1), v:Int = cast e.colorKeys[i].color, j = i;
			while (j > 0 && colorTimes[j - 1] > t) {
				colorTimes[j] = colorTimes[j - 1];
				colorValues[j] = colorValues[j - 1];
				j--;
			}
			colorTimes[j] = t;
			colorValues[j] = v;
		}
		colorCount = keys;
	}

	/** Returns how much of a particle's alpha its pulse leaves at an age: 1 at the beat's high point, 1 less `pulseDepth` at its low.

		@param e  The emitter.
		@param phase  The particle's phase, 0 to 1.
		@param age  Its age, in seconds. */
	public static function pulseAt(e:Emitter, phase:Float, age:Float):Float {
		if (!(e.pulseRate > 0))
			return 1;
		var depth = clamp(e.pulseDepth, 0, 1);
		return 1 - depth * (.5 + .5 * Trig.sin(TAU * fraction(e.pulseRate * age + phase)));
	}

	/** Returns the size curve at a point of a life: its first key's size before it, its last's after, and between two keys the line
		between them.

		@param t  The point, 0 at birth to 1 at death. */
	public static function sizeAt(t:Float):Float {
		var value = sizeValues[0];
		for (i in 1...sizeCount) {
			if (t >= sizeTimes[i]) {
				value = sizeValues[i];
				continue;
			}
			if (t > sizeTimes[i - 1])
				value = sizeValues[i - 1] + (sizeValues[i] - sizeValues[i - 1]) * (t - sizeTimes[i - 1]) / (sizeTimes[i] - sizeTimes[i - 1]);
			break;
		}
		return value;
	}

	/** Returns the color curve at a point of a life, as `sizeAt` reads the sizes, each channel between two points rounded.

		@param t  The point, 0 at birth to 1 at death.
		@return  The color, as a `Color` holds it. */
	public static function colorAt(t:Float):Int {
		var value = colorValues[0];
		for (i in 1...colorCount) {
			if (t >= colorTimes[i]) {
				value = colorValues[i];
				continue;
			}
			if (t > colorTimes[i - 1]) {
				var a = colorValues[i - 1],
					b = colorValues[i],
					f = (t - colorTimes[i - 1]) / (colorTimes[i] - colorTimes[i - 1]);
				value = between(a, b, f, 0) | between(a, b, f, 8) | between(a, b, f, 16) | between(a, b, f, 24);
			}
			break;
		}
		return value;
	}

	// A channel of the color between two, rounded, in its place.
	static inline function between(a:Int, b:Int, f:Float, shift:Int):Int {
		var x = (a >>> shift) & 255, y = (b >>> shift) & 255;
		return Math.round(x + (y - x) * f) << shift;
	}

	// The soft round dot a particle draws without a texture, made once for each graphics.
	static var dot:Null<helix.raylib.Texture2D>;
	static var dotGraphics:Null<helix.platform.IGraphics>;

	/** Returns the texture a particle draws: its emitter's, or a soft round dot, white, 32 texels a side, its alpha falling smoothly from
		its middle to its edge, made the first time it's asked for and filtered bilinearly.

		@param e  The emitter. */
	public static function textureOf(e:Emitter):helix.raylib.Texture2D {
		if (e.texture != null)
			return e.texture;
		if (dot == null || dotGraphics != Runtime.graphics) {
			dotGraphics = Runtime.graphics;
			var n = 32, pixels = haxe.io.Bytes.alloc(n * n * 4);
			for (y in 0...n)
				for (x in 0...n) {
					var dx = (x + .5) / n * 2 - 1, dy = (y + .5) / n * 2 - 1;
					var t = 1 - Math.sqrt(dx * dx + dy * dy);
					var alpha = t <= 0 ? 0. : t >= .5 ? 1. : (t / .5) * (t / .5) * (3 - 2 * (t / .5));
					var at = (y * n + x) * 4;
					pixels.fill(at, 3, 255);
					pixels.set(at + 3, Std.int(alpha * 255 + .5));
				}
			var image = new helix.raylib.Image();
			image.data = pixels;
			image.width = n;
			image.height = n;
			image.mipmaps = 1;
			image.format = helix.raylib.Raylib.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
			dot = @:privateAccess helix.raylib.modules.RTextures.LoadTextureFromImage(image);
			@:privateAccess helix.raylib.modules.RTextures.SetTextureFilter(dot, helix.raylib.Raylib.TEXTURE_FILTER_BILINEAR);
			// Sent again after the GPU's context is restored.
			Textures.keepPixels(dot.id);
		}
		return dot;
	}

	/** Returns the part of a texture an emitter's particles draw: its `source`, or the whole texture.

		@param e  The emitter.
		@param texture  The texture.
		@param out  The rectangle written: x, y, width and height, in pixels. */
	public static function sourceOf(e:Emitter, texture:helix.raylib.Texture2D, out:Array<Float>):Void {
		var r = e.source;
		out[0] = r == null ? 0 : r.x;
		out[1] = r == null ? 0 : r.y;
		out[2] = r == null ? texture.width : r.width;
		out[3] = r == null ? texture.height : r.height;
	}

	/** Returns how many of the flipbook's frames are played: its `frameCount`, all of them when 0 or less, held to the frames there are.

		@param e  The emitter. */
	public static function framesOf(e:Emitter):Int {
		var all = (e.frameColumns > 1 ? e.frameColumns : 1) * (e.frameRows > 1 ? e.frameRows : 1);
		return e.frameCount <= 0 || e.frameCount > all ? all : e.frameCount;
	}

	// What a 2D draw reads, kept so a draw allocates nothing: the texture's part, and the quad's color.
	static final part:Array<Float> = [0, 0, 0, 0];

	/** Draws a 2D emitter's particles into the frame's batch, oldest first, each a quad of its texture as `DrawTexturePro` draws one.

		@param e  The emitter. */
	public static function draw2D(e:Emitter2D):Void {
		if (e.span == 0)
			return;
		var texture = textureOf(e);
		if (texture.id == 0 || texture.width == 0 || texture.height == 0)
			return;
		var frame = Runtime.frame;
		var mode = frame.blendMode;
		if (e.blendMode != mode)
			@:privateAccess helix.raylib.modules.RCore.BeginBlendMode(e.blendMode);
		readCurves(e, true);
		sourceOf(e, texture, part);
		var handle = Textures.handle(texture.id);
		var columns = e.frameColumns > 1 ? e.frameColumns : 1,
			rows = e.frameRows > 1 ? e.frameRows : 1,
			frames = framesOf(e);
		var cellWidth = part[2] / columns, cellHeight = part[3] / rows;
		var fps = e.framesPerSecond,
			stretch = e.stretch > 0 ? e.stretch : 0.,
			align = e.alignToMotion;
		var wander = e.wanderDistance, wanderRate = e.wanderRate;
		var s = e.slots, n = e.capacity;
		for (k in 0...e.span) {
			var slot = (e.head - e.span + k + n) % n, at = slot * SLOT;
			var age = e.clock - s[at + BORN], life = s[at + LIFE];
			if (age < 0 || age >= life)
				continue;
			var t = age / life;
			var size = sizeAt(t) * s[at + SCALE];
			if (!(size > 0))
				continue;
			var color = colorAt(t), tint = e.tints[slot];
			var r = mix(color, tint, 0),
				g = mix(color, tint, 8),
				b = mix(color, tint, 16),
				a = Math.round(mix(color, tint, 24) * pulseAt(e, s[at + PHASE], age));
			if (a == 0)
				continue;
			var x = s[at + X], y = s[at + Y], vx = s[at + VX], vy = s[at + VY];
			if (s[at + ORBIT] != 0) {
				var angle = s[at + ORBIT] * age,
					rx = x - s[at + CX],
					ry = y - s[at + CY];
				x += orbited(rx, ry, angle, 0);
				y += orbited(rx, ry, angle, 1);
			}
			if (wander > 0) {
				var turn = TAU * wanderRate * age;
				x += wander * Emitters.wander(s[at + RANDOM], 0, turn);
				y += wander * Emitters.wander(s[at + RANDOM], 1, turn);
			}
			// The quad's axes: across its texture, turned clockwise by its spin (and its motion, aligned), or along its motion, stretched.
			var speed = Math.sqrt(vx * vx + vy * vy), along = size, c = 1., si = 0.;
			if (stretch > 0 && speed > 1e-5) {
				c = vx / speed;
				si = vy / speed;
				along = size + speed * stretch;
				x -= c * speed * stretch / 2;
				y -= si * speed * stretch / 2;
			} else {
				var angle = s[at + SPIN] * age;
				if (align && speed > 1e-5)
					angle += Math.atan2(vy, vx);
				c = Math.cos(angle);
				si = Math.sin(angle);
			}
			// The flipbook's frame: played once over the life, or looped at its rate.
			var f = frames < 2 ? 0 : fps > 0 ? Std.int(Math.ffloor(age * fps) % frames) : Std.int(Math.min(Math.ffloor(t * frames), frames - 1));
			var u0 = (part[0] + (f % columns) * cellWidth) / texture.width,
				v0 = (part[1] + Std.int(f / columns) * cellHeight) / texture.height;
			var u1 = u0 + cellWidth / texture.width,
				v1 = v0 + cellHeight / texture.height;
			var hx = along / 2, hy = size / 2;
			// The corners top left, bottom left, bottom right, top right, in DrawTexturePro's order.
			var ax = x - c * hx + si * hy, ay = y - si * hx - c * hy;
			var bx = x - c * hx - si * hy, by = y - si * hx + c * hy;
			var cx = x + c * hx - si * hy, cy = y + si * hx + c * hy;
			var ex = x + c * hx + si * hy, ey = y + si * hx - c * hy;
			frame.quad(handle, ax, ay, bx, by, cx, cy, ex, ey, u0, v0, u1, v1, new Color(r, g, b, a));
		}
		if (e.blendMode != mode)
			@:privateAccess helix.raylib.modules.RCore.BeginBlendMode(mode);
	}

	// A channel of a color times a tint's, rounded.
	static inline function mix(color:Int, tint:Int, shift:Int):Int
		return Std.int((((color >>> shift) & 255) * ((tint >>> shift) & 255) + 127) / 255);
}
