package helix.math;

/** Provides smooth noise: a number for each point that changes little between near points, the same on every target.

	```haxe
	var height = Noise.fractal(x * .01, z * .01) * 40; // terrain: hills with detail
	var sway = Noise.perlin(time * .5, 0) * 3; // a camera's shake or a flame's flicker
	var cloud = Noise.simplex(x * .02, y * .02, time); // a moving cloud layer
	var crack = Noise.cellular(x * .1, y * .1); // cells, as stone or water caustics
	```

	Natively the generated C++ is compiled with `-ffp-contract=off` on GCC and clang, so that fused multiply-adds don't change the
	rounding. */
@:buildXml("<files id='haxe'><compilerflag value='-ffp-contract=off' unless='windows'/></files>")
class Noise {
	// How much simplex's four corners' sum is scaled by, to reach about -1 to 1.
	static inline var SIMPLEX_SCALE = 76.;

	/** Returns Perlin noise at a point.

		The noise is 0 at a point with whole-number coordinates. The noise repeats every 256 along each axis.
		@param x  The point's x.
		@param y  The point's y.
		@param z  Optional. The point's z; defaults to 0, a 2D slice.
		@param seed  Optional. Picks one noise of 256; defaults to 0.
		@return  The noise, about -1 to 1. */
	public static function perlin(x:Float, y:Float, z = 0., seed = 0):Float {
		var wholeX = Math.ffloor(x),
			wholeY = Math.ffloor(y),
			wholeZ = Math.ffloor(z);
		var x0 = cell(wholeX), y0 = cell(wholeY), z0 = cell(wholeZ);
		var x1 = (x0 + 1) & 255, y1 = (y0 + 1) & 255, z1 = (z0 + 1) & 255;
		x -= wholeX;
		y -= wholeY;
		z -= wholeZ;
		var u = ease(x), v = ease(y), w = ease(z);
		var r0 = PERMUTATION[(x0 + seed) & 255],
			r1 = PERMUTATION[(x1 + seed) & 255];
		var r00 = PERMUTATION[(r0 + y0) & 255],
			r01 = PERMUTATION[(r0 + y1) & 255],
			r10 = PERMUTATION[(r1 + y0) & 255],
			r11 = PERMUTATION[(r1 + y1) & 255];
		var xm = x - 1, ym = y - 1, zm = z - 1;
		var n00 = mix(gradient(r00 + z0, x, y, z), gradient(r00 + z1, x, y, zm), w);
		var n01 = mix(gradient(r01 + z0, x, ym, z), gradient(r01 + z1, x, ym, zm), w);
		var n10 = mix(gradient(r10 + z0, xm, y, z), gradient(r10 + z1, xm, y, zm), w);
		var n11 = mix(gradient(r11 + z0, xm, ym, z), gradient(r11 + z1, xm, ym, zm), w);
		return mix(mix(n00, n01, v), mix(n10, n11, v), u);
	}

	/** Returns simplex noise at a point. Simplex noise shows less of the grid's directions than `perlin` does.

		The noise repeats every 768 along each axis.
		@param x  The point's x.
		@param y  The point's y.
		@param z  Optional. The point's z; defaults to 0, a 2D slice.
		@param seed  Optional. Picks one noise of 256; defaults to 0.
		@return  The noise, about -1 to 1. */
	public static function simplex(x:Float, y:Float, z = 0., seed = 0):Float {
		// The point in a grid of cubes skewed along their diagonal, each cube six tetrahedra.
		var skew = (x + y + z) * (1 / 3);
		var wholeX = Math.ffloor(x + skew),
			wholeY = Math.ffloor(y + skew),
			wholeZ = Math.ffloor(z + skew);
		var unskew = (wholeX + wholeY + wholeZ) * (1 / 6);
		var x0 = x - (wholeX - unskew),
			y0 = y - (wholeY - unskew),
			z0 = z - (wholeZ - unskew);
		// The tetrahedron's second and third corners, by which of x0, y0 and z0 is largest and which next.
		var i1 = 0, j1 = 0, k1 = 0, i2 = 0, j2 = 0, k2 = 0;
		if (x0 >= y0) {
			if (y0 >= z0) {
				i1 = 1;
				i2 = 1;
				j2 = 1;
			} else if (x0 >= z0) {
				i1 = 1;
				i2 = 1;
				k2 = 1;
			} else {
				k1 = 1;
				i2 = 1;
				k2 = 1;
			}
		} else if (y0 < z0) {
			k1 = 1;
			j2 = 1;
			k2 = 1;
		} else if (x0 < z0) {
			j1 = 1;
			j2 = 1;
			k2 = 1;
		} else {
			j1 = 1;
			i2 = 1;
			j2 = 1;
		}
		var i = cell(wholeX), j = cell(wholeY), k = cell(wholeZ);
		var sum = corner(i, j, k, x0, y0, z0, seed)
			+ corner(i + i1, j + j1, k + k1, x0 - i1 + 1 / 6, y0 - j1 + 1 / 6, z0 - k1 + 1 / 6, seed)
			+ corner(i + i2, j + j2, k + k2, x0 - i2 + 1 / 3, y0 - j2 + 1 / 3, z0 - k2 + 1 / 3, seed)
			+ corner(i + 1, j + 1, k + 1, x0 - .5, y0 - .5, z0 - .5, seed);
		return SIMPLEX_SCALE * sum;
	}

