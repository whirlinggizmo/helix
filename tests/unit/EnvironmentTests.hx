import haxe.ds.Vector;
import haxe.io.Bytes;
import helix.render3d.EnvironmentBake3D;
import helix.render3d.Hdr;

/** Environment maps' CPU half: the direction mappings, the irradiance, the cubes and their prefiltering, half floats, the BRDF table, .hdr
	decoding and a whole bake. */
class EnvironmentTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function near(a:Float, b:Float, tolerance:Float):Bool
		return Math.abs(a - b) <= tolerance;

	// A width x height equirectangular image whose every pixel is radiance(x, y, z) of its direction.
	static function image(width:Int, height:Int, radiance:(Float, Float, Float) -> Float):Vector<Float> {
		var rgb = new Vector<Float>(width * height * 3),
			d = new Vector<Float>(3);
		for (y in 0...height)
			for (x in 0...width) {
				EnvironmentBake3D.equirectDirection((x + .5) / width, (y + .5) / height, d);
				var value = radiance(d[0], d[1], d[2]);
				for (c in 0...3)
					rgb[(y * width + x) * 3 + c] = value;
			}
		return rgb;
	}

	static function main():Void {
		var out = new Vector<Float>(3), back = new Vector<Float>(3);
		EnvironmentBake3D.equirectDirection(.5, .5, out);
		check(near(out[2], -1, 1e-9), "The equirectangular image's middle looks toward -z");
		EnvironmentBake3D.equirectDirection(.75, .5, out);
		check(near(out[0], 1, 1e-9), "A quarter on looks toward +x");
		EnvironmentBake3D.equirectDirection(.3, 0, out);
		check(near(out[1], 1, 1e-9), "v = 0 is straight up");
		for (i in 0...50) {
			var u = .01 + .98 * ((i * 37) % 50) / 50, v = .02 + .96 * i / 50;
			EnvironmentBake3D.equirectDirection(u, v, out);
			EnvironmentBake3D.directionEquirect(out[0], out[1], out[2], back);
			check(near(back[0], u, 1e-9) && near(back[1], v, 1e-9), 'Equirectangular $u, $v comes back');
		}
		for (face in 0...6)
			for (i in 0...5) {
				var s = .1 + .2 * i, t = .9 - .17 * i;
				EnvironmentBake3D.cubeDirection(face, s, t, out);
				EnvironmentBake3D.directionCube(out[0], out[1], out[2], back);
				check(Std.int(back[0]) == face && near(back[1], s, 1e-9) && near(back[2], t, 1e-9), 'Cube face $face at $s, $t comes back');
			}
		EnvironmentBake3D.cubeDirection(0, .5, .5, out);
		check(near(out[0], 1, 1e-9), "Face 0 is +x");
		EnvironmentBake3D.cubeDirection(2, .5, .5, out);
		check(near(out[1], 1, 1e-9), "Face 2 is +y");
		EnvironmentBake3D.cubeDirection(5, .5, .5, out);
		check(near(out[2], -1, 1e-9), "Face 5 is -z");

		// Irradiance over pi: a constant sky gives back its radiance; a linear one, two thirds of it along the normal.
		var w = 256, h = 128, sums = new Vector<Float>(27), sh = new Vector<Float>(27);
		for (i in 0...27)
			sums[i] = 0;
		EnvironmentBake3D.projectRows(image(w, h, (x, y, z) -> 2), w, h, 0, h, sums);
		EnvironmentBake3D.shFromSums(sums, sh);
		for (n in [[0., 1, 0], [1., 0, 0], [0., 0, -1], [.6, -.8, 0]]) {
			EnvironmentBake3D.evalSh(sh, n[0], n[1], n[2], out);
			check(near(out[0], 2, 2e-3) && near(out[2], 2, 2e-3), 'A constant environment lights $n as itself: ${out[0]}');
		}
		for (i in 0...27)
			sums[i] = 0;
		EnvironmentBake3D.projectRows(image(w, h, (x, y, z) -> 1 + .5 * x - y), w, h, 0, h, sums);
		EnvironmentBake3D.shFromSums(sums, sh);
		for (n in [[0., 1, 0], [1., 0, 0], [0., 0, 1], [-.6, -.8, 0]]) {
			EnvironmentBake3D.evalSh(sh, n[0], n[1], n[2], out);
			check(near(out[1], 1 + 2 / 3 * (.5 * n[0] - n[1]), 2e-3), 'A linear environment lights $n by its cosine lobe: ${out[1]}');
		}

		// Cubes: a constant image stays constant through the cube, its mips and every prefiltered mip; mip 0 is the source.
		var flatImage = image(w, h, (x, y, z) -> 3);
		var cube = new CubeMap3D(32, 6);
		for (face in 0...6)
			EnvironmentBake3D.cubeRows(flatImage, w, h, cube, face, 0, 32);
		EnvironmentBake3D.boxMips(cube);
		var constant = true;
		for (m in 0...6)
			for (x in cube.mips[m])
				constant = constant && near(x, 3, 1e-9);
		check(constant, "A constant image makes a constant cube, every mip");
		var skyImage = image(w, h, (x, y, z) -> y > 0 ? 1 + 3 * y : .2);
		var sky = new CubeMap3D(32, 6);
		for (face in 0...6)
			EnvironmentBake3D.cubeRows(skyImage, w, h, sky, face, 0, 32);
		EnvironmentBake3D.boxMips(sky);
		var filtered = new CubeMap3D(16, 5),
			samples = new Vector<Float>(96 * 4);
		for (m in 0...5) {
			var count = m > 0 ? EnvironmentBake3D.prefilterSamples(sky, m, 5, 96, samples) : 0;
			for (face in 0...6)
				EnvironmentBake3D.prefilterRows(sky, filtered, m, face, 0, 16 >> m, samples, count);
		}
		EnvironmentBake3D.sampleCube(sky, .3, .8, -.2, 1, out);
		EnvironmentBake3D.sampleCube(filtered, .3, .8, -.2, 0, back);
		check(near(out[0], back[0], 1e-6), "The prefiltered mip 0 is the source at its size");
		// Its average radiance stays put as it blurs (each mip's texels weighted by their solid angle, near enough by count here).
		var means = [];
		for (m in 0...5) {
			var sum = 0.;
			for (i in 0...Std.int(filtered.mips[m].length / 3))
				sum += filtered.mips[m][i * 3];
			means.push(sum / (filtered.mips[m].length / 3));
		}
		for (m in 1...5)
			check(near(means[m], means[0], means[0] * .08), 'Prefiltered mip $m keeps the energy: ${means[m]} against ${means[0]}');
		EnvironmentBake3D.sampleCube(filtered, 0, 1, 0, 4, out);
		EnvironmentBake3D.sampleCube(filtered, 0, 1, 0, 0, back);
		check(out[0] < back[0], "The roughest mip is dimmer straight up than the sharp one: blurred toward the dark ground");
		var count = EnvironmentBake3D.prefilterSamples(sky, 0, 5, 96, samples);
		check(count == 96, "Roughness 0 keeps every sample");

		// Half floats, against IEEE's.
		for (pair in [
			[1., 0x3C00],
			[.5, 0x3800],
			[-2., 0xC000],
			[65504., 0x7BFF],
			[1e6, 0x7BFF],
			[0., 0],
			[1 / 3, 0x3555],
			[.1, 0x2E66],
			[6.103515625e-5, 0x0400],
			[5.960464477539063e-8, 0x0001],
			[1e-9, 0],
			[2050.5, 0x6801],
			[2051.5, 0x6802]
		])
			check(EnvironmentBake3D.halfOf(pair[0]) == Std.int(pair[1]),
				'Half of ${pair[0]} is ${StringTools.hex(Std.int(pair[1]))}, not ${StringTools.hex(EnvironmentBake3D.halfOf(pair[0]))}');

		// .hdr: a flat one and a run-length encoded one.
		var flatHdr = hdr(2, 2, false), rle = hdr(16, 3, true);
		var decoded = Hdr.read(flatHdr);
		check(decoded.width == 2 && decoded.height == 2, "A flat .hdr's size");
		check(near(decoded.rgb[0], 1, 1e-9) && near(decoded.rgb[1], .5, 1e-9) && near(decoded.rgb[2], 0, 1e-9), "A flat .hdr's first pixel");
		check(near(decoded.rgb[3 * 3], 4 * 3 / 128, 1e-9), "A flat .hdr's last pixel");
		var long = Hdr.read(rle);
		check(long.width == 16 && long.height == 3, "A run-length encoded .hdr's size");
		var right = true;
		for (y in 0...3)
			for (x in 0...16)
				right = right
					&& near(long.rgb[(y * 16 + x) * 3], (x < 8 ? 64 : x) / 128 * 2, 1e-9)
					&& near(long.rgb[(y * 16 + x) * 3 + 2], y / 128 * 2, 1e-9);
		check(right, "A run-length encoded .hdr's pixels");
		check(!Hdr.isHdr(Bytes.ofString("#?RADIANCE\nFORMAT=32-bit_rle_xyze\n\n-Y 1 +X 1\n")), "Another format isn't read");
		var broken = rle.sub(0, rle.length - 5);
		check(try {
			Hdr.read(broken);
			false;
		} catch (e:Dynamic) true, "A cut-short .hdr throws");

		// A whole bake, from an 8-bit image: the BRDF table, the irradiance and both cubes' levels.
		var rgba = Bytes.alloc(64 * 32 * 4);
		for (i in 0...64 * 32)
			rgba.setInt32(i * 4, i < 64 * 16 ? 0xffffffff : 0xff202020);
		var bake = EnvironmentBake3D.fromRgba(64, 32, rgba);
		while (!bake.run(1000)) {}
		check(bake.lightingLevels.length == EnvironmentBake3D.MIP_COUNT
			&& bake.lightingLevels[0].length == 6 * 128 * 128 * 8, "The lighting cube's levels");
		check(bake.backgroundSize == 64 && bake.backgroundLevels.length == 7 && bake.backgroundLevels[6].length == 6 * 8,
			"The background cube's levels, down to 1");
		EnvironmentBake3D.evalSh(bake.irradiance, 0, 1, 0, out);
		EnvironmentBake3D.evalSh(bake.irradiance, 0, -1, 0, back);
		check(out[0] > .7 && back[0] < .3, 'White above, dark below: up ${out[0]}, down ${back[0]}');

		// The BRDF table: smooth is exactly Schlick's split; A + B never above 1; Unreal's (0.72, 0.02) at n.v 0.5, roughness 0.5.
		var table = EnvironmentBake3D.brdfTable,
			size = EnvironmentBake3D.BRDF_SIZE;
		check(table != null && table.length == size * size * 4, "The BRDF table is made");
		var nv = (40 + .5) / size, fc = Math.pow(1 - nv, 5);
		check(near(table.get(40 * 4) / 255, 1 - fc, .02) && near(table.get(40 * 4 + 1) / 255, fc, .02), "Smooth: Schlick's split");
		var sumsOk = true, falling = true;
		for (y in 0...size)
			for (x in 0...size) {
				var at = (y * size + x) * 4;
				sumsOk = sumsOk && table.get(at) + table.get(at + 1) <= 256;
				if (y > 0 && x >= 16) {
					var above = ((y - 1) * size + x) * 4;
					falling = falling && table.get(at) + table.get(at + 1) <= table.get(above) + table.get(above + 1) + 1;
				}
			}
		check(sumsOk, "A + B is at most 1");
		check(falling, "A + B falls as roughness rises, for n.v of a quarter and up");
		var mid = (32 * size + 32) * 4;
		check(near(table.get(mid) / 255, .72, .03) && near(table.get(mid + 1) / 255, .02, .02),
			'Half and half: ${table.get(mid) / 255}, ${table.get(mid + 1) / 255}');
		Sys.println('{"passed":true,"checks":$checks}');
	}

	// A .hdr of width x height: flat, each pixel 1, 0.5, 0 but the last, 0.09375, 0, 0; or run-length encoded, red a run of eight 64s then
	// literals x, green 0, blue the row (each a byte, 1/64 of one).
	static function hdr(width:Int, height:Int, encoded:Bool):Bytes {
		var out = new haxe.io.BytesBuffer();
		out.addString("#?RADIANCE\n# made by a test\nFORMAT=32-bit_rle_rgbe\n\n-Y " + height + " +X " + width + "\n");
		if (!encoded) {
			// e = 129: a byte is worth 1 / 128; e = 128, 1 / 256.
			for (i in 0...width * height) {
				var last = i == width * height - 1;
				for (b in (last ? [24, 0, 0, 128] : [128, 64, 0, 129]))
					out.addByte(b);
			}
			return out.getBytes();
		}
		for (y in 0...height) {
			out.addByte(2);
			out.addByte(2);
			out.addByte(width >> 8);
			out.addByte(width & 255);
			// e = 130: a byte is worth 1 / 64.
			for (c in 0...4) {
				var values = [for (x in 0...width) c == 0 ? (x < 8 ? 64 : x) : c == 1 ? 0 : c == 2 ? y : 130];
				out.addByte(128 + 8);
				out.addByte(values[0]);
				out.addByte(width - 8);
				for (x in 8...width)
					out.addByte(values[x]);
			}
		}
		return out.getBytes();
	}
}
