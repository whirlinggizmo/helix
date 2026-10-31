import haxe.io.Bytes;
import helix.formats.qoi.QoiFile;

/** Checks QoiFile with the library alone: its files byte for byte as raylib 5.5's qoi.h writes them (each file's length and CRC-32,
	taken from qoi.h compiled with gcc, on the same made-up images), for 3 and 4 channels, a single pixel, runs, the index, small and
	larger differences and a changing alpha; each read back to the pixels written, its size, channels and colorspace; a file that ends
	early; and what throws. */
class QoiTests {
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

	static function thrown(call:Void->Void):Bool {
		try
			call()
		catch (e:String)
			return true;
		return false;
	}

	// The QOI of a made-up image is qoi.h's, by its length and CRC-32, and reads back to it.
	static function same(pattern:Int, width:Int, height:Int, channels:Int, length:Int, crc32:Int):Void {
		var what = '$width x $height, $channels channels, pattern $pattern';
		var image = pixels(pattern, width, height, channels);
		var qoi = QoiFile.write(width, height, channels, image);
		check(qoi.length == length && haxe.crypto.Crc32.make(qoi) == crc32, '$what: qoi.h\'s $length bytes, CRC 0x${StringTools.hex(crc32, 8)}');
		check(qoi.getString(0, 4) == "qoif" && qoi.get(12) == channels && qoi.get(13) == 0, '$what: the magic, its channels, sRGB');
		var read = QoiFile.read(qoi);
		check(read.width == width && read.height == height && read.channels == channels && !read.linear, '$what: its header read back');
		check(read.pixels.compare(image) == 0, '$what: its pixels read back');
	}

	static function main():Void {
		same(0, 1, 1, 3, 26, 0xe2fbd58c);
		same(2, 1, 1, 4, 27, 0x846c674a);
		same(0, 17, 9, 3, 29, 0x81e460c2);
		same(0, 17, 9, 4, 30, 0xde28df34);
		same(1, 17, 9, 3, 314, 0x006d67f0);
		same(1, 17, 9, 4, 787, 0xe5f21df8);
		same(2, 17, 9, 3, 634, 0xbb1e5793);
		same(2, 17, 9, 4, 786, 0x31ebab5c);
		same(3, 17, 9, 3, 370, 0xcb29fd74);
		same(3, 17, 9, 4, 432, 0x043a7965);
		same(4, 17, 9, 3, 319, 0xf746d9d4);
		same(4, 17, 9, 4, 737, 0x21f6119b);
		same(5, 17, 9, 3, 245, 0xfcbb6cc0);
		same(5, 17, 9, 4, 272, 0xa8d2a796);
		same(0, 64, 64, 4, 94, 0xe87f11eb); // runs of 62
		same(5, 64, 64, 4, 6645, 0x59bb6fee);

		// A file that ends early keeps the color it ended on.
		var image = pixels(2, 8, 8, 4);
		var qoi = QoiFile.write(8, 8, 4, image);
		var cut = Bytes.alloc(14 + 5 + 8);
		cut.blit(0, qoi, 0, 14 + 5);
		var short = QoiFile.read(cut);
		check(short.pixels.length == 8 * 8 * 4
			&& short.pixels.sub(0, 4).compare(image.sub(0, 4)) == 0
			&& short.pixels.sub(252, 4).compare(image.sub(0, 4)) == 0,
			"a file that ends early: the last pixel read, repeated");

		// A linear file reads as one.
		var linear = qoi.sub(0, qoi.length);
		linear.set(13, 1);
		check(QoiFile.read(linear).linear, "colorspace 1 reads as linear");

		check(thrown(() -> QoiFile.read(Bytes.alloc(21))), "a file too short throws");
		var wrong = qoi.sub(0, qoi.length);
		wrong.set(0, "Q".code);
		check(thrown(() -> QoiFile.read(wrong)), "a wrong magic throws");
		var twoChannels = qoi.sub(0, qoi.length);
		twoChannels.set(12, 2);
		check(thrown(() -> QoiFile.read(twoChannels)), "2 channels in the header throws");
		var huge = qoi.sub(0, qoi.length);
		huge.set(4, 0x7F);
		check(thrown(() -> QoiFile.read(huge)), "over 400 million pixels throws");
		check(thrown(() -> QoiFile.write(8, 8, 2, image)), "writing 2 channels throws");
		check(thrown(() -> QoiFile.write(0, 8, 4, image)), "writing no width throws");
		check(thrown(() -> QoiFile.write(9, 8, 4, image)), "writing more pixels than given throws");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
