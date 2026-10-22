package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.FPHelper;

/** Prepares an environment map on the CPU, a step at a time (run, under a time budget), so that it spreads over frames: from an
	equirectangular image (a .hdr's linear light, or an 8-bit image's sRGB) it works out the light it casts on rough surfaces (irradiance, as 9
	spherical-harmonic coefficients), a cubemap of the image at its own resolution (the background, its mips box-filtered for blur) and one
	blurred for each roughness (GGX-prefiltered, CUBE_SIZE a face and MIP_COUNT mips, roughness 0 to 1 across them: what smooth to rough
	surfaces reflect), both as half floats ready for the GPU; and once, shared by every environment, the split-sum BRDF table (brdfTable).
	Split-sum image-based lighting, as the glTF sample viewer, Filament and Unreal light with it.

	Conventions: directions are world space, +y up. An equirectangular image's u runs around the horizon, 0.5 looking toward -z and growing
	toward +x; v = 0 is straight up. Cubemap faces are +X, -X, +Y, -Y, +Z, -Z in GL's orientation (s, t from 0 to 1, t = 0 the face's first
	row). The coefficients are convolved for Lambert's diffuse and divided by pi: evaluated at a normal, they give irradiance over pi. */
class EnvironmentBake3D {
	/** The prefiltered cube's face size, at mip 0. */
	public static inline var CUBE_SIZE = 128;

	/** The prefiltered cube's mips: 128 down to 4, roughness 0, 0.2, ... 1. */
	public static inline var MIP_COUNT = 6;

	/** The BRDF table's size: n.v across, roughness down. */
	public static inline var BRDF_SIZE = 64;

	static inline var SAMPLES = 96;
	static inline var BRDF_SAMPLES = 256;
	static inline var MIN_SOURCE = 64;
	static inline var MAX_SOURCE = 1024;
	// A step's work: an image's pixels (decoding, the irradiance), or samples (four a background texel, or prefilter samples).
	static inline var STEP_PIXELS = 32768;
	static inline var STEP_SAMPLES = 16384;

	// Kept across a hot reload: the table takes a while to make.
	@:hot static var brdf:Null<Bytes>;
	@:hot static var brdfRows = 0;

	var stage = Brdf;
	var hdr:Null<Hdr>;
	var image:Vector<Float>;
	var width:Int;
	var height:Int;
	var sums = new Vector<Float>(27);
	var sh = new Vector<Float>(27);
	var source:CubeMap3D;
	var prefiltered:CubeMap3D;
	var samples = new Vector<Float>(SAMPLES * 4);
	var sampleCount = 0;
	var face = 0;
	var mip = 0;
	var row = 0;
	var scratch = new Vector<Float>(3);
	var direction = new Vector<Float>(3);

	function new() {
		for (i in 0...27)
			sums[i] = 0;
	}

	/** A bake of encoded, a .hdr's bytes, decoded in its steps. Throws for one that isn't a .hdr. */
	public static function fromHdr(encoded:Bytes):EnvironmentBake3D {
		var bake = new EnvironmentBake3D();
		bake.hdr = Hdr.begin(encoded);
		bake.width = bake.hdr.width;
		bake.height = bake.hdr.height;
		bake.image = bake.hdr.rgb;
		return bake;
	}

	/** A bake of an 8-bit image (rows top first, RGBA, its colors sRGB), as linear light. Throws for a size of 0 or less, or rgba too short. */
	public static function fromRgba(width:Int, height:Int, rgba:Bytes):EnvironmentBake3D {
		if (width <= 0 || height <= 0 || rgba.length < width * height * 4)
			throw "Invalid environment image";
		var linear = new Vector<Float>(256);
		for (i in 0...256) {
			var c = i / 255;
			linear[i] = c <= .04045 ? c / 12.92 : Math.pow((c + .055) / 1.055, 2.4);
		}
		var bake = new EnvironmentBake3D();
		bake.width = width;
		bake.height = height;
		bake.image = new Vector<Float>(width * height * 3);
		for (i in 0...width * height)
			for (c in 0...3)
				bake.image[i * 3 + c] = linear[rgba.get(i * 4 + c)];
		return bake;
	}

	/** Whether it's finished. */
	public var done(get, never):Bool;

