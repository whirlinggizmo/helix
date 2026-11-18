import helix.math.Noise;
import helix.math.Random;

/** Checks Noise with the library alone: Perlin, simplex and cellular noise and Perlin's octaves summed, each one's range, how smoothly
	each changes, where each repeats and what a seed changes, and that every target gives the interpreter's bits. */
class NoiseTests {
	static var checks = 0;

	// The interpreter's hash of the numbers the last check takes, which Node's and hxcpp's must match.
	static inline var PINNED = 974820441;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance = 1e-12):Bool
		return Math.abs(a - b) < tolerance;

	static function main():Void {
		var r = new Random(4);
		inline function place():Float
			return r.nextRange(-150, 150);

		// Perlin: 0 at whole numbers, within about -1 to 1, smooth, repeating every 256, and a seed's own.
		var wholes = true;
		for (_ in 0...200)
			if (Noise.perlin(r.nextInt(600) - 300, r.nextInt(600) - 300, r.nextInt(600) - 300, r.nextInt(256)) != 0)
				wholes = false;
		check(wholes, "perlin: 0 at a point of whole numbers");
		var least = 0., most = 0., smooth = true, repeats = true, differs = 0;
		for (_ in 0...4000) {
			var x = place(), y = place(), z = place(), seed = r.nextInt(256);
			var n = Noise.perlin(x, y, z, seed);
			least = Math.min(least, n);
			most = Math.max(most, n);
			if (Math.abs(Noise.perlin(x + 1e-4, y - 1e-4, z + 1e-4, seed) - n) > 1e-3)
				smooth = false;
			if (!near(Noise.perlin(x + 256, y - 512, z + 256, seed), n, 1e-9) || !near(Noise.perlin(x, y, z, seed + 256), n))
				repeats = false;
			if (Noise.perlin(x, y, z, seed + 1) != n)
				differs++;
		}
		check(least < -.7 && least > -1.05 && most > .7 && most < 1.05, "perlin: about -1 to 1");
		check(smooth, "perlin: near points give near numbers");
		check(repeats, "perlin: the noise again 256 along an axis, and 256 seeds on");
		check(differs > 3900, "perlin: another seed, another noise");
		check(Noise.perlin(.3, .7) == Noise.perlin(.3, .7, 0, 0)
			&& Noise.perlin(.3, .7) != Noise.perlin(.3, .7, .5), "perlin: z 0 and seed 0 unless told");
		check(near(Noise.perlin(-1e-9, .4, .6), Noise.perlin(1e-9, .4, .6), 1e-6), "perlin: smooth across 0");

		// Simplex.
		least = 0;
		most = 0;
		smooth = true;
		repeats = true;
		differs = 0;
		for (_ in 0...4000) {
			var x = place(), y = place(), z = place(), seed = r.nextInt(256);
			var n = Noise.simplex(x, y, z, seed);
			least = Math.min(least, n);
			most = Math.max(most, n);
			if (Math.abs(Noise.simplex(x + 1e-4, y - 1e-4, z + 1e-4, seed) - n) > 2e-3)
				smooth = false;
			if (!near(Noise.simplex(x + 768, y, z - 768, seed), n, 1e-8) || !near(Noise.simplex(x, y, z, seed + 256), n))
				repeats = false;
			if (Noise.simplex(x, y, z, seed + 1) != n)
				differs++;
		}
		check(least < -.7 && least > -1 && most > .7 && most < 1, "simplex: about -1 to 1");
		check(smooth, "simplex: near points give near numbers");
		check(repeats, "simplex: the noise again 768 along an axis, and 256 seeds on");
		check(differs > 3900, "simplex: another seed, another noise");
		check(Noise.simplex(.3, .7) == Noise.simplex(.3, .7, 0, 0) && Noise.simplex(.3, .7) != Noise.simplex(.3, .7, .5),
			"simplex: z 0 and seed 0 unless told");
		check(Noise.simplex(0, 0, 0) == 0, "simplex: 0 at the origin");

		// Cellular: a distance, so no further apart at two points than the points are.
		least = 9;
		most = 0;
		var distance = true;
		repeats = true;
		differs = 0;
		for (_ in 0...2000) {
			var x = place(), y = place(), z = place(), seed = r.nextInt(256);
			var n = Noise.cellular(x, y, z, seed);
			least = Math.min(least, n);
			most = Math.max(most, n);
			var dx = r.nextRange(-.5, .5),
				dy = r.nextRange(-.5, .5),
				dz = r.nextRange(-.5, .5);
			if (Math.abs(Noise.cellular(x + dx, y + dy, z + dz, seed) - n) > Math.sqrt(dx * dx + dy * dy + dz * dz) + 1e-12)
				distance = false;
			if (!near(Noise.cellular(x - 256, y + 256, z + 512, seed), n, 1e-9) || !near(Noise.cellular(x, y, z, seed + 256), n))
				repeats = false;
			if (Noise.cellular(x, y, z, seed + 1) != n)
				differs++;
		}
		check(least >= 0 && least < .1 && most > .9 && most < 1.75, "cellular: from 0 to no more than a cell's diagonal");
		check(distance, "cellular: two points' distances differ by no more than the points are apart");
		check(repeats, "cellular: the scatter again 256 along an axis, and 256 seeds on");
		check(differs > 1900, "cellular: another seed, another scatter");
		check(Noise.cellular(.3, .7) == Noise.cellular(.3, .7, 0, 0), "cellular: z 0 and seed 0 unless told");

		// Octaves.
		check(Noise.fractal(.3, .7, .2, 1) == Noise.perlin(.3, .7, .2)
			&& Noise.fractal(.3, .7, .2, 0) == 0
			&& Noise.fractal(.3, .7, .2, -3) == 0,
			"fractal: one octave is perlin, none is 0");
		check(Noise.fractal(.3, .7, .2, 3, 3, .25, 5) == Noise.perlin(.3, .7, .2, 5)
			+ Noise.perlin(.3 * 3, .7 * 3, .2 * 3, 6) * .25
			+ Noise.perlin(.3 * 9, .7 * 9, .2 * 9, 7) * .0625,
			"fractal: each octave finer by the lacunarity, fainter by the gain, on the next seed");
		check(Noise.fractal(.3, .7) == Noise.fractal(.3, .7, 0, 6, 2, .5, 0), "fractal: 6 octaves, twice as fine and half as faint, unless told");
		least = 0;
		most = 0;
		for (_ in 0...4000) {
			var n = Noise.fractal(place(), place(), place());
			least = Math.min(least, n);
			most = Math.max(most, n);
		}
		check(least < -.7 && least > -1.97 && most > .7 && most < 1.97, "fractal: mostly -1 to 1, and within the octaves' sizes added up");

		// Every target's bits match the interpreter's.
		var bits = haxe.io.Bytes.alloc(8 * 4 * 500);
		var at = 0;
		inline function note(v:Float):Void {
			bits.setDouble(at, v);
			at += 8;
		}
		r.seed = 8;
		for (_ in 0...500) {
			var x = r.nextRange(-1e4, 1e4),
				y = r.nextRange(-1e4, 1e4),
				z = r.nextRange(-1e4, 1e4),
				seed = r.nextInt(1000) - 500;
			note(Noise.perlin(x, y, z, seed));
			note(Noise.simplex(x, y, z, seed));
			note(Noise.cellular(x, y, z, seed));
			note(Noise.fractal(x, y, z, 5, 2.1, .6, seed));
		}
		var hash = haxe.crypto.Crc32.make(bits);
		check(at == bits.length && hash == PINNED, 'the bits of 500 of each: $hash');
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
