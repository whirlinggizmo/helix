package helix.graphics;

import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;

/** PNG encoding in Haxe, the same bytes on every target: RGBA8 rows filtered as PNG suggests (the filter of the smallest sum, row by row),
	then deflated with LZ77 matching and the fixed Huffman codes. Smaller than stored data by about as much as a dynamic-code encoder for
	flat, synthetic images (a game's frame); larger for noisy ones. */
@:noCompletion
@:allow(helix)
class Png {
	static inline var WINDOW = 32768;
	static inline var HASH_BITS = 15;
	static inline var MAX_CHAIN = 32;
	static inline var MIN_MATCH = 3;
	static inline var MAX_MATCH = 258;

	static final LENGTH_BASE = [
		3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258
	];
	static final LENGTH_EXTRA = [
		0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
	];
	static final DISTANCE_BASE = [
		1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577
	];
	static final DISTANCE_EXTRA = [
		0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
	];

	/** The PNG file of a width x height RGBA8 image, rows top first (rgba holds at least width * height * 4 bytes). Throws for a size of 0 or
		less or rgba too short. */
	static function encode(width:Int, height:Int, rgba:Bytes):Bytes {
		if (width <= 0 || height <= 0 || rgba.length < width * height * 4)
			throw "Invalid image";
		var out = new BytesBuffer();
		for (b in [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
			out.addByte(b);
		var header = Bytes.alloc(13);
		setBigEndian(header, 0, width);
		setBigEndian(header, 4, height);
		header.set(8, 8); // 8 bits a channel
		header.set(9, 6); // RGBA
		chunk(out, "IHDR", header);
		chunk(out, "IDAT", zlib(filter(width, height, rgba)));
		chunk(out, "IEND", Bytes.alloc(0));
		return out.getBytes();
	}

	// Each row behind its filter type, the one of None, Sub, Up, Average and Paeth whose output has the smallest sum of magnitudes.
	static function filter(width:Int, height:Int, rgba:Bytes):Bytes {
		var row = width * 4,
			out = Bytes.alloc((row + 1) * height),
			trial = Bytes.alloc(row),
			best = Bytes.alloc(row);
		for (y in 0...height) {
			var at = y * row, bestSum = -1, bestType = 0;
			for (type in 0...5) {
				var sum = 0;
				for (x in 0...row) {
					var raw = rgba.get(at + x),
						left = x >= 4 ? rgba.get(at + x - 4) : 0,
						up = y > 0 ? rgba.get(at + x - row) : 0,
						upLeft = x >= 4 && y > 0 ? rgba.get(at + x - row - 4) : 0;
					var value = (switch type {
						case 0: raw;
						case 1: raw - left;
						case 2: raw - up;
						case 3: raw - ((left + up) >> 1);
						case _: raw - paeth(left, up, upLeft);
					}) & 0xFF;
					trial.set(x, value);
					sum += value < 128 ? value : 256 - value;
				}
				if (bestSum < 0 || sum < bestSum) {
					bestSum = sum;
					bestType = type;
					best.blit(0, trial, 0, row);
				}
			}
			out.set(y * (row + 1), bestType);
			out.blit(y * (row + 1) + 1, best, 0, row);
		}
		return out;
	}

	static function paeth(a:Int, b:Int, c:Int):Int {
		var p = a + b - c, pa = p > a ? p - a : a - p, pb = p > b ? p - b : b - p, pc = p > c ? p - c : c - p;
		return pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
	}

	// A zlib stream: its header, one final fixed-Huffman deflate block, and the data's Adler-32.
	static function zlib(data:Bytes):Bytes {
		var bits = new BitWriter();
		bits.write(0x78, 8);
		bits.write(0x01, 8);
		bits.write(1, 1); // the final block
		bits.write(1, 2); // fixed Huffman codes
		var head = new Vector<Int>(1 << HASH_BITS),
			previous = new Vector<Int>(WINDOW);
		for (i in 0...head.length)
			head[i] = -1;
		var n = data.length, i = 0;
		while (i < n) {
			var length = 0, distance = 0;
			if (i + MIN_MATCH <= n) {
				var hash = hashAt(data, i);
				var candidate = head[hash], chain = MAX_CHAIN;
				while (candidate >= 0 && i - candidate <= WINDOW && chain-- > 0) {
					var l = 0, limit = n - i < MAX_MATCH ? n - i : MAX_MATCH;
					while (l < limit && data.get(candidate + l) == data.get(i + l))
						l++;
					if (l > length) {
						length = l;
						distance = i - candidate;
						if (l == limit)
							break;
					}
					candidate = previous[candidate % WINDOW];
				}
			}
			if (length >= MIN_MATCH) {
				writeLength(bits, length);
				writeDistance(bits, distance);
				for (k in 0...length)
					insert(data, i + k, n, head, previous);
				i += length;
			} else {
				writeLiteral(bits, data.get(i));
				insert(data, i, n, head, previous);
				i++;
			}
		}
		writeLiteral(bits, 256); // the block's end
		bits.flush();
		var adler = haxe.crypto.Adler32.make(data);
		for (shift in [24, 16, 8, 0])
			bits.out.addByte((adler >>> shift) & 0xFF);
		return bits.out.getBytes();
	}

	static inline function hashAt(data:Bytes, i:Int):Int
		return ((data.get(i) << 10) ^ (data.get(i + 1) << 5) ^ data.get(i + 2)) & ((1 << HASH_BITS) - 1);

	static inline function insert(data:Bytes, i:Int, n:Int, head:Vector<Int>, previous:Vector<Int>):Void
		if (i + MIN_MATCH <= n) {
			var hash = hashAt(data, i);
			previous[i % WINDOW] = head[hash];
			head[hash] = i;
		}

	// Fixed Huffman codes (RFC 1951 3.2.6), written most significant bit first.
	static function writeLiteral(bits:BitWriter, value:Int):Void {
		if (value < 144)
			bits.writeCode(0x30 + value, 8);
		else if (value < 256)
			bits.writeCode(0x190 + value - 144, 9);
		else if (value < 280)
			bits.writeCode(value - 256, 7);
		else
			bits.writeCode(0xC0 + value - 280, 8);
	}

	static function writeLength(bits:BitWriter, length:Int):Void {
		var code = LENGTH_BASE.length - 1;
		while (LENGTH_BASE[code] > length)
			code--;
		writeLiteral(bits, 257 + code);
		bits.write(length - LENGTH_BASE[code], LENGTH_EXTRA[code]);
	}

	static function writeDistance(bits:BitWriter, distance:Int):Void {
		var code = DISTANCE_BASE.length - 1;
		while (DISTANCE_BASE[code] > distance)
			code--;
		bits.writeCode(code, 5);
		bits.write(distance - DISTANCE_BASE[code], DISTANCE_EXTRA[code]);
	}

	static function chunk(out:BytesBuffer, type:String, data:Bytes):Void {
		var length = Bytes.alloc(4);
		setBigEndian(length, 0, data.length);
		out.add(length);
		var body = Bytes.alloc(4 + data.length);
		body.blit(0, Bytes.ofString(type), 0, 4);
		body.blit(4, data, 0, data.length);
		out.add(body);
		var crc = Bytes.alloc(4);
		setBigEndian(crc, 0, haxe.crypto.Crc32.make(body));
		out.add(crc);
	}

	static inline function setBigEndian(b:Bytes, at:Int, value:Int):Void {
		b.set(at, (value >>> 24) & 0xFF);
		b.set(at + 1, (value >>> 16) & 0xFF);
		b.set(at + 2, (value >>> 8) & 0xFF);
		b.set(at + 3, value & 0xFF);
	}
}

/** Deflate's bit stream: values least significant bit first, Huffman codes most significant first. */
private class BitWriter {
	/** The bytes written so far. */
	public var out = new BytesBuffer();

	var buffer = 0;
	var count = 0;

	/** An empty stream. */
	public function new() {}

	/** count bits of value, least significant first. */
	public function write(value:Int, count:Int):Void {
		buffer |= (value & ((1 << count) - 1)) << this.count;
		this.count += count;
		while (this.count >= 8) {
			out.addByte(buffer & 0xFF);
			buffer >>>= 8;
			this.count -= 8;
		}
	}

	/** A Huffman code of count bits, most significant first. */
	public function writeCode(code:Int, count:Int):Void {
		var reversed = 0;
		for (i in 0...count)
			reversed |= ((code >>> i) & 1) << (count - 1 - i);
		write(reversed, count);
	}

	/** Writes the last partial byte, its unused bits 0. */
	public function flush():Void
		if (count > 0) {
			out.addByte(buffer);
			buffer = 0;
			count = 0;
		}
}