	function get_done():Bool
		return stage == Done;

	/** Works steps until it's done or budgetMs milliseconds have passed (at least one step); true once done. Throws for a .hdr that turns out
		broken. */
	public function run(budgetMs:Float):Bool {
		var start = haxe.Timer.stamp();
		while (stage != Done) {
			step();
			if ((haxe.Timer.stamp() - start) * 1000 >= budgetMs)
				break;
		}
		return stage == Done;
	}

	/** Its irradiance once done: 9 coefficients, RGB each (27 floats), over pi. */
	public var irradiance(get, never):Vector<Float>;

	function get_irradiance():Vector<Float>
		return sh;

	/** The prefiltered cube once done: MIP_COUNT levels from CUBE_SIZE, each its six faces one after another, RGBA half floats. */
	public var lightingLevels(default, null):Array<Bytes> = [];

	/** The background cube once done: from backgroundSize down to 1, each its six faces one after another, RGBA half floats. */
	public var backgroundLevels(default, null):Array<Bytes> = [];

	/** The background cube's face size, once its size is known (0 before): the image's width over 4, rounded down to a power of two, 64 to
		1024. */
	public var backgroundSize(default, null):Int = 0;

	/** The split-sum BRDF table once a bake has made it (null before): BRDF_SIZE square, RGBA8, red the scale A and green the bias B on F0
		(F0 * A + B, 0..1), by n.v across and perceptual roughness down, each at its texel's centre: integrated over 256 GGX importance samples
		with Schlick-GGX geometry (k = alpha / 2) and Schlick's Fresnel (Karis' split sum). */
	public static var brdfTable(get, never):Null<Bytes>;

	static function get_brdfTable():Null<Bytes>
		return brdfRows == BRDF_SIZE ? brdf : null;

	// One step of work.
	function step():Void {
		switch stage {
			case Brdf:
				if (brdfRows < BRDF_SIZE)
					brdfRow();
				else
					stage = hdr != null ? Decode : Irradiance;
			case Decode:
				if (hdr.readRows(rowsFor(STEP_PIXELS, width))) {
					hdr = null;
					stage = Irradiance;
				}
			case Irradiance:
				var end = Std.int(Math.min(row + rowsFor(STEP_PIXELS, width), height));
				projectRows(image, width, height, row, end, sums);
				row = end;
				if (row == height) {
					shFromSums(sums, sh);
					var size = MIN_SOURCE;
					while (size * 2 <= width / 4 && size < MAX_SOURCE)
						size *= 2;
					source = new CubeMap3D(size, mipCountOf(size));
					backgroundSize = size;
					row = face = 0;
					stage = Source;
				}
			case Source:
				var size = source.size,
					end = Std.int(Math.min(row + rowsFor(Std.int(STEP_SAMPLES / 4), size), size));
				cubeRows(image, width, height, source, face, row, end);
				row = end;
				if (row == size) {
					row = 0;
					if (++face == 6) {
						boxMips(source);
						image = null;
						prefiltered = new CubeMap3D(CUBE_SIZE, MIP_COUNT);
						face = mip = 0;
						sampleCount = 0;
						stage = Prefilter;
					}
				}
			case Prefilter:
				var s = levelSize(CUBE_SIZE, mip);
				var end = Std.int(Math.min(row + rowsFor(STEP_SAMPLES, s * (mip > 0 ? sampleCount : 1)), s));
				prefilterRows(source, prefiltered, mip, face, row, end, samples, sampleCount);
				row = end;
				if (row < s)
					return;
				row = 0;
				if (++face < 6)
					return;
				face = 0;
				if (++mip == MIP_COUNT) {
					mip = 0;
					stage = Pack;
					return;
				}
				sampleCount = prefilterSamples(source, mip, MIP_COUNT, SAMPLES, samples);
			case Pack:
				// A level a step: the prefiltered cube's, then the background's.
				if (mip < MIP_COUNT)
					lightingLevels.push(halfLevel(prefiltered.mips[mip]));
				else
					backgroundLevels.push(halfLevel(source.mips[mip - MIP_COUNT]));
				if (++mip == MIP_COUNT + source.mipCount) {
					source = prefiltered = null;
					stage = Done;
				}
			case Done:
		}
	}

