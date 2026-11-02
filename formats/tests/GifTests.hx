import haxe.io.Bytes;
import helix.formats.gif.GifDisposal;
import helix.formats.gif.GifFile;

/** Checks GifFile with the library alone, on the GIF files in `tests/assets/gif` (embedded as the test compiles): each frame composited
	as Chromium's `ImageDecoder` composites it (each frame's RGBA by its CRC-32, taken from Chromium 1248 through Playwright), and the
	files' screens, color tables, loop counts, rectangles, interlacing, indices, transparency, disposals and delays as they were written.
	The files: one frame of GIF87a; rectangles kept over the screen; disposal to the background and transparency over it; a background
	index past 0, transparency in a global and a local table, interlaced rows; Previous after a frame cleared, a frame without a clear
	code first, a frame with no graphic control block, no trailer; 256 colors of noise filling the code table, written on at 12 bits
	and with a clear code; one PIL wrote; and one of no frames. Then what is refused: every shorter cut of a file and every byte of it changed refuse with a
	message or read, never reading past the end; a wrong signature, an empty screen, a frame outside the screen, no color table, a
	graphic control block of 5 bytes, an unknown block, a code size of 12, a code not yet in the table, data ending early. */
class GifTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// A file's bytes, read as the test compiles: the path is from the repository's root, beside this file's directory's parent.
	static macro function embed(path:String):haxe.macro.Expr {
		var root = haxe.io.Path.directory(haxe.io.Path.directory(haxe.macro.Context.getPosInfos(haxe.macro.Context.currentPos()).file));
		var file = haxe.io.Path.join([root == "" ? "." : root, "..", path]);
		return macro haxe.crypto.Base64.decode($v{haxe.crypto.Base64.encode(sys.io.File.getBytes(file))});
	}

	// Whether reading throws a String (a message), rather than reading.
	static function refused(data:Bytes):Bool {
		try
			GifFile.read(data)
		catch (e:String)
			return true;
		return false;
	}

	// The file's frames composited are Chromium's, CRC for CRC.
	static function composited(name:String, gif:GifFile, crcs:Array<Int>):Void {
		var frames = gif.computeFrames();
		check(frames.length == crcs.length, '$name: ${crcs.length} frames, as Chromium decodes it');
		for (i => frame in frames) {
			check(frame.length == gif.width * gif.height * 4, '$name: frame $i is the whole screen, RGBA');
			check(haxe.crypto.Crc32.make(frame) == crcs[i], '$name: frame $i is Chromium\'s, CRC 0x${StringTools.hex(crcs[i], 8)}');
		}
	}

	// An RGBA pixel of a composited frame, as 0xRRGGBBAA.
	static function pixel(gif:GifFile, frame:Bytes, x:Int, y:Int):Int {
		var p = (y * gif.width + x) * 4;
		return (frame.get(p) << 24) | (frame.get(p + 1) << 16) | (frame.get(p + 2) << 8) | frame.get(p + 3);
	}

	// A copy of bytes with one changed.
	static function changed(data:Bytes, at:Int, value:Int):Bytes {
		var copy = data.sub(0, data.length);
		copy.set(at, value);
		return copy;
	}

	static function main():Void {
		var still = embed("formats/tests/assets/gif/still.gif"),
			anim = embed("formats/tests/assets/gif/anim.gif");
		var dispose = embed("formats/tests/assets/gif/dispose.gif"),
			transparent = embed("formats/tests/assets/gif/transparent.gif");
		var previous = embed("formats/tests/assets/gif/previous.gif"),
			large = embed("formats/tests/assets/gif/large.gif");
		var pil = embed("formats/tests/assets/gif/pil.gif"),
			empty = embed("formats/tests/assets/gif/empty.gif");

		var gif = GifFile.read(still);
		check(gif.width == 5 && gif.height == 3 && gif.frames.length == 1, "still: a 5 x 3 screen, one frame");
		check(gif.colors.length == 4 && gif.colors[2] == 0xFFC8320A, "still: its global table of 4, 0xFFRRGGBB");
		check(gif.loopCount == -1 && gif.backgroundIndex == 0, "still: no loop count");
		var frame = gif.frames[0];
		check(frame.x == 0 && frame.y == 0 && frame.width == 5 && frame.height == 3 && !frame.interlaced, "still: the frame is the screen");
		check(frame.colors == gif.colors
			&& frame.transparentIndex == -1
			&& frame.disposal == GifDisposal.Unspecified
			&& frame.delay == 0,
			"still: no graphic control block, so no transparency, disposal or delay");
		var indices = [for (i in 0...15) frame.indices.get(i)];
		check(indices.join(",") == [for (y in 0...3) for (x in 0...5) (x + y) % 4].join(","), "still: its indices, rows top first");
		composited("still", gif, [0x4b4a59d3]);

		gif = GifFile.read(anim);
		check(gif.loopCount == 0, "anim: loops forever");
		check([for (f in gif.frames) f.delay].join(",") == "0.1,0.25,0.5", "anim: delays in seconds");
		check([for (f in gif.frames) '${f.x} ${f.y} ${f.width} ${f.height}'].join(",") == "0 0 6 4,1 1 2 2,3 2 3 2", "anim: the rectangles");
		check(gif.frames[0].disposal == GifDisposal.Keep && gif.frames[1].disposal == GifDisposal.Unspecified, "anim: the disposals");
		composited("anim", gif, [0xa7afa803, 0xaeae877a, 0xc50aa765]);
		var frames = gif.computeFrames();
		check(pixel(gif, frames[1], 1, 1) == 0xFF00FFFF
			&& pixel(gif, frames[2], 1, 1) == 0xFF00FFFF, "anim: frame 1's pixel, kept in frame 2");

		gif = GifFile.read(dispose);
		check(gif.loopCount == 2 && gif.frames.length == 4, "dispose: 4 frames, looping twice");
		check([for (f in gif.frames) f.disposal].join(",") == [Previous, Keep, Background, Keep].join(","), "dispose: the disposals");
		check(gif.frames[3].transparentIndex == 0 && gif.frames[2].transparentIndex == -1, "dispose: the last frame's transparent index");
		composited("dispose", gif, [0x9213a694, 0xa270284f, 0x3d5e89ef, 0x3d0fadd6]);
		frames = gif.computeFrames();
		check(pixel(gif, frames[3], 1, 1) == 0, "dispose: the rectangle cleared to the background is transparent");
		check(pixel(gif, frames[3], 2, 3) == 0, "dispose: a transparent pixel over it leaves it so");
		check(pixel(gif, frames[3], 7, 7) == 0xC8320AFF, "dispose: outside it the frame before stays");

		gif = GifFile.read(transparent);
		check(gif.backgroundIndex == 2, "transparent: its background index");
		check(gif.frames[1].interlaced && gif.frames[1].colors.length == 8 && gif.frames[1].colors != gif.colors,
			"transparent: an interlaced frame with a table of its own");
		var interlaced = gif.frames[1];
		var expected = [for (y in 0...10) for (x in 0...6) (x + y) % 4 == 0 ? 0 : (y % 7) + 1];
		check([for (i in 0...60) interlaced.indices.get(i)].join(",") == expected.join(","), "transparent: interlaced rows put in order");
		composited("transparent", gif, [0x8daacb3c, 0x810a67cb, 0xbfb6788f]);
		frames = gif.computeFrames();
		check(pixel(gif, frames[0], 0, 0) == 0, "transparent: the background color isn't drawn");
		check(pixel(gif, frames[0], 1, 1) == 0, "transparent: the global table's transparent index isn't drawn");

		gif = GifFile.read(previous);
		check(gif.frames.length == 4 && gif.loopCount == 7, "previous: read without its trailer");
		check(gif.frames[3].colors.length == 4 && gif.frames[3].colors[3] == 0xFFFAFBFC, "previous: the last frame's own table");
		composited("previous", gif, [0xfec56a1f, 0x1b8a979c, 0x57054a32, 0x487f35b3]);

		gif = GifFile.read(large);
		check(gif.colors.length == 256 && gif.frames[1].width == 40, "large: 256 colors");
		composited("large", gif, [0xad028186, 0x674a7f1f]);
		gif = GifFile.read(pil);
		check(gif.loopCount == 1 && gif.frames[0].delay == 0.07 && gif.frames[1].delay == 0.12, "pil: PIL's loop count and delays");
		composited("pil", gif, [0xbfc6bf33, 0x245f90b8]);

		// Every cut and every byte changed is refused with a message or read: nothing is read past the end.
		for (file in [dispose, transparent, previous]) {
			for (length in 0...file.length) {
				var cut = file.sub(0, length);
				try
					GifFile.read(cut).computeFrames()
				catch (e:String) {}
			}
			for (at in 0...file.length)
				for (value in [0, 1, 0x2C, 0x80, 0xFF]) {
					try
						GifFile.read(changed(file, at, value)).computeFrames()
					catch (e:String) {}
				}
		}
		check(true, "every cut and changed byte refused with a message or read");
		check(refused(Bytes.alloc(0)) && refused(changed(still, 4, "8".code)), "a wrong signature is refused");
		check(refused(changed(changed(still, 6, 0), 7, 0)), "an empty screen is refused");
		check(GifFile.read(empty).frames.length == 0 && GifFile.read(empty).computeFrames().length == 0, "a file of no frames reads");
		check(GifFile.read(still.sub(0, 13 + 12)).frames.length == 0, "a file ending after its color table has no frames");
		// still.gif: header 13, table 12, then the image descriptor at 25: x at 26, width at 30, packed at 34, code size at 35.
		check(refused(changed(still, 26, 1)), "a frame outside the screen is refused");
		var noTable = new haxe.io.BytesBuffer();
		noTable.addBytes(changed(still, 10, 0), 0, 13);
		noTable.addBytes(still, 25, still.length - 25);
		check(refused(noTable.getBytes()), "a frame with no color table is refused");
		check(refused(changed(still, 35, 12)), "a code size of 12 is refused");
		check(refused(changed(still, 25, 0x99)), "an unknown block is refused");
		check(refused(still.sub(0, still.length - 4)), "data ending inside a block is refused");
		// anim.gif's first graphic control block, after the header, the table of 8 and the 19-byte NETSCAPE2.0 block.
		check(anim.get(13 + 24 + 19) == 0x21 && anim.get(13 + 24 + 21) == 4, "anim: its graphic control block is where it's expected");
		check(refused(changed(anim, 13 + 24 + 21, 5)), "a graphic control block of 5 bytes is refused");
		// A frame of 2 x 1 with code size 2: clear (4), then code 7 (6 is the next to be made), then the end.
		var bad = Bytes.ofHex("47494638396102000100800000000000ffffff2c0000000002000100000202c40b003b");
		check(refused(bad), "a code not yet in the table is refused");
		var short = Bytes.ofHex("47494638396102000100800000000000ffffff2c00000000020001000002024401003b");
		check(refused(short), "image data ending before the last pixel is refused");
		var good = Bytes.ofHex("47494638396102000100800000000000ffffff2c0000000002000100000202440a003b");
		check(GifFile.read(good).frames[0].indices.toHex() == "0001", "the same frame with both pixels reads");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
