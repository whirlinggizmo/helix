package helix.formats.gif;

import haxe.ds.Vector;
import haxe.io.Bytes;

/** Represents a GIF file (GIF87a or GIF89a): its screen, its global color table and loop count, and its frames as the file gives them.

	Every frame is read, its LZW data decoded and its interlaced rows put in order, with its graphic control block's transparency,
	disposal and delay. `computeFrames` draws them onto the screen in turn, as a browser shows them.

	```haxe
	var gif = GifFile.read(bytes);
	var frames = gif.computeFrames();
	trace(gif.width, gif.height, frames.length, gif.frames[0].delay);
	``` */
class GifFile {
	/** Gets the screen's width, in pixels: the width of every frame `computeFrames` returns. */
	public final width:Int;

	/** Gets the screen's height, in pixels. */
	public final height:Int;

	/** Gets the global color table, each color `0xFFRRGGBB`, or null when the file has none. */
	public final colors:Null<Array<Int>>;

	/** Gets the global color table's index of the background color, as the file gives it. Browsers don't draw it; the screen starts
		transparent. */
	public final backgroundIndex:Int;

	/** Gets the loop count of the file's NETSCAPE2.0 block: 0 to loop forever, or how many times it loops; -1 when the file has none. */
	public final loopCount:Int;

	/** Gets the frames, in the file's order. A file may have none. */
	public final frames:Array<GifFrame>;

	function new(width:Int, height:Int, colors:Null<Array<Int>>, backgroundIndex:Int, loopCount:Int, frames:Array<GifFrame>) {
		this.width = width;
		this.height = height;
		this.colors = colors;
		this.backgroundIndex = backgroundIndex;
		this.loopCount = loopCount;
		this.frames = frames;
	}

	/** Reads a GIF file.

		A file ending where a block would start, without its trailer, is read up to there. Blocks after the trailer are ignored, and so
		are extensions other than the graphic control block and the NETSCAPE2.0 (or ANIMEXTS1.0) loop count. A frame's image data
		holding more pixels than its rectangle has the rest ignored. With a frame limit, nothing after that many frames is read, so a file
		broken after them reads as those frames.

		@param data  The file.
		@param maxFrameCount  Optional. The most frames to read; every frame when omitted.
		@return  The file's screen and frames.
		@throws String  It isn't a GIF file (its signature is wrong, or its screen is 0 pixels wide or high, or over 400 million pixels), or
			it is broken: it ends inside a block, a frame lies outside the screen, has no color table, or has image data that is wrong or
			ends before its last pixel, a graphic control block isn't 4 bytes, or a block is of no kind GIF has. */
	public static function read(data:Bytes, ?maxFrameCount:Int):GifFile {
		var reader = new GifReader(data);
		if (!matches(data, 0, "GIF87a") && !matches(data, 0, "GIF89a"))
			throw "not a GIF file: its signature is wrong";
		reader.position = 6;
		var width = reader.read16(), height = reader.read16();
		var flags = reader.read8(), backgroundIndex = reader.read8();
		reader.read8(); // the pixel aspect ratio
		if (width == 0 || height == 0 || width * 1.0 * height > PIXELS_MAX)
			throw 'not a GIF file: its screen is $width x $height pixels';
		var global = (flags & 0x80) != 0 ? reader.readColors(2 << (flags & 7)) : null;

		var frames = [], loopCount = -1;
		var transparentIndex = -1, disposal = GifDisposal.Unspecified, delay = 0.0;
		while (reader.position < data.length && (maxFrameCount == null || frames.length < maxFrameCount)) {
			var introducer = reader.read8();
			if (introducer == TRAILER)
				break;
			if (introducer == EXTENSION) {
				var label = reader.read8();
				if (label == GRAPHIC_CONTROL) {
					if (reader.read8() != 4)
						throw 'a broken GIF file: a graphic control block of other than 4 bytes, before frame ${frames.length}';
					var packed = reader.read8();
					delay = reader.read16() / 100;
					var index = reader.read8();
					transparentIndex = (packed & 1) != 0 ? index : -1;
					var method = (packed >> 2) & 7;
					disposal = method == 1 ? GifDisposal.Keep : method == 2 ? GifDisposal.Background : method == 3 ? GifDisposal.Previous : GifDisposal.Unspecified;
					reader.skipBlocks();
				} else if (label == APPLICATION) {
					var size = reader.read8();
					var start = reader.position;
					reader.skip(size);
					if (size == 11 && (matches(data, start, "NETSCAPE2.0") || matches(data, start, "ANIMEXTS1.0"))) {
						var length = reader.read8();
						while (length != 0) {
							var block = reader.position;
							reader.skip(length);
							if (length >= 3 && data.get(block) == 1)
								loopCount = data.get(block + 1) | (data.get(block + 2) << 8);
							length = reader.read8();
						}
					} else
						reader.skipBlocks();
				} else {
					reader.skipBlocks();
					// A plain text block is drawn as a frame is, so the graphic control block before it is its.
					if (label == PLAIN_TEXT) {
						transparentIndex = -1;
						disposal = GifDisposal.Unspecified;
						delay = 0;
					}
				}
			} else if (introducer == IMAGE) {
				var x = reader.read16(),
					y = reader.read16(),
					w = reader.read16(),
					h = reader.read16();
				var packed = reader.read8();
				if (x + w > width || y + h > height)
					throw 'a broken GIF file: frame ${frames.length} (${w} x ${h} at $x, $y) lies outside the $width x $height screen';
				var local = (packed & 0x80) != 0 ? reader.readColors(2 << (packed & 7)) : null;
				var colors = local != null ? local : global;
				if (colors == null)
					throw 'a broken GIF file: frame ${frames.length} has no color table';
				var interlaced = (packed & 0x40) != 0;
				var indices = reader.readIndices(w, h, interlaced, frames.length);
				frames.push(new GifFrame(x, y, w, h, interlaced, colors, indices, transparentIndex, disposal, delay));
				transparentIndex = -1;
				disposal = GifDisposal.Unspecified;
				delay = 0;
			} else
				throw 'a broken GIF file: a block of kind 0x${StringTools.hex(introducer, 2)} at byte ${reader.position - 1}';
		}
		return new GifFile(width, height, global, backgroundIndex, loopCount, frames);
	}