	static inline function rowsFor(budget:Int, width:Int):Int
		return width > 0 && Std.int(budget / width) > 0 ? Std.int(budget / width) : 1;

	static inline function levelSize(size:Int, mip:Int):Int
		return size >> mip > 0 ? size >> mip : 1;

	static function mipCountOf(size:Int):Int {
		var count = 1;
		while (size >> (count - 1) > 1 && count < 16)
			count++;
		return count;
	}

	/** The direction of equirectangular u, v (0..1 each), into out (x, y, z). */
	public static function equirectDirection(u:Float, v:Float, out:Vector<Float>):Void {
		var phi = (u - .5) * 2 * Math.PI, theta = v * Math.PI;
		out[0] = Math.sin(theta) * Math.sin(phi);
		out[1] = Math.cos(theta);
		out[2] = -Math.sin(theta) * Math.cos(phi);
	}

	/** Where direction x, y, z (any length but 0) is in an equirectangular image, into out (u, v). */
	public static function directionEquirect(x:Float, y:Float, z:Float, out:Vector<Float>):Void {
		var length = Math.sqrt(x * x + y * y + z * z), dy = y / length;
		out[0] = .5 + Math.atan2(x / length, -z / length) / (2 * Math.PI);
		out[1] = Math.acos(dy < -1 ? -1 : dy > 1 ? 1 : dy) / Math.PI;
	}

	/** The direction through face's s, t (0..1 each), normalized, into out (x, y, z). */
	public static function cubeDirection(face:Int, s:Float, t:Float, out:Vector<Float>):Void {
		var sc = 2 * s - 1, tc = 2 * t - 1, x, y, z;
		switch face {
			case 0:
				x = 1.;
				y = -tc;
				z = -sc;
			case 1:
				x = -1.;
				y = -tc;
				z = sc;
			case 2:
				x = sc;
				y = 1.;
				z = tc;
			case 3:
				x = sc;
				y = -1.;
				z = -tc;
			case 4:
				x = sc;
				y = -tc;
				z = 1.;
			default:
				x = -sc;
				y = -tc;
				z = -1.;
		}
		var length = Math.sqrt(x * x + y * y + z * z);
		out[0] = x / length;
		out[1] = y / length;
		out[2] = z / length;
	}

	/** Where direction x, y, z is on a cube, into out (face, s, t). */
	public static function directionCube(x:Float, y:Float, z:Float, out:Vector<Float>):Void {
		var ax = Math.abs(x), ay = Math.abs(y), az = Math.abs(z), ma, sc, tc, face;
		if (ax >= ay && ax >= az) {
			ma = ax;
			face = x > 0 ? 0 : 1;
			sc = x > 0 ? -z : z;
			tc = -y;
		} else if (ay >= az) {
			ma = ay;
			face = y > 0 ? 2 : 3;
			sc = x;
			tc = y > 0 ? z : -z;
		} else {
			ma = az;
			face = z > 0 ? 4 : 5;
			sc = z > 0 ? x : -x;
			tc = -y;
		}
		if (ma <= 0)
			ma = 1;
		out[0] = face;
		out[1] = .5 * (sc / ma + 1);
		out[2] = .5 * (tc / ma + 1);
	}

	// Bilinear among the four texels around fx, fy of the width x height RGB grid starting at float `base` of rgb, wrapping across x (around the
	// horizon) or clamped; into out.
	static function bilinear(rgb:Vector<Float>, base:Int, width:Int, height:Int, fx:Float, fy:Float, wrap:Bool, out:Vector<Float>):Void {
		var x0 = Math.floor(fx), y0 = Math.floor(fy);
		var ax = fx - x0, ay = fy - y0, x1 = x0 + 1, y1 = y0 + 1;
		if (wrap) {
			x0 = (x0 % width + width) % width;
			x1 = (x1 % width + width) % width;
		} else {
			x0 = x0 < 0 ? 0 : x0 >= width ? width - 1 : x0;
			x1 = x1 < 0 ? 0 : x1 >= width ? width - 1 : x1;
		}
		y0 = y0 < 0 ? 0 : y0 >= height ? height - 1 : y0;
		y1 = y1 < 0 ? 0 : y1 >= height ? height - 1 : y1;
		var a = base + (y0 * width + x0) * 3, b = base + (y0 * width + x1) * 3;
		var c = base + (y1 * width + x0) * 3, d = base + (y1 * width + x1) * 3;
		var wa = (1 - ax) * (1 - ay), wb = ax * (1 - ay), wc = (1 - ax) * ay, wd = ax * ay;
		for (k in 0...3)
			out[k] = rgb[a + k] * wa + rgb[b + k] * wb + rgb[c + k] * wc + rgb[d + k] * wd;
	}

