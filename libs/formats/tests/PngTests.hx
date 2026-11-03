import haxe.io.Bytes;
import helix.formats.png.PngFile;

/** Checks PngFile with the library alone: its files byte for byte as raylib 5.5's stb_image_write writes them (each file's length and
	CRC-32, taken from stb_image_write compiled with gcc, on the same made-up images), for 1 to 4 channels, a single pixel, odd sizes,
	and noise stored rather than compressed; each file read back here (its chunks' CRCs, its zlib stream's Adler-32 through
	`haxe.zip.InflateImpl`, its filters undone) to the pixels written; and what throws. */
class PngTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static var state = 0;

	// The next byte of a fixed LCG, the C side's.
	static function next():Int {
		var s:haxe.Int32 = state;
		s = s * 1664525 + 1013904223;
		state = s;
		return state >>> 24;
	}

	// A made-up image's bytes, as the C side made them: 0 flat, 1 a gradient, 2 noise, 3 blocks of flat color and coarse noise,
	// 4 a gradient with a little noise, 5 flat squares with specks and a mostly opaque alpha.
	static function pixels(pattern:Int, width:Int, height:Int, channels:Int):Bytes {
		var bytes = Bytes.alloc(width * height * channels);
		state = width * 7919 + height * 104729 + channels * 31 + pattern;
		var i = 0;
		for (y in 0...height)
			for (x in 0...width)
				for (channel in 0...channels) {
					var v = switch pattern {
						case 0: (channel * 61 + 17) & 255;
						case 1: (x * 5 + y * 3 + channel * 40) & 255;
						case 2: next();
						case 3: (((x >> 2) + (y >> 2)) & 1) != 0 ? (channel * 80 + 30) & 255 : next() & 0xC0;
						case 4: (x * 2 + y + channel * 30 + (next() & 3)) & 255;
						case _ if (channel == 3): (next() & 0x1f) == 0 ? next() : 255;
						case _: ((x >> 3) * 40 + (y >> 3) * 20 + channel * 7 + ((next() & 7) == 0 ? next() & 15 : 0)) & 255;
					}
					bytes.set(i++, v);
				}
		return bytes;
	}

	// A big-endian 32-bit integer.
	static function be32(bytes:Bytes, p:Int):Int
		return (bytes.get(p) << 24) | (bytes.get(p + 1) << 16) | (bytes.get(p + 2) << 8) | bytes.get(p + 3);

	// A PNG's pixels, read back: its signature, header and chunks' CRCs checked, its zlib stream inflated with its Adler-32 checked,
	// its filters undone.
	static function decode(png:Bytes, width:Int, height:Int, channels:Int):Bytes {
		check(png.sub(0, 8).toHex() == "89504e470d0a1a0a", "the PNG signature");
		var p = 8;
		var idat = new haxe.io.BytesBuffer();
		var chunks = [];
		while (p < png.length) {
			var length = be32(png, p);
			var type = png.getString(p + 4, 4);
			check(haxe.crypto.Crc32.make(png.sub(p + 4, length + 4)) == be32(png, p + 8 + length), '$type: its CRC');
			if (type == "IHDR") {
				var ctype = [0, 0, 4, 2, 6][channels];
				check(be32(png, p + 8) == width && be32(png, p + 12) == height, "IHDR: the size");
				check(png.get(p + 16) == 8 && png.get(p + 17) == ctype, "IHDR: 8 bits, the color type");
			}
			if (type == "IDAT")
				idat.addBytes(png, p + 8, length);
			chunks.push(type);
			p += 12 + length;
		}
		check(chunks.join(",") == "IHDR,IDAT,IEND", "IHDR, IDAT and IEND");
		var row = width * channels;
		var raw = Bytes.alloc((row + 1) * height);
		var inflater = new haxe.zip.InflateImpl(new haxe.io.BytesInput(idat.getBytes()), true, true);
		var read = 0;
		while (read < raw.length) {
			var n = inflater.readBytes(raw, read, raw.length - read);
			if (n == 0)
				break;
			read += n;
		}
		check(read == raw.length, "IDAT: a byte a row and its pixels");
		var out = Bytes.alloc(row * height);
		var filters = true;
		for (y in 0...height) {
			var filter = raw.get(y * (row + 1));
			filters = filters && filter <= 4;
			for (i in 0...row) {
				var a = i >= channels ? out.get(y * row + i - channels) : 0;
				var b = y > 0 ? out.get((y - 1) * row + i) : 0;
				var c = i >= channels && y > 0 ? out.get((y - 1) * row + i - channels) : 0;
				var predicted = switch filter {
					case 1: a;
					case 2: b;
					case 3: (a + b) >> 1;
					case 4: var p = a + b - c, pa = Std.int(Math.abs(p - a)), pb = Std.int(Math.abs(p - b)), pc = Std.int(Math.abs(p - c)); pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
					case _: 0;
				}
				out.set(y * row + i, (raw.get(y * (row + 1) + 1 + i) + predicted) & 0xFF);
			}
		}
		check(filters, "each row's filter is one PNG has");
		return out;
	}

	// The PNG of a made-up image is stb_image_write's, by its length and CRC-32, and reads back to its pixels.
	static function same(pattern:Int, width:Int, height:Int, channels:Int, length:Int, crc32:Int):Void {
		var what = '$width x $height, $channels channels, pattern $pattern';
		var image = pixels(pattern, width, height, channels);
		var png = PngFile.write(width, height, channels, image);
		check(png.length == length && haxe.crypto.Crc32.make(png) == crc32, '$what: stb_image_write\'s $length bytes, CRC 0x${StringTools.hex(crc32, 8)}');
		check(decode(png, width, height, channels).compare(image) == 0, '$what reads back');
	}

	static function main():Void {
		same(0, 1, 1, 1, 67, 0x14498e65);
		same(0, 1, 1, 2, 68, 0xf5cfdb61);
		same(0, 1, 1, 3, 69, 0xe2b97e5d);
		same(0, 1, 1, 4, 70, 0x957bd1af);
		same(1, 17, 9, 1, 75, 0xecfb08d2);
		same(1, 17, 9, 4, 84, 0x267ef97f);
		same(2, 17, 9, 2, 383, 0xfbee41bf);
		same(2, 17, 9, 3, 536, 0xc92cb79c);
		same(3, 17, 9, 1, 179, 0x4713680c);
		same(3, 17, 9, 4, 362, 0x89c0a24c);
		same(5, 5, 7, 3, 132, 0x92c26988);
		same(5, 5, 7, 4, 131, 0x6a0dbedc);
		same(4, 33, 65, 1, 1645, 0xd3d33065);
		same(4, 33, 65, 3, 4466, 0x0d35f944);
		same(5, 64, 64, 4, 6564, 0x27f3f934);
		same(2, 64, 64, 4, 16516, 0x409009ac); // noise: stored, compressing made it larger
		var image = pixels(1, 4, 4, 4);
		for (bad in [[0, 4, 4], [4, 0, 4], [4, 4, 0], [4, 4, 5], [5, 4, 4]])
			check(try {
				PngFile.write(bad[0], bad[1], bad[2], image);
				false;
			} catch (e:String) true, 'a ${bad[0]} x ${bad[1]} image of ${bad[2]} channels throws');
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
