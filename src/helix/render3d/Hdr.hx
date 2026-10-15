package helix.render3d;

import haxe.ds.Vector;
import haxe.io.Bytes;

/** A Radiance .hdr image (RGBE, "#?RADIANCE" or "#?RGBE", 32-bit_rle_rgbe, flat or run-length encoded scanlines, "-Y height +X width": the
	orientation every .hdr environment uses) read into linear RGB floats, three a pixel, rows top first, a band of rows at a time (readRows), so a
	large one can be read across frames. */
class Hdr {
	/** Its width in pixels. */
	public final width:Int;

	/** Its height in pixels. */
	public final height:Int;

	/** Its pixels: linear RGB, three floats each, rows top first; complete once every row is read. */
	public final rgb:Vector<Float>;

	var bytes:Bytes;
	var position:Int;
	// Whether the scanlines are run-length encoded: -1 until the first is seen, then the whole image's (as stb_image reads them).
	var rle = -1;
	var scanline:Bytes;
	var row = 0;

	function new(bytes:Bytes, width:Int, height:Int, start:Int) {
		this.bytes = bytes;
		this.width = width;
		this.height = height;
		position = start;
		rgb = new Vector<Float>(width * height * 3);
		scanline = Bytes.alloc(width * 4);
	}

	/** Whether bytes start as a .hdr this reads. */
	public static function isHdr(bytes:Bytes):Bool
		return header(bytes) != null;

	/** Starts reading a .hdr: its size known, its rows read by readRows. Throws for bytes that aren't one it reads. */
	public static function begin(bytes:Bytes):Hdr {
		var found = header(bytes);
		if (found == null)
			throw "Not a Radiance .hdr it reads";
		return new Hdr(bytes, found.width, found.height, found.start);
	}

	/** A whole .hdr read at once. Throws for one that isn't, or is broken. */
	public static function read(bytes:Bytes):Hdr {
		var hdr = begin(bytes);
		while (!hdr.readRows(hdr.height)) {}
		return hdr;
	}

	/** Whether every row is read. */
	public function isDone():Bool
		return row == height;

	/** Reads up to count more rows; true once every row is read. Throws for data that ends early or is broken. */
	public function readRows(count:Int):Bool {
		var end = row + count < height ? row + count : height;
		while (row < end) {
			readRow(row);
			row++;
		}
		if (row == height)
			bytes = null;
		return row == height;
	}

	// The header's lines up to the empty one, then the size line: the size and where the pixels start, or null.
	static function header(bytes:Bytes):Null<{width:Int, height:Int, start:Int}> {
		var at = 0;
		function line():Null<String> {
			var start = at;
			while (at < bytes.length && bytes.get(at) != 10)
				at++;
			if (at >= bytes.length)
				return null;
			var text = bytes.getString(start, at - start);
			at++;
			return text;
		}
		var first = line();
		if (first != "#?RADIANCE" && first != "#?RGBE")
			return null;
		while (true) {
			var text = line();
			if (text == null)
				return null;
			if (text == "")
				break;
			if (StringTools.startsWith(text, "FORMAT=") && text != "FORMAT=32-bit_rle_rgbe")
				return null;
		}
		var size = line();
		if (size == null)
			return null;
		var parts = size.split(" ");
		if (parts.length != 4 || parts[0] != "-Y" || parts[2] != "+X")
			return null;
		var h = Std.parseInt(parts[1]), w = Std.parseInt(parts[3]);
		if (h == null || w == null || w <= 0 || h <= 0 || w > 32768 || h > 32768)
			return null;
		return {width: w, height: h, start: at};
	}

	function readRow(y:Int):Void {
		var w = width;
		if (rle < 0)
			rle = w >= 8
				&& w < 32768
				&& position + 4 <= bytes.length
				&& bytes.get(position) == 2
				&& bytes.get(position + 1) == 2
				&& (bytes.get(position + 2) << 8 | bytes.get(position + 3)) == w ? 1 : 0;
		if (rle == 0) {
			// Flat RGBE.
			if (position + w * 4 > bytes.length)
				throw "The .hdr ends early";
			for (x in 0...w)
				rgbe(bytes, position + x * 4, y * w + x);
			position += w * 4;
			return;
		}
		if (position + 4 > bytes.length
			|| bytes.get(position) != 2
			|| bytes.get(position + 1) != 2
			|| (bytes.get(position + 2) << 8 | bytes.get(position + 3)) != w)
			throw "A broken .hdr scanline";
		position += 4;
		// Each channel's runs: (128 + n, a byte n times) or (n, n bytes).
		for (c in 0...4) {
			var x = 0;
			while (x < w) {
				if (position >= bytes.length)
					throw "The .hdr ends early";
				var n = bytes.get(position++);
				if (n > 128) {
					n -= 128;
					if (n > w - x || position >= bytes.length)
						throw "A broken .hdr run";
					var value = bytes.get(position++);
					for (_ in 0...n)
						scanline.set((x++) * 4 + c, value);
				} else {
					if (n == 0 || n > w - x || position + n > bytes.length)
						throw "A broken .hdr run";
					for (_ in 0...n)
						scanline.set((x++) * 4 + c, bytes.get(position++));
				}
			}
		}
		for (x in 0...w)
			rgbe(scanline, x * 4, y * w + x);
	}

	// The RGBE pixel at source[at] into pixel `pixel` of rgb.
	function rgbe(source:Bytes, at:Int, pixel:Int):Void {
		var e = source.get(at + 3), out = pixel * 3;
		if (e == 0) {
			rgb[out] = rgb[out + 1] = rgb[out + 2] = 0;
			return;
		}
		var f = Math.pow(2, e - (128 + 8));
		rgb[out] = source.get(at) * f;
		rgb[out + 1] = source.get(at + 1) * f;
		rgb[out + 2] = source.get(at + 2) * f;
	}
}