	/** The equirectangular image (width x height, linear RGB) in direction x, y, z, filtered, into out (r, g, b). */
	public static function sampleEquirect(rgb:Vector<Float>, width:Int, height:Int, x:Float, y:Float, z:Float, out:Vector<Float>):Void {
		directionEquirect(x, y, z, out);
		bilinear(rgb, 0, width, height, out[0] * width - .5, out[1] * height - .5, true, out);
	}

	/** cube in direction x, y, z at mip lod (between mips, both blended), into out (r, g, b). */
	public static function sampleCube(cube:CubeMap3D, x:Float, y:Float, z:Float, lod:Float, out:Vector<Float>):Void {
		var max = cube.mipCount - 1;
		lod = lod < 0 ? 0 : lod > max ? max : lod;
		var m0 = Math.floor(lod), m1 = m0 + 1 < cube.mipCount ? m0 + 1 : m0, f = lod - m0;
		directionCube(x, y, z, out);
		var face = Std.int(out[0]), s = out[1], t = out[2];
		var size0 = levelSize(cube.size, m0);
		bilinear(cube.mips[m0], face * size0 * size0 * 3, size0, size0, s * size0 - .5, t * size0 - .5, false, out);
		if (f <= 0 || m1 == m0)
			return;
		var r = out[0], g = out[1], b = out[2], size1 = levelSize(cube.size, m1);
		bilinear(cube.mips[m1], face * size1 * size1 * 3, size1, size1, s * size1 - .5, t * size1 - .5, false, out);
		out[0] = r + (out[0] - r) * f;
		out[1] = g + (out[1] - g) * f;
		out[2] = b + (out[2] - b) * f;
	}

	// The 9 spherical-harmonic basis functions at unit direction x, y, z, into out.
	static inline function basis(x:Float, y:Float, z:Float, out:Vector<Float>):Void {
		out[0] = .282095;
		out[1] = .488603 * y;
		out[2] = .488603 * z;
		out[3] = .488603 * x;
		out[4] = 1.092548 * x * y;
		out[5] = 1.092548 * y * z;
		out[6] = .315392 * (3 * z * z - 1);
		out[7] = 1.092548 * x * z;
		out[8] = .546274 * (x * x - y * y);
	}

	/** Rows y0 to y1 of an equirectangular image's projection onto the basis, added to sums (27: 9 coefficients, RGB each). */
	public static function projectRows(rgb:Vector<Float>, width:Int, height:Int, y0:Int, y1:Int, sums:Vector<Float>):Void {
		var area = (2 * Math.PI / width) * (Math.PI / height),
			d = new Vector<Float>(3),
			y = new Vector<Float>(9);
		for (py in y0...y1) {
			var v = (py + .5) / height,
				solidAngle = area * Math.sin(v * Math.PI);
			for (px in 0...width) {
				equirectDirection((px + .5) / width, v, d);
				basis(d[0], d[1], d[2], y);
				var at = (py * width + px) * 3;
				for (k in 0...9) {
					var weight = y[k] * solidAngle;
					sums[k * 3] += rgb[at] * weight;
					sums[k * 3 + 1] += rgb[at + 1] * weight;
					sums[k * 3 + 2] += rgb[at + 2] * weight;
				}
			}
		}
	}

	/** The coefficients from a whole image's sums: each band's Lambert convolution (Ramamoorthi and Hanrahan), over pi; into out. */
	public static function shFromSums(sums:Vector<Float>, out:Vector<Float>):Void
		for (k in 0...9) {
			var band = k == 0 ? 1. : k < 4 ? 2 / 3 : .25;
			for (c in 0...3)
				out[k * 3 + c] = sums[k * 3 + c] * band;
		}

