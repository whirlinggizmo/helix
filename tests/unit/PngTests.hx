import haxe.io.Bytes;
import helix.graphics.Png;

/** The PNG encoder, checked by decoding its files again: chunks and their CRCs, the zlib stream through Haxe's own inflater, every filter
	undone, the pixels compared. */
@:access(helix)
class PngTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	public static function main():Void {
		// A flat image (long matches), a gradient with noise (every filter type wins somewhere), one pixel, and a wide one past the window.
		var seed = 7;
		function random():Int {
			seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF;
			return seed >> 16;
		}
		var images = [
			{w: 64, h: 32, at: (x:Int, y:Int, c:Int) -> c == 3 ? 255 : 40},
			{w: 37, h: 23, at: (x:Int, y:Int, c:Int) -> (x * 7 + y * 3 + c * 50 + (random() & 7)) & 0xFF},
			{w: 1, h: 1, at: (x:Int, y:Int, c:Int) -> 200 + c},
			{w: 9000, h: 3, at: (x:Int, y:Int, c:Int) -> ((x >> 4) * 13 + y + c) & 0xFF}
		];
		for (image in images) {
			var rgba = Bytes.alloc(image.w * image.h * 4);
			for (y in 0...image.h)
				for (x in 0...image.w)
					for (c in 0...4)
						rgba.set((y * image.w + x) * 4 + c, image.at(x, y, c));
			var png = Png.encode(image.w, image.h, rgba);
			var decoded = decode(png);
			check(decoded.w == image.w && decoded.h == image.h && decoded.rgba.compare(rgba) == 0, 'Round trip ${image.w}x${image.h}');
			if (image.w == 64)
				check(png.length < rgba.length / 20, "A flat image compresses");
		}
		var threw = try {
			Png.encode(0, 1, Bytes.alloc(4));
			false;
		} catch (_:Dynamic)
			true;
		check(threw, "A size of 0 throws");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}

	static function decode(png:Bytes):{w:Int, h:Int, rgba:Bytes} {
		check(png.get(0) == 0x89 && png.getString(1, 3) == "PNG", "Signature");
		var at = 8, w = 0, h = 0, idat = new haxe.io.BytesBuffer();
		while (at < png.length) {
			var length = int(png, at), type = png.getString(at + 4, 4);
			check(int(png, at + 8 + length) == haxe.crypto.Crc32.make(png.sub(at + 4, 4 + length)), type + " CRC");
			if (type == "IHDR") {
				w = int(png, at + 8);
				h = int(png, at + 12);
				check(png.get(at + 16) == 8 && png.get(at + 17) == 6, "8-bit RGBA");
			} else if (type == "IDAT")
				idat.add(png.sub(at + 8, length));
			at += 12 + length;
		}
		var filtered = haxe.zip.InflateImpl.run(new haxe.io.BytesInput(idat.getBytes())), row = w * 4;
		check(filtered.length == (row + 1) * h, "Filtered size");
		var rgba = Bytes.alloc(row * h);
		for (y in 0...h) {
			var type = filtered.get(y * (row + 1));
			for (x in 0...row) {
				var value = filtered.get(y * (row + 1) + 1 + x),
					left = x >= 4 ? rgba.get(y * row + x - 4) : 0,
					up = y > 0 ? rgba.get((y - 1) * row + x) : 0,
					upLeft = x >= 4 && y > 0 ? rgba.get((y - 1) * row + x - 4) : 0;
				var p = left + up - upLeft,
					pa = Std.int(Math.abs(p - left)),
					pb = Std.int(Math.abs(p - up)),
					pc = Std.int(Math.abs(p - upLeft));
				var predictor = switch type {
					case 0: 0;
					case 1: left;
					case 2: up;
					case 3: (left + up) >> 1;
					case _: pa <= pb && pa <= pc ? left : pb <= pc ? up : upLeft;
				}
				rgba.set(y * row + x, (value + predictor) & 0xFF);
			}
		}
		return {w: w, h: h, rgba: rgba};
	}

	static function int(b:Bytes, at:Int):Int
		return (b.get(at) << 24) | (b.get(at + 1) << 16) | (b.get(at + 2) << 8) | b.get(at + 3);
}
