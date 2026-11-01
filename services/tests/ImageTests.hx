import haxe.crypto.Crc32;
import haxe.io.Bytes;
import helix.math.Random;
import helix.services.fonts.Font2D;
import helix.services.fonts.Glyph2D;
import helix.services.images.Image;

/** Checks Image's operations: the pixels of a few cases of each pinned by their CRC-32, each the value raylib's own function gives the
	same input (compiled from its C, R8G8B8A8: 5.5's, and 6.2's for the lines and the filled circle); and the behaviour around them: the byte order, clipping, the filters of this library's
	own (`Bilinear`, `Bicubic`, the mipmaps), scaled drawing, and where it differs from raylib by design (alpha kept by `grayscale` and
	`convolve`, `dither` left 8-bit, `crop` outside, `resizeCanvas` at the same size). */
@:access(helix.services.fonts)
class ImageTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static var state = 0;

	// Pixels from xorshift32, every byte (alpha too) its own: the comparison's inputs.
	// Degrees as raylib's ImageRotate turns them to radians, in float32.
	static function angle(degrees:Float):Float
		return f32(f32(f32(degrees) * f32(Math.PI)) / 180);

	// Degrees as raylib's GenImageGradientLinear turns them, (90 - direction) already taken, to radians.
	static function direction(degrees:Float):Float
		return f32(f32(f32(degrees) / 180) * f32(3.14159));

	// An image's alpha border as x, y, width and height, or "empty".
	static function border(image:Image, threshold:Float):String {
		var b = image.getAlphaBorder(threshold);
		return b.isEmpty ? "empty" : [b.minX, b.minY, b.width, b.height].join(",");
	}

	static function f32(value:Float):Float
		return haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(value));

	static function noise(width:Int, height:Int, seed = 1):Image {
		state = seed;
		var bytes = Bytes.alloc(width * height * 4);
		for (i in 0...bytes.length) {
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			bytes.set(i, (state >>> 8) & 255);
		}
		return new Image("", width, height, bytes);
	}

	static function opaque(width:Int, height:Int):Image {
		var image = noise(width, height);
		for (i in 0...width * height)
			image.pixels.set(i * 4 + 3, 255);
		return image;
	}

	static function changed(image:Image, change:Image->Void):Image {
		change(image);
		return image;
	}

	// An image's size and pixels against raylib's.
	static function pin(name:String, image:Image, width:Int, height:Int, crc:Int):Void
		check(image.width == width && image.height == height && Crc32.make(image.pixels) == crc,
			'$name: ${image.width}x${image.height} ${StringTools.hex(Crc32.make(image.pixels), 8)}');

	// A font of 9 glyphs cut from a noise atlas, in whole pixels, as the comparison made raylib's.
	static function font():Font2D {
		var chars = "?ABCabc! ";
		var atlas = Image.filled(64, 16, 0xffffffff),
			alpha = noise(64, 16, 42);
		for (i in 0...64 * 16)
			atlas.pixels.set(i * 4 + 3, alpha.pixels.get(i));
		var glyphs = [];
		for (k in 0...9) {
			var space = k == 8,
				w = space ? 0 : 4 + k % 3,
				h = space ? 0 : 8 + k % 4;
			glyphs.push(new Glyph2D(chars.charCodeAt(k), k * 7, (k % 2) * 4, w, h, space ? 0 : k % 3 - 1, space ? 0 : -h + k % 2,
				space ? 4 : k == 4 ? 0 : w + 1));
		}
		return new Font2D(14, 11, -3, 0, atlas, glyphs);
	}

	static function main():Void {
		var A = 0xff2080e0, B = 0x40f0a010;

		// Made.
		pin("gradientLinear", Image.gradientLinear(64, 48, direction(30), A, B), 64, 48, 0x09fa35d5);
		pin("gradientRadial", Image.gradientRadial(33, 33, 0.3, A, B), 33, 33, 0x637859bf);
		pin("gradientSquare", Image.gradientSquare(7, 13, 0.5, A, B), 7, 13, 0x69b2658a);
		pin("checked", Image.checked(17, 9, 3, 2, A, B), 17, 9, 0x62a34b45);
		pin("whiteNoise", Image.whiteNoise(64, 48, 0.5, new Random(7)), 64, 48, 0x69c49ecf);
		pin("perlinNoise", Image.perlinNoise(48, 64, 10, -5, 4.5), 48, 64, 0x5e15e7ba);
		pin("cellular", Image.cellular(50, 30, 7, new Random(12)), 50, 30, 0xffe57f42);
		pin("copy", noise(7, 13).copy(), 7, 13, 0xf65e7300);
		pin("getChannel", noise(7, 13).getChannel(2), 7, 13, 0xa4d06a40);
		var solid = Image.filled(3, 2, 0x80102030);
		check(solid.pixels.get(0) == 0x10 && solid.pixels.get(1) == 0x20 && solid.pixels.get(2) == 0x30 && solid.pixels.get(3) == 0x80,
			"pixels are red, green, blue, alpha");
		check(solid.getPixel(2, 1) == 0x80102030 && solid.getPixel(3, 0) == 0 && solid.getPixel(0, -1) == 0, "getPixel, 0 outside");
		var ramp = Image.gradientLinear(16, 4, direction(0), 0xff000000, 0xffffffff);
		check(ramp.getPixel(0, 0) & 255 < 16 && ramp.getPixel(15, 3) & 255 > 239, "0 degrees runs left to right");
		ramp = Image.gradientLinear(4, 16, direction(90), 0xff000000, 0xffffffff);
		check(ramp.getPixel(3, 0) & 255 < 16 && ramp.getPixel(0, 15) & 255 > 239, "90 degrees runs top to bottom");
		check(Crc32.make(Image.whiteNoise(9, 9, 0.5, new Random(3)).pixels) == Crc32.make(Image.whiteNoise(9, 9, 0.5, new Random(3)).pixels),
			"the same seed gives the same noise");
		check(Image.whiteNoise(4, 4, 0, new Random(3)).getPalette(10).join(",") == "" + 0xff000000, "no chance of white is all black");
		check(Image.checked(4, 4, 2, 2, A, B).getPixel(2, 0) == B
			&& Image.checked(4, 4, 0, 0, A, B).getPixel(1, 0) == B, "squares, a size of 0 taken as 1");

		// Resized.
		pin("crop", noise(64, 48).crop(-4, -2, 10, 10), 6, 8, 0x51ff72da);
		pin("resize Nearest", noise(7, 13).resize(32, 24, Nearest), 32, 24, 0xb1b29d30);
		pin("resizeCanvas", noise(64, 48).resizeCanvas(80, 60, -5, -7, B), 80, 60, 0xd1ec22f9);
		pin("toPowerOfTwo", noise(3, 5).toPowerOfTwo(B), 4, 8, 0x116ea935);
		pin("rotate 30", noise(64, 48).rotate(angle(30)), 79, 73, 0x2822ba29);
		pin("rotate -45", noise(7, 13).rotate(angle(-45)), 14, 14, 0x35b290c6);
		pin("rotate 90", noise(40, 40).rotate(angle(90)), 40, 40, 0x7214830d);
		pin("rotateClockwise", noise(7, 13).rotateClockwise(), 13, 7, 0x91b1ac1d);
		pin("rotateCounterclockwise", noise(7, 13).rotateCounterclockwise(), 13, 7, 0x8d5b4271);
		var framed = noise(40, 30, 3);
		for (y in 0...30)
			for (x in 0...40)
				if (x < 4 || y < 3 || x >= 35 || y >= 28)
					framed.pixels.set((y * 40 + x) * 4 + 3, 0);
		pin("cropAlpha", framed.cropAlpha(0.5), 31, 25, 0x279d691b);
		check(border(framed, 0.5) == "4,3,31,25", "getAlphaBorder");
		check(border(Image.filled(5, 5, 0), 0) == "empty", "no border in a clear image");
		check(noise(8, 8).crop(9, 0, 4, 4).width == 0
			&& noise(8, 8).crop(2, 2, -1, 3).height == 0, "a rectangle outside crops to nothing");
		var shifted = Image.filled(4, 4, A).resizeCanvas(4, 4, 1, 2, B);
		check(shifted.getPixel(0, 0) == B && shifted.getPixel(1, 2) == A && shifted.getPixel(3, 3) == A, "the same size, moved");
		var mixed = new Image("", 2, 1, Bytes.ofHex("ff000080ffffffff"));
		var halved = mixed.resize(1, 1, Bilinear).getPixel(0, 0);
		check(halved >>> 24 == 0xc0 && (halved >> 16) & 255 == 255 && halved & 255 == 170, "Bilinear weights colors by alpha");
		var flat = Image.filled(5, 7, A);
		check(flat.resize(13, 3, Bilinear).getPalette(9).join(",") == "" + A
			&& flat.resize(9, 11, Bicubic).getPalette(9).join(",") == "" + A,
			"one color stays one color");
		var edge = new Image("", 4, 1, Bytes.ofHex("000000ff000000ffffffffffffffffff")).resize(8, 1, Bicubic);
		check(edge.getPixel(0, 0) & 255 == 0 && edge.getPixel(7, 0) & 255 == 255 && edge.getPixel(4, 0) & 255 > edge.getPixel(3, 0) & 255,
			"Bicubic keeps the ends and rises between");
		check(noise(8, 8).resize(0, 4, Bilinear).width == 0, "a size of 0 is empty");
		var mips = noise(8, 3).getMipmaps();
		check(mips.map(m -> m.width + "x" + m.height).join(" ") == "4x1 2x1 1x1", "mipmaps halve to 1 by 1");
		var quad = new Image("", 2, 2, Bytes.ofHex("000000ff404040ff808080ffc0c0c0ff"));
		check(quad.getMipmaps()[0].getPixel(0, 0) == 0xff606060 && noise(1, 1).getMipmaps().length == 0, "a mipmap averages 2 by 2");

		// Changed in place.
		pin("flipVertical", changed(noise(7, 13), i -> i.flipVertical()), 7, 13, 0xf1be6e2b);
		pin("flipHorizontal", changed(noise(7, 13), i -> i.flipHorizontal()), 7, 13, 0x66e31aee);
		pin("tint", changed(noise(7, 13), i -> i.tint(0x80ff4020)), 7, 13, 0xea0c2f0d);
		pin("invert", changed(noise(7, 13), i -> i.invert()), 7, 13, 0x192bf1f4);
		pin("grayscale", changed(opaque(7, 13), i -> i.grayscale()), 7, 13, 0xd7a3a620);
		pin("contrast -100", changed(noise(7, 13), i -> i.contrast(-100)), 7, 13, 0x810b2da6);
		pin("contrast 30", changed(noise(7, 13), i -> i.contrast(30)), 7, 13, 0xe0a7be56);
		pin("brighten", changed(noise(7, 13), i -> i.brighten(-40)), 7, 13, 0xbf38fa10);
		pin("clearAlpha", changed(noise(7, 13), i -> i.clearAlpha(B, 0.3)), 7, 13, 0x1bfc211b);
		pin("maskAlpha", changed(noise(7, 13), i -> i.maskAlpha(noise(7, 13, 77))), 7, 13, 0x54087d04);
		pin("premultiplyAlpha", changed(noise(7, 13), i -> i.premultiplyAlpha()), 7, 13, 0x14d0e1df);
		pin("replaceColor", changed(Image.checked(16, 16, 4, 4, A, B), i -> i.replaceColor(A, 0x12345678)), 16, 16, 0x05457143);
		pin("blur 1", changed(opaque(9, 6), i -> i.blur(1)), 9, 6, 0x30302265);
		pin("blur 4", changed(noise(13, 30), i -> i.blur(4)), 13, 30, 0xbcf4acbe);
		pin("convolve 3x3", changed(noise(7, 13), i -> i.convolve([0, -1, 0, -1, 5, -1, 0, -1, 0])), 7, 13, 0x5d7f145b);
		pin("convolve 5x5", changed(noise(7, 13), i -> i.convolve([
			for (v in [
				1, 4, 6, 4, 1, 4, 16, 24, 16, 4, 6, 24, 36, 24, 6, 4, 16, 24, 16, 4, 1, 4, 6, 4, 1
			])
				v / 256
		])), 7, 13, 0xf463be87);
		pin("dither 565", changed(noise(7, 13), i -> i.dither(5, 6, 5, 0)), 7, 13, 0xe750c8b4);
		pin("dither 4444", changed(noise(7, 13), i -> i.dither(4, 4, 4, 4)), 7, 13, 0x7dd785e9);
		var gray = changed(noise(3, 3), i -> i.grayscale());
		check(gray.pixels.get(4) == gray.pixels.get(5) && gray.pixels.get(7) == noise(3, 3).pixels.get(7), "grayscale keeps alpha");
		var sharp = changed(noise(5, 5), i -> i.convolve([0, -1, 0, -1, 5, -1, 0, -1, 0]));
		check(sharp.pixels.get(3) == noise(5, 5).pixels.get(3)
			&& sharp.pixels.get(99) == noise(5, 5).pixels.get(99), "convolve keeps alpha");
		check(Crc32.make(changed(noise(5, 5), i -> i.convolve([1, 2])).pixels) == Crc32.make(noise(5, 5).pixels), "a kernel not square does nothing");
		check(Crc32.make(changed(noise(5, 5), i -> i.dither(8, 8, 8, 8)).pixels) == Crc32.make(noise(5, 5).pixels), "8 bits keeps the levels");
		var levels = changed(noise(16, 16), i -> i.dither(1, 1, 1, 0)).getPalette(100);
		check(levels.length <= 8
			&& levels.filter(c -> c >>> 24 != 255
				|| [for (k in 0...3) (c >> k * 8) & 255].filter(v -> v != 0 && v != 255).length > 0).length == 0,
			"1 bit a channel leaves 0 or 255, opaque without alpha bits");
		check(Crc32.make(changed(noise(5, 5), i -> i.blur(0)).pixels) == Crc32.make(noise(5, 5).pixels), "a blur of 0 does nothing");
		check(changed(Image.filled(1, 1, 0xff050505), i -> i.brighten(-40)).getPixel(0, 0) == 0xff010101, "below 0 is 1, as raylib's");
		check(changed(Image.filled(2, 2, A), i -> i.maskAlpha(Image.filled(3, 2, 0))).getPixel(1, 1) == A, "a mask of another size does nothing");

		// Read.
		check(StringTools.hex(noise(64, 48).getPixel(10, 20), 8) == "735C5DDE", "getPixel");
		var paletted = Image.filled(20, 20, 0);
		state = 9;
		var pal = [
			0xff102030,
			0x00ffffff,
			0x80405060,
			0xff102031,
			0x00000000,
			0x7f7f7f7f,
			0xffffffff
		];
		for (i in 0...400) {
			state ^= state << 13;
			state ^= state >>> 17;
			state ^= state << 5;
			paletted.setPixel(i % 20, Std.int(i / 20), pal[(state >>> 8) % 7]);
		}
		check(paletted.getPalette(10).map(c -> StringTools.hex(c, 8)).join(",") == "FFFFFFFF,7F7F7F7F,FF102030,80405060,FF102031",
			"getPalette: first met, clear skipped");
		check(paletted.getPalette(2).length == 2, "getPalette stops at its most");

		// Drawn into.
		pin("drawLine", changed(noise(64, 48), i -> i.drawLine(5, 40, 60, 2, A)), 64, 48, 0x01e7706b);
		pin("drawLine clipped", changed(noise(64, 48), i -> i.drawLine(-20, -5, 80, 60, A)), 64, 48, 0x5fdd68b0);
		// One pixel: its end is drawn, where 5.5 drew nothing.
		pin("drawLine point", changed(noise(64, 48), i -> i.drawLine(7, 9, 7, 9, A)), 64, 48, 0x0e979fd6);
		pin("drawThickLine", changed(noise(64, 48), i -> i.drawThickLine(5.3, 40.6, 60.5, 2.2, 6, A)), 64, 48, 0xeb7522ca);
		// 4 thick is 4 lines, where 5.5 drew 3 across and 1 down.
		pin("drawThickLine 4 across", changed(noise(64, 48), i -> i.drawThickLine(10, 30, 50, 30, 4, A)), 64, 48, 0xc1964ac8);
		pin("drawThickLine down", changed(noise(64, 48), i -> i.drawThickLine(30, 5, 33, 40, 3, B)), 64, 48, 0xb5209eac);
		// Each row as wide either side of the middle, where 5.5's were a pixel short on the right.
		pin("drawCircle", changed(noise(64, 48), i -> i.drawCircle(60, 45, 15, A)), 64, 48, 0xabde38fa);
		pin("drawCircleLines", changed(noise(64, 48), i -> i.drawCircleLines(32, 24, 20, A)), 64, 48, 0x81a4db76);
		pin("drawRectangle", changed(noise(64, 48), i -> i.drawRectangle(-5, -5, 20, 10, B)), 64, 48, 0xd826001e);
		pin("drawRectangle 0 wide", changed(noise(64, 48), i -> i.drawRectangle(10, 10, 0, 5, B)), 64, 48, 0x35e34bfa);
		pin("drawRectangleLines", changed(noise(64, 48), i -> i.drawRectangleLines(5, 5, 20, 10, 3, B)), 64, 48, 0xcbf31987);
		pin("drawTriangle", changed(noise(64, 48), i -> i.drawTriangle(10.5, 3.25, 50.75, 20.5, 2.5, 40.125, A, A, A)), 64, 48, 0x02c65883);
		pin("drawTriangle blended", changed(noise(64, 48), i -> i.drawTriangle(5, 5, 60, 10, 30, 45, A, B, 0xff00ff00)), 64, 48, 0x7f17db16);
		pin("drawTriangleLines", changed(noise(64, 48), i -> i.drawTriangleLines(10.5, 3.25, 50.75, 20.5, 2.5, 40.125, B)), 64, 48, 0xf977df9e);
		pin("drawImage", changed(noise(64, 48), i -> i.drawImage(noise(30, 20, 5), 3, 2, 16, 16, 10.5, 7.75, 16, 16, 0xc0ff8040)), 64, 48, 0x49a86a00);
		pin("drawImage clipped", changed(noise(64, 48), i -> i.drawImage(noise(30, 20, 5), 0, 0, 30, 20, 40, -15, 30, 20, 0x80ffffff)), 64, 48, 0x88a48dd6);
		var f = font();
		pin("drawText", changed(noise(64, 48), i -> i.drawText(f, "abc!?", 0, 0, 14, 1, 0xc0ff8040)), 64, 48, 0x4f816a16);
		pin("drawText spaced", changed(noise(64, 48), i -> i.drawText(f, "Ab cA!", 5.5, 2.25, 14, 1, 0xffffffff)), 64, 48, 0x6427870b);
		var dot = Image.filled(5, 5, 0);
		dot.setPixel(2, 2, A);
		dot.setPixel(5, 2, B);
		dot.setPixel(-1, 0, B);
		check(dot.getPalette(9).join(",") == "" + A, "setPixel, outside skipped");
		var scaled = Image.filled(40, 40, 0);
		scaled.drawImage(Image.filled(2, 2, 0xffff0000), 0, 0, 2, 2, 4, 4, 8, 8, 0xffffffff);
		check(border(scaled, 0) == "4,4,8,8" && scaled.getPixel(7, 7) == 0xffff0000, "drawImage scales to its rectangle");
		var small = Image.filled(64, 48, 0), big = Image.filled(64, 48, 0);
		small.drawText(f, "AB", 0, 0, 14, 0, 0xffffffff);
		big.drawText(f, "AB", 0, 0, 28, 0, 0xffffffff);
		var s = small.getAlphaBorder(0), b = big.getAlphaBorder(0);
		check(b.width >= s.width * 2 - 2 && b.height >= s.height * 2 - 2, "drawText at twice the size draws twice as big");
		var two = Image.filled(64, 48, 0);
		two.drawText(f, "A\nA", 0, 0, 14, 0, 0xffffffff);
		check(two.getAlphaBorder(0).height > 14, "a newline starts the next line below");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
