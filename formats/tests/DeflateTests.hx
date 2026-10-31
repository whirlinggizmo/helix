import haxe.io.Bytes;
import helix.formats.deflate.Deflate;

/** Checks Deflate with the library alone: its streams byte for byte as raylib 5.5's sdefl writes them (each output's length and
	CRC-32, taken from sdefl compiled with gcc, on the same made-up inputs), at several levels, over raw blocks, a block of each kind,
	and a second 256 KiB block; each stream read back by `haxe.zip.InflateImpl`; empty input; and a level out of range. */
class DeflateTests {
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

	// A made-up image's bytes, as the C side made them: 1 a gradient, 2 noise, 3 blocks of flat color and coarse noise, 5 flat
	// squares with specks and a mostly opaque alpha.
	static function pixels(pattern:Int, width:Int, height:Int, channels:Int):Bytes {
		var bytes = Bytes.alloc(width * height * channels);
		state = width * 7919 + height * 104729 + channels * 31 + pattern;
		var i = 0;
		for (y in 0...height)
			for (x in 0...width)
				for (channel in 0...channels) {
					var v = switch pattern {
						case 1: (x * 5 + y * 3 + channel * 40) & 255;
						case 2: next();
						case 3: (((x >> 2) + (y >> 2)) & 1) != 0 ? (channel * 80 + 30) & 255 : next() & 0xC0;
						case _ if (channel == 3): (next() & 0x1f) == 0 ? next() : 255;
						case _: ((x >> 3) * 40 + (y >> 3) * 20 + channel * 7 + ((next() & 7) == 0 ? next() & 15 : 0)) & 255;
					}
					bytes.set(i++, v);
				}
		return bytes;
	}

	static function crc(bytes:Bytes):Int
		return haxe.crypto.Crc32.make(bytes);

	// The bytes a raw DEFLATE stream holds, up to max of them.
	static function inflate(stream:Bytes, max:Int):Bytes {
		var inflater = new haxe.zip.InflateImpl(new haxe.io.BytesInput(stream), false, false);
		var out = Bytes.alloc(max);
		var length = 0;
		while (length < max) {
			var read = inflater.readBytes(out, length, max - length);
			if (read == 0)
				break;
			length += read;
		}
		return out.sub(0, length);
	}

	// The stream for data at level is sdefl's, by its length and CRC-32, and inflates back to data.
	static function same(data:Bytes, level:Int, length:Int, crc32:Int, what:String):Void {
		var stream = Deflate.compress(data, level);
		check(stream.length == length && crc(stream) == crc32, '$what at level $level: sdefl\'s $length bytes, CRC 0x${StringTools.hex(crc32, 8)}');
		check(inflate(stream, data.length + 1).compare(data) == 0, '$what at level $level inflates back');
	}

	static function main():Void {
		var blocks = pixels(3, 64, 64, 4);
		same(blocks, 0, 3689, 0xdfa0a4a6, "64 x 64 blocks");
		same(blocks, 1, 3671, 0x75b11cfd, "64 x 64 blocks");
		same(blocks, 5, 3490, 0xdd6474b6, "64 x 64 blocks");
		same(blocks, 8, 3430, 0x158590b8, "64 x 64 blocks");
		same(pixels(5, 64, 64, 4), 8, 4540, 0x4ed6b6c7, "64 x 64 squares");
		same(pixels(2, 64, 64, 4), 8, 16389, 0x0d11c72c, "64 x 64 noise, a raw block");
		same(pixels(2, 70000, 1, 1), 0, 70010, 0x9d4655e6, "70000 bytes of noise, two raw blocks");
		same(pixels(3, 70000, 1, 1), 8, 13735, 0xd850cb30, "70000 bytes of blocks");
		same(pixels(1, 262145, 1, 1), 0, 2298, 0x01893b75, "256 KiB and a byte of gradient, two blocks");
		same(pixels(1, 1, 1, 1), 8, 6, 0x6b80f81e, "a byte");
		for (level in 0...9)
			check(Deflate.compress(Bytes.alloc(0), level).length == 0, 'empty input at level $level: no bytes, as sdefl writes');
		for (level in [-1, 9])
			check(try {
				Deflate.compress(blocks, level);
				false;
			} catch (e:String) true, 'level $level throws');
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