	/** The irradiance over pi that coefficients sh (27) give at unit normal x, y, z, into out (r, g, b). */
	public static function evalSh(sh:Vector<Float>, x:Float, y:Float, z:Float, out:Vector<Float>):Void {
		var b = new Vector<Float>(9);
		basis(x, y, z, b);
		for (c in 0...3) {
			var sum = 0.;
			for (k in 0...9)
				sum += sh[k * 3 + c] * b[k];
			out[c] = sum;
		}
	}

	/** Rows y0 to y1 of face of cube's mip 0 from an equirectangular image, each texel 2x2 samples. */
	public static function cubeRows(rgb:Vector<Float>, width:Int, height:Int, cube:CubeMap3D, face:Int, y0:Int, y1:Int):Void {
		var size = cube.size,
			data = cube.mips[0],
			d = new Vector<Float>(3),
			color = new Vector<Float>(3);
		for (y in y0...y1)
			for (x in 0...size) {
				var at = ((face * size + y) * size + x) * 3, r = 0., g = 0., b = 0.;
				for (sy in 0...2)
					for (sx in 0...2) {
						cubeDirection(face, (x + .25 + .5 * sx) / size, (y + .25 + .5 * sy) / size, d);
						sampleEquirect(rgb, width, height, d[0], d[1], d[2], color);
						r += color[0];
						g += color[1];
						b += color[2];
					}
				data[at] = r / 4;
				data[at + 1] = g / 4;
				data[at + 2] = b / 4;
			}
	}

	/** cube's mips from 1 on, each its last box-filtered. */
	public static function boxMips(cube:CubeMap3D):Void
		for (m in 1...cube.mipCount) {
			var src = levelSize(cube.size, m - 1),
				dst = levelSize(cube.size, m),
				from = cube.mips[m - 1],
				to = cube.mips[m];
			for (face in 0...6) {
				var s = face * src * src * 3;
				for (y in 0...dst)
					for (x in 0...dst) {
						var x0 = 2 * x, y0 = 2 * y, x1 = 2 * x + 1 < src ? 2 * x + 1 : 2 * x, y1 = 2 * y + 1 < src ? 2 * y + 1 : 2 * y;
						var at = ((face * dst + y) * dst + x) * 3;
						for (c in 0...3)
							to[at + c] = .25 * (from[s + (y0 * src + x0) * 3 + c] + from[s + (y0 * src + x1) * 3 + c] + from[s + (y1 * src + x0) * 3 + c]
								+ from[s + (y1 * src + x1) * 3 + c]);
					}
			}
		}

	// Van der Corput's radical inverse in base 2 of i's 32 bits.
	static function radicalInverse(i:Int):Float {
		var bits = i << 16 | i >>> 16;
		bits = (bits & 0x55555555) << 1 | (bits & 0xAAAAAAAA) >>> 1;
		bits = (bits & 0x33333333) << 2 | (bits & 0xCCCCCCCC) >>> 2;
		bits = (bits & 0x0F0F0F0F) << 4 | (bits & 0xF0F0F0F0) >>> 4;
		bits = (bits & 0x00FF00FF) << 8 | (bits & 0xFF00FF00) >>> 8;
		return (bits < 0 ? bits + 4294967296. : bits) * 2.3283064365386963e-10;
	}