	/** Returns each frame as a browser shows it: the whole screen after the frame is drawn, RGBA, 8 bits a channel, rows top first.

		The screen starts transparent (every byte 0). Each frame is drawn over what the frames before left: its pixels of its transparent
		index, or of an index past its color table's end, aren't drawn, and the rest are opaque. Before the next frame is drawn, the
		frame's rectangle is disposed of as its `disposal` says: kept, cleared to transparent, or put back as it was before the frame.

		@return  Each frame's pixels, `width * height * 4` bytes, in the frames' order.
		@throws String  The frames take over 2 GB. */
	public function computeFrames():Array<Bytes> {
		var size = width * height * 4;
		if (size * 1.0 * frames.length > 0x7FFFFFFF)
			throw 'GIF frames of $width x $height pixels, ${frames.length} of them, take over 2 GB';
		var screen = Bytes.alloc(size), result = [];
		for (frame in frames) {
			var before = frame.disposal == GifDisposal.Previous ? screen.sub(0, size) : null;
			draw(screen, frame);
			result.push(screen.sub(0, size));
			if (frame.disposal == GifDisposal.Background)
				for (row in frame.y...frame.y + frame.height)
					screen.fill((row * width + frame.x) * 4, frame.width * 4, 0);
			else if (before != null)
				for (row in frame.y...frame.y + frame.height)
					screen.blit((row * width + frame.x) * 4, before, (row * width + frame.x) * 4, frame.width * 4);
		}
		return result;
	}

	// Whether the bytes at a position are a text's, an ASCII character each.
	static function matches(data:Bytes, at:Int, text:String):Bool {
		if (at + text.length > data.length)
			return false;
		for (i in 0...text.length)
			if (data.get(at + i) != text.charCodeAt(i))
				return false;
		return true;
	}

	// Draws a frame's pixels onto the screen, skipping its transparent index and any past its color table.
	function draw(screen:Bytes, frame:GifFrame):Void {
		var colors = frame.colors,
			count = colors.length,
			transparent = frame.transparentIndex;
		var i = 0;
		for (row in 0...frame.height) {
			var p = ((frame.y + row) * width + frame.x) * 4;
			for (_ in 0...frame.width) {
				var index = frame.indices.get(i++);
				if (index != transparent && index < count) {
					var color = colors[index];
					screen.set(p, (color >> 16) & 0xFF);
					screen.set(p + 1, (color >> 8) & 0xFF);
					screen.set(p + 2, color & 0xFF);
					screen.set(p + 3, 255);
				}
				p += 4;
			}
		}
	}

	static inline final IMAGE = 0x2C;
	static inline final EXTENSION = 0x21;
	static inline final TRAILER = 0x3B;
	static inline final GRAPHIC_CONTROL = 0xF9;
	static inline final APPLICATION = 0xFF;
	static inline final PLAIN_TEXT = 0x01;
	static inline final PIXELS_MAX = 400000000;
}