	/** Returns cellular (Worley) noise at a point: the distance to the nearest of points scattered one to a unit cell.

		The scatter repeats every 256 along each axis.
		@param x  The point's x.
		@param y  The point's y.
		@param z  Optional. The point's z; defaults to 0, a 2D slice.
		@param seed  Optional. Picks one scatter of 256; defaults to 0.
		@return  The distance, 0 at a scattered point. */
	public static function cellular(x:Float, y:Float, z = 0., seed = 0):Float {
		var wholeX = Math.ffloor(x),
			wholeY = Math.ffloor(y),
			wholeZ = Math.ffloor(z);
		var cellX = cell(wholeX), cellY = cell(wholeY), cellZ = cell(wholeZ);
		x -= wholeX;
		y -= wholeY;
		z -= wholeZ;
		// The nearest scattered point is in the point's cell or one of the 26 around.
		var nearest = Math.POSITIVE_INFINITY;
		for (dz in -1...2)
			for (dy in -1...2)
				for (dx in -1...2) {
					var cx = cellX + dx, cy = cellY + dy, cz = cellZ + dz;
					var px = dx + (scatter(cx + seed, cy, cz) + .5) / 256 - x,
						py = dy + (scatter(cy + seed + 101, cz, cx) + .5) / 256 - y,
						pz = dz + (scatter(cz + seed + 211, cx, cy) + .5) / 256 - z;
					var distance = px * px + py * py + pz * pz;
					if (distance < nearest)
						nearest = distance;
				}
		return Math.sqrt(nearest);
	}

	/** Returns Perlin noise summed over octaves, each finer and fainter than the last (fractal Brownian motion).

		@param x  The point's x.
		@param y  The point's y.
		@param z  Optional. The point's z; defaults to 0, a 2D slice.
		@param octaves  Optional. How many layers are summed; defaults to 6.
		@param lacunarity  Optional. How much finer each octave is than the last; defaults to 2.
		@param gain  Optional. How much fainter each octave is than the last; defaults to 0.5.
		@param seed  Optional. Picks one noise of 256; defaults to 0.
		@return  The sum: mostly within -1 to 1 at the default gain, and at most the octaves' sizes added up, 1.97 at the defaults. */
	public static function fractal(x:Float, y:Float, z = 0., octaves = 6, lacunarity = 2., gain = .5, seed = 0):Float {
		var frequency = 1., amplitude = 1., sum = 0.;
		for (octave in 0...octaves) {
			sum += perlin(x * frequency, y * frequency, z * frequency, seed + octave) * amplitude;
			frequency *= lacunarity;
			amplitude *= gain;
		}
		return sum;
	}

	// A whole number's place among the 256 the tables hold, the same for a number of any size and sign.
	static inline function cell(whole:Float):Int
		return Std.int(whole - Math.ffloor(whole / 256) * 256) & 255;

	static inline function ease(a:Float):Float
		return ((a * 6 - 15) * a + 10) * a * a * a;

	static inline function mix(a:Float, b:Float, t:Float):Float
		return a + (b - a) * t;

	static inline function gradient(index:Int, x:Float, y:Float, z:Float):Float {
		var at = GRADIENT[index & 255] * 3;
		return BASIS[at] * x + BASIS[at + 1] * y + BASIS[at + 2] * z;
	}

	// What one corner of simplex's tetrahedron adds at a point x, y, z from the corner: the corner's gradient, fading to 0 at a
	// distance of the square root of 1/2.
	static inline function corner(i:Int, j:Int, k:Int, x:Float, y:Float, z:Float, seed:Int):Float {
		var fade = .5 - x * x - y * y - z * z;
		if (fade < 0)
			fade = 0;
		fade *= fade;
		return fade * fade * gradient(PERMUTATION[(PERMUTATION[(i + seed) & 255] + j) & 255] + k, x, y, z);
	}

	// A number from 0 to 255 for a cell, from the permutation.
	static inline function scatter(a:Int, b:Int, c:Int):Int
		return PERMUTATION[(PERMUTATION[(PERMUTATION[a & 255] + b) & 255] + c) & 255];