	/** Mip mip's prefilter samples, the same for every texel of the mip: n Hammersley points through GGX at roughness mip / (mipCount - 1),
		those below the horizon left out, into out (four floats each: the light direction about +z, its z its weight n.l, and the source mip it
		reads, blurrier where samples are sparse: filtered importance sampling); how many are kept. */
	public static function prefilterSamples(source:CubeMap3D, mip:Int, mipCount:Int, n:Int, out:Vector<Float>):Int {
		var texelSolidAngle = 4 * Math.PI / (6 * source.size * source.size);
		var roughness = mipCount > 1 ? mip / (mipCount - 1) : 0., alpha = roughness * roughness, a2 = alpha * alpha, kept = 0;
		for (i in 0...n) {
			var phi = 2 * Math.PI * i / n, xi = radicalInverse(i);
			var cosTheta = Math.sqrt((1 - xi) / (1 + (a2 - 1) * xi)),
				sinTheta = Math.sqrt(1 - cosTheta * cosTheta);
			var hx = sinTheta * Math.cos(phi), hy = sinTheta * Math.sin(phi), hz = cosTheta;
			// n reflected about h, n = +z.
			var lz = 2 * hz * hz - 1;
			if (lz <= 0)
				continue;
			var dd = hz * hz * (a2 - 1) + 1;
			// D n.h / (4 v.h), with v.h = n.h.
			var pdf = a2 / (Math.PI * dd * dd) * .25;
			out[kept * 4] = 2 * hz * hx;
			out[kept * 4 + 1] = 2 * hz * hy;
			out[kept * 4 + 2] = lz;
			out[kept * 4 + 3] = .5 * Math.log(1 / (n * pdf + 1e-6) / texelSolidAngle) / Math.log(2) + 1;
			kept++;
		}
		return kept;
	}

	/** Rows y0 to y1 of face of out's mip mip, from source through count samples (prefilterSamples'); mip 0 is source as it is, at out's size. */
	public static function prefilterRows(source:CubeMap3D, out:CubeMap3D, mip:Int, face:Int, y0:Int, y1:Int, samples:Vector<Float>, count:Int):Void {
		var s = levelSize(out.size, mip),
			data = out.mips[mip],
			n = new Vector<Float>(3),
			color = new Vector<Float>(3);
		for (y in y0...y1)
			for (x in 0...s) {
				var at = ((face * s + y) * s + x) * 3;
				cubeDirection(face, (x + .5) / s, (y + .5) / s, n);
				var nx = n[0], ny = n[1], nz = n[2];
				if (mip == 0) {
					sampleCube(source, nx, ny, nz, Math.log(source.size / s) / Math.log(2), color);
					data[at] = color[0];
					data[at + 1] = color[1];
					data[at + 2] = color[2];
					continue;
				}
				// A frame about n: tx, ty, n.
				var ux = Math.abs(nz) < .999 ? 0. : 1.,
					uz = Math.abs(nz) < .999 ? 1. : 0.;
				var tx = 0 * nz - uz * ny,
					ty = uz * nx - ux * nz,
					tz = ux * ny - 0 * nx,
					tl = Math.sqrt(tx * tx + ty * ty + tz * tz);
				tx /= tl;
				ty /= tl;
				tz /= tl;
				var bx = ny * tz - nz * ty,
					by = nz * tx - nx * tz,
					bz = nx * ty - ny * tx;
				var r = 0., g = 0., b = 0., weight = 0.;
				for (i in 0...count) {
					var kx = samples[i * 4],
						ky = samples[i * 4 + 1],
						kz = samples[i * 4 + 2];
					sampleCube(source, tx * kx + bx * ky + nx * kz, ty * kx + by * ky + ny * kz, tz * kx + bz * ky + nz * kz, samples[i * 4 + 3], color);
					r += color[0] * kz;
					g += color[1] * kz;
					b += color[2] * kz;
					weight += kz;
				}
				if (weight > 0) {
					data[at] = r / weight;
					data[at + 1] = g / weight;
					data[at + 2] = b / weight;
				}
			}
	}

	/** value as an IEEE half float's bits, rounded to nearest; past the largest finite half, the largest. */
	public static function halfOf(value:Float):Int {
		var bits = FPHelper.floatToI32(value);
		var sign = (bits >>> 16) & 0x8000,
			exponent = ((bits >>> 23) & 0xFF) - 127 + 15,
			mantissa = bits & 0x7FFFFF;
		if ((bits >>> 23) & 0xFF == 0xFF)
			return sign | 0x7C00 | (mantissa != 0 ? 0x200 : 0);
		if (exponent >= 31)
			return sign | 0x7BFF;
		if (exponent <= 0) {
			if (exponent < -10)
				return sign;
			mantissa |= 0x800000;
			var shift = 14 - exponent;
			return sign | ((mantissa + (1 << (shift - 1))) >>> shift);
		}
		// A carry out of the mantissa bumps the exponent, as it should.
		var half = (exponent << 10) + ((mantissa + 0x1000) >>> 13);
		return sign | (half >= 0x7C00 ? 0x7BFF : half);
	}