/** Reads a GIF file's bytes, refusing to read past its end, and decodes its frames' LZW data. */
@:allow(helix.formats.gif.GifFile)
private class GifReader {
	var position = 0;

	final data:Bytes;

	function new(data:Bytes) {
		this.data = data;
	}

	function read8():Int {
		if (position >= data.length)
			throw 'a broken GIF file: it ends inside a block, at byte ${data.length}';
		return data.get(position++);
	}

	function read16():Int {
		var low = read8();
		return low | (read8() << 8);
	}

	function skip(count:Int):Void {
		if (position + count > data.length)
			throw 'a broken GIF file: it ends inside a block, at byte ${data.length}';
		position += count;
	}

	// Skips data sub-blocks, up to and including their terminator.
	function skipBlocks():Void {
		var length = read8();
		while (length != 0) {
			skip(length);
			length = read8();
		}
	}

	// A color table of count colors, each 0xFFRRGGBB.
	function readColors(count:Int):Array<Int> {
		skip(count * 3);
		var p = position - count * 3;
		return [
			for (i in 0...count)
				0xFF000000 | (data.get(p + i * 3) << 16) | (data.get(p + i * 3 + 1) << 8) | data.get(p + i * 3 + 2)
		];
	}

	// A frame's color indices, decoded from its LZW data, rows top first. Codes after the frame's last pixel are checked and ignored.
	function readIndices(width:Int, height:Int, interlaced:Bool, frameIndex:Int):Bytes {
		var minimum = read8();
		if (minimum < 2 || minimum > 11)
			throw 'a broken GIF file: frame $frameIndex\'s LZW code size is $minimum';
		var total = width * height;
		var indices = Bytes.alloc(total);
		// The row each decoded row goes to: in order, or by the four interlaced passes.
		var rows = new Vector<Int>(height);
		var n = 0;
		if (interlaced) {
			for (pass in [[0, 8], [4, 8], [2, 4], [1, 2]]) {
				var row = pass[0];
				while (row < height) {
					rows[n++] = row;
					row += pass[1];
				}
			}
		} else
			for (row in 0...height)
				rows[row] = row;

		var clear = 1 << minimum, end = clear + 1;
		var prefixes = new Vector<Int>(4096, 0),
			suffixes = new Vector<Int>(4096, 0),
			firsts = new Vector<Int>(4096, 0);
		for (code in 0...clear) {
			suffixes[code] = code;
			firsts[code] = code;
		}
		var stack = new Vector<Int>(4097, 0);
		var size = minimum + 1, next = clear + 2, old = -1;
		var bits = 0, bitCount = 0, block = 0, ended = false;
		var written = 0, column = 0, row = 0, out = height > 0 ? rows[0] * width : 0;
		while (true) {
			// The next code, its bits from the sub-blocks, least significant first.
			while (bitCount < size) {
				if (block == 0) {
					block = read8();
					if (block == 0) {
						ended = true;
						break;
					}
				}
				bits |= read8() << bitCount;
				bitCount += 8;
				block--;
			}
			if (ended)
				break;
			var code = bits & ((1 << size) - 1);
			bits >>>= size;
			bitCount -= size;
			if (code == clear) {
				size = minimum + 1;
				next = clear + 2;
				old = -1;
				continue;
			}
			if (code == end) {
				skip(block);
				skipBlocks();
				break;
			}
			if (code > next || (code == next && old < 0) || (old < 0 && code > clear))
				throw 'a broken GIF file: frame $frameIndex\'s image data holds a code it can\'t ($code)';
			// The code's string, last index first: of a known code, or of the code before and its first index.
			var depth = 0, string = code;
			if (code == next) {
				stack[depth++] = firsts[old];
				string = old;
			}
			while (string >= clear) {
				stack[depth++] = suffixes[string];
				string = prefixes[string];
			}
			stack[depth++] = string;
			if (old >= 0 && next < 4096) {
				prefixes[next] = old;
				suffixes[next] = string;
				firsts[next] = firsts[old];
				next++;
				if (next == 1 << size && size < 12)
					size++;
			}
			old = code;
			while (depth > 0) {
				var index = stack[--depth];
				if (written < total) {
					indices.set(out + column, index);
					written++;
					if (++column == width) {
						column = 0;
						if (++row < height)
							out = rows[row] * width;
					}
				}
			}
		}
		if (written < total)
			throw 'a broken GIF file: frame $frameIndex\'s image data ends before its last pixel ($written of $total)';
		return indices;
	}
}