	// stb_perlin's 12 gradients, three numbers each.
	static final BASIS:Array<Float> = [
		1, 1, 0, -1,  1, 0, 1, -1,  0, -1, -1,  0,
		1, 0, 1, -1,  0, 1, 1,  0, -1, -1,  0, -1,
		0, 1, 1,  0, -1, 1, 0,  1, -1,  0, -1, -1
	];

	// stb_perlin's permutation (its second copy dropped: an index is reduced modulo 256).
	static final PERMUTATION:Array<Int> = [
		23, 125, 161, 52, 103, 117, 70, 37, 247, 101, 203, 169, 124, 126, 44, 123, 152, 238, 145, 45, 171, 114, 253, 10, 192, 136, 4, 157, 249, 30, 35, 72,
		175, 63, 77, 90, 181, 16, 96, 111, 133, 104, 75, 162, 93, 56, 66, 240, 8, 50, 84, 229, 49, 210, 173, 239, 141, 1, 87, 18, 2, 198, 143, 57, 225, 160,
		58, 217, 168, 206, 245, 204, 199, 6, 73, 60, 20, 230, 211, 233, 94, 200, 88, 9, 74, 155, 33, 15, 219, 130, 226, 202, 83, 236, 42, 172, 165, 218, 55,
		222, 46, 107, 98, 154, 109, 67, 196, 178, 127, 158, 13, 243, 65, 79, 166, 248, 25, 224, 115, 80, 68, 51, 184, 128, 232, 208, 151, 122, 26, 212, 105,
		43, 179, 213, 235, 148, 146, 89, 14, 195, 28, 78, 112, 76, 250, 47, 24, 251, 140, 108, 186, 190, 228, 170, 183, 139, 39, 188, 244, 246, 132, 48, 119,
		144, 180, 138, 134, 193, 82, 182, 120, 121, 86, 220, 209, 3, 91, 241, 149, 85, 205, 150, 113, 216, 31, 100, 41, 164, 177, 214, 153, 231, 38, 71, 185,
		174, 97, 201, 29, 95, 7, 92, 54, 254, 191, 118, 34, 221, 131, 11, 163, 99, 234, 81, 227, 147, 156, 176, 17, 142, 69, 12, 110, 62, 27, 255, 0, 194, 59,
		116, 242, 252, 19, 21, 187, 53, 207, 129, 64, 135, 61, 40, 167, 237, 102, 223, 106, 159, 197, 189, 215, 137, 36, 32, 22, 5
	];

	// stb_perlin's gradient for each permutation entry (its second copy dropped likewise).
	static final GRADIENT:Array<Int> = [
		7, 9, 5, 0, 11, 1, 6, 9, 3, 9, 11, 1, 8, 10, 4, 7, 8, 6, 1, 5, 3, 10, 9, 10, 0, 8, 4, 1, 5, 2, 7, 8, 7, 11, 9, 10, 1, 0, 4, 7, 5, 0, 11, 6, 1, 4, 2,
		8, 8, 10, 4, 9, 9, 2, 5, 7, 9, 1, 7, 2, 2, 6, 11, 5, 5, 4, 6, 9, 0, 1, 1, 0, 7, 6, 9, 8, 4, 10, 3, 1, 2, 8, 8, 9, 10, 11, 5, 11, 11, 2, 6, 10, 3, 4,
		2, 4, 9, 10, 3, 2, 6, 3, 6, 10, 5, 3, 4, 10, 11, 2, 9, 11, 1, 11, 10, 4, 9, 4, 11, 0, 4, 11, 4, 0, 0, 0, 7, 6, 10, 4, 1, 3, 11, 5, 3, 4, 2, 9, 1, 3,
		0, 1, 8, 0, 6, 7, 8, 7, 0, 4, 6, 10, 8, 2, 3, 11, 11, 8, 0, 2, 4, 8, 3, 0, 0, 10, 6, 1, 2, 2, 4, 5, 6, 0, 1, 3, 11, 9, 5, 5, 9, 6, 9, 8, 3, 8, 1, 8,
		9, 6, 9, 11, 10, 7, 5, 6, 5, 9, 1, 3, 7, 0, 2, 10, 11, 2, 6, 1, 3, 11, 7, 7, 2, 1, 7, 3, 0, 8, 1, 1, 5, 0, 6, 10, 11, 11, 0, 2, 7, 0, 10, 8, 3, 5, 7,
		1, 11, 1, 0, 7, 9, 0, 11, 5, 10, 3, 2, 3, 5, 9, 7, 9, 8, 4, 6, 5
	];
}