	// A level's RGB floats as RGBA half floats (alpha 1).
	static function halfLevel(rgb:Vector<Float>):Bytes {
		var texels = Std.int(rgb.length / 3),
			out = Bytes.alloc(texels * 8),
			one = halfOf(1);
		for (i in 0...texels) {
			out.setUInt16(i * 8, halfOf(rgb[i * 3]));
			out.setUInt16(i * 8 + 2, halfOf(rgb[i * 3 + 1]));
			out.setUInt16(i * 8 + 4, halfOf(rgb[i * 3 + 2]));
			out.setUInt16(i * 8 + 6, one);
		}
		return out;
	}

	// The BRDF table's next row.
	static function brdfRow():Void {
		if (brdf == null)
			brdf = Bytes.alloc(BRDF_SIZE * BRDF_SIZE * 4);
		var y = brdfRows, roughness = (y + .5) / BRDF_SIZE, alpha = roughness * roughness, k = alpha * .5;
		var hx = new Vector<Float>(BRDF_SAMPLES),
			hy = new Vector<Float>(BRDF_SAMPLES),
			hz = new Vector<Float>(BRDF_SAMPLES);
		for (i in 0...BRDF_SAMPLES) {
			var phi = 2 * Math.PI * i / BRDF_SAMPLES, xi = radicalInverse(i);
			var cosTheta = Math.sqrt((1 - xi) / (1 + (alpha * alpha - 1) * xi)),
				sinTheta = Math.sqrt(Math.max(0, 1 - cosTheta * cosTheta));
			hx[i] = sinTheta * Math.cos(phi);
			hy[i] = sinTheta * Math.sin(phi);
			hz[i] = cosTheta;
		}
		for (x in 0...BRDF_SIZE) {
			var nDotV = (x + .5) / BRDF_SIZE, vx = Math.sqrt(1 - nDotV * nDotV), a = 0., b = 0.;
			for (i in 0...BRDF_SAMPLES) {
				var vDotH = vx * hx[i] + nDotV * hz[i];
				var nDotL = 2 * vDotH * hz[i] - nDotV;
				if (nDotL <= 0)
					continue;
				nDotL = nDotL > 1 ? 1 : nDotL;
				var nDotH = hz[i] < 0 ? 0 : hz[i] > 1 ? 1 : hz[i];
				var vh = vDotH < 0 ? 0 : vDotH > 1 ? 1 : vDotH;
				var g = (nDotV / (nDotV * (1 - k) + k)) * (nDotL / (nDotL * (1 - k) + k));
				var visible = g * vh / (nDotH * nDotV + 1e-6),
					fc = Math.pow(1 - vh, 5);
				a += (1 - fc) * visible;
				b += fc * visible;
			}
			var at = (y * BRDF_SIZE + x) * 4;
			brdf.set(at, byte(a / BRDF_SAMPLES));
			brdf.set(at + 1, byte(b / BRDF_SAMPLES));
			brdf.set(at + 2, 0);
			brdf.set(at + 3, 255);
		}
		brdfRows++;
	}

	static inline function byte(value:Float):Int {
		var b = Math.round(value * 255);
		return b < 0 ? 0 : b > 255 ? 255 : b;
	}
}

/** A cubemap of linear RGB floats with its mips: mips[m] holds the six faces of (size >> m) squared texels each, three floats a texel. */
class CubeMap3D {
	/** Its face size at mip 0. */
	public final size:Int;

	/** How many mips. */
	public final mipCount:Int;

	/** Each mip's texels, zero to start. */
	public final mips:Array<Vector<Float>> = [];

	/** An all-black cube of size with mipCount mips. */
	public function new(size:Int, mipCount:Int) {
		this.size = size;
		this.mipCount = mipCount;
		for (m in 0...mipCount) {
			var s = size >> m > 0 ? size >> m : 1,
				data = new Vector<Float>(6 * s * s * 3);
			for (i in 0...data.length)
				data[i] = 0;
			mips.push(data);
		}
	}
}

/** What a bake does next. */
private enum abstract BakeStage(Int) {
	var Brdf;
	var Decode;
	var Irradiance;
	var Source;
	var Prefilter;
	var Pack;
	var Done;
}
