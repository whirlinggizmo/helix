package helix.formats.png;

import haxe.ds.Vector;
import haxe.io.Bytes;

/** Provides writing a PNG file as raylib 5.5's `ExportImage` and `ExportImageToMemory` write one, byte for byte.

	It is stb_image_write 1.16's PNG writer (`stbi_write_png_to_mem`), ported: each row's filter chosen by trying all five and keeping
	the one whose bytes, read as signed, sum smallest; then its own zlib compressor at its default quality (8), a single block of
	DEFLATE's fixed Huffman codes, stored instead when that would be smaller. The pixels are 8 bits a channel, rows top first, with no
	padding between them. Files are larger than an optimizing encoder's, as stb_image_write's are.

	```haxe
	var png = PngFile.write(64, 32, 4, pixels);
	``` */
class PngFile {
	/** Writes pixels as a PNG file.

		One channel is gray, two gray and alpha, three RGB and four RGBA, as raylib's grayscale, gray-alpha, R8G8B8 and R8G8B8A8 images
		are written. Bytes past the image's are ignored.

		@param width  The image's width, in pixels.
		@param height  The image's height, in pixels.
		@param channels  The channels a pixel has, 1 to 4, a byte each.
		@param pixels  The pixels, rows top first, each `width * channels` bytes.
		@return  The PNG file.
		@throws String  The width or height is under 1, the channels are outside 1 to 4, or there are fewer pixels than the size needs. */
	public static function write(width:Int, height:Int, channels:Int, pixels:Bytes):Bytes {
		if (width < 1 || height < 1)
			throw 'A PNG of $width x $height pixels: both must be 1 or more';
		if (channels < 1 || channels > 4)
			throw 'A PNG of $channels channels: it takes 1 to 4';
		if (pixels.length < width * height * channels)
			throw 'A PNG of $width x $height x $channels needs ${width * height * channels} bytes, given ${pixels.length}';
		return StbPngWriter.write(pixels, width * channels, width, height, channels);
	}
}

/* Ported from stb_image_write.h v1.16 (raylib 5.5's copy), by Sean Barrett and its contributors, under either license below.

	ALTERNATIVE A - MIT License
	Copyright (c) 2017 Sean Barrett
	Permission is hereby granted, free of charge, to any person obtaining a copy of
	this software and associated documentation files (the "Software"), to deal in
	the Software without restriction, including without limitation the rights to
	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
	of the Software, and to permit persons to whom the Software is furnished to do
	so, subject to the following conditions:
	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

	ALTERNATIVE B - Public Domain (www.unlicense.org)
	This is free and unencumbered software released into the public domain.
	Anyone is free to copy, modify, publish, use, compile, sell, or distribute this
	software, either in source code form or as a compiled binary, for any purpose,
	commercial or non-commercial, and by any means. */
/** Provides `PngFile.write`'s work: stb_image_write's PNG writer and its zlib compressor. */
private class StbPngWriter {
	// stbi_write_png_compression_level's default; raylib leaves it.
	static inline final COMPRESSION_LEVEL = 8;
	static inline final ZHASH = 16384;

	static final LENGTHC = [
		3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 259
	];
	static final LENGTHEB = [
		0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0
	];
	static final DISTC = [
		1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577, 32768
	];
	static final DISTEB = [
		0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13
	];
	static final FIRSTMAP = [0, 1, 0, 5, 6];
	static final CTYPE = [-1, 0, 4, 2, 6];
	static var crcTable:Null<Vector<Int>> = null;

	/** Returns a PNG file of x by y pixels of n channels, its rows strideBytes apart, as `stbi_write_png_to_mem` writes it. */
	public static function write(pixels:Bytes, strideBytes:Int, x:Int, y:Int, n:Int):Bytes {
		var rowBytes = x * n;
		var filt = Bytes.alloc((rowBytes + 1) * y);
		var lineBuffer = Bytes.alloc(rowBytes);
		for (j in 0...y) {
			// The best filter, by running through all of them.
			var bestFilter = 0, bestFilterVal = 0x7fffffff;
			for (filterType in 0...5) {
				encodeLine(pixels, strideBytes, x, j, n, filterType, lineBuffer, 0);
				// The line's entropy with this filter, estimated; the less, the better.
				var est = 0;
				for (i in 0...rowBytes) {
					var v = lineBuffer.get(i);
					est += v < 128 ? v : 256 - v;
				}
				if (est < bestFilterVal) {
					bestFilterVal = est;
					bestFilter = filterType;
				}
			}
			filt.set(j * (rowBytes + 1), bestFilter);
			encodeLine(pixels, strideBytes, x, j, n, bestFilter, filt, j * (rowBytes + 1) + 1);
		}
		var zlib = zlibCompress(filt, COMPRESSION_LEVEL);
		var zlen = zlib.length;

		// Each chunk takes 12 bytes besides its data.
		var out = Bytes.alloc(8 + 12 + 13 + 12 + zlen + 12);
		var o = 0;
		for (b in [137, 80, 78, 71, 13, 10, 26, 10])
			out.set(o++, b);
		o = wp32(out, o, 13);
		o = wptag(out, o, "IHDR");
		o = wp32(out, o, x);
		o = wp32(out, o, y);
		out.set(o++, 8);
		out.set(o++, CTYPE[n]);
		out.set(o++, 0);
		out.set(o++, 0);
		out.set(o++, 0);
		o = wpcrc(out, o, 13);
		o = wp32(out, o, zlen);
		o = wptag(out, o, "IDAT");
		out.blit(o, zlib, 0, zlen);
		o += zlen;
		o = wpcrc(out, o, zlen);
		o = wp32(out, o, 0);
		o = wptag(out, o, "IEND");
		o = wpcrc(out, o, 0);
		return out;
	}

	static inline function wp32(out:Bytes, o:Int, v:Int):Int {
		out.set(o, v >>> 24);
		out.set(o + 1, (v >>> 16) & 0xFF);
		out.set(o + 2, (v >>> 8) & 0xFF);
		out.set(o + 3, v & 0xFF);
		return o + 4;
	}

	static function wptag(out:Bytes, o:Int, tag:String):Int {
		for (i in 0...4)
			out.set(o + i, StringTools.fastCodeAt(tag, i));
		return o + 4;
	}

	// The CRC of the chunk's type and its len bytes of data, the 4 + len bytes before o, written at o.
	static function wpcrc(out:Bytes, o:Int, len:Int):Int
		return wp32(out, o, crc32(out, o - len - 4, len + 4));

	static function crc32(buffer:Bytes, start:Int, len:Int):Int {
		var table = crcTable;
		if (table == null) {
			table = new Vector<Int>(256, 0);
			for (i in 0...256) {
				var c = i;
				for (_ in 0...8)
					c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
				table[i] = c;
			}
			crcTable = table;
		}
		var crc = ~0;
		for (i in start...start + len)
			crc = (crc >>> 8) ^ table[(buffer.get(i) ^ crc) & 0xFF];
		return ~crc;
	}

	static inline function paeth(a:Int, b:Int, c:Int):Int {
		var p = a + b - c;
		var pa = abs(p - a), pb = abs(p - b), pc = abs(p - c);
		if (pa <= pb && pa <= pc)
			return a;
		if (pb <= pc)
			return b;
		return c;
	}

	static inline function abs(v:Int):Int
		return v < 0 ? -v : v;

	// stbiw__encode_png_line, the row's filtered bytes written to dest from destPos.
	static function encodeLine(pixels:Bytes, strideBytes:Int, width:Int, y:Int, n:Int, filterType:Int, dest:Bytes, destPos:Int):Void {
		var type = y != 0 ? filterType : FIRSTMAP[filterType];
		var z = strideBytes * y;
		var up = z - strideBytes;
		var count = width * n;
		if (type == 0) {
			dest.blit(destPos, pixels, z, count);
			return;
		}
		// The first pixel.
		for (i in 0...n) {
			var v = switch type {
				case 2: pixels.get(z + i) - pixels.get(up + i);
				case 3: pixels.get(z + i) - (pixels.get(up + i) >> 1);
				case 4: pixels.get(z + i) - paeth(0, pixels.get(up + i), 0);
				case _: pixels.get(z + i);
			}
			dest.set(destPos + i, v & 0xFF);
		}
		switch type {
			case 1:
				for (i in n...count)
					dest.set(destPos + i, (pixels.get(z + i) - pixels.get(z + i - n)) & 0xFF);
			case 2:
				for (i in n...count)
					dest.set(destPos + i, (pixels.get(z + i) - pixels.get(up + i)) & 0xFF);
			case 3:
				for (i in n...count)
					dest.set(destPos + i, (pixels.get(z + i) - ((pixels.get(z + i - n) + pixels.get(up + i)) >> 1)) & 0xFF);
			case 4:
				for (i in n...count)
					dest.set(destPos + i, (pixels.get(z + i) - paeth(pixels.get(z + i - n), pixels.get(up + i), pixels.get(up + i - n))) & 0xFF);
			case 5:
				for (i in n...count)
					dest.set(destPos + i, (pixels.get(z + i) - (pixels.get(z + i - n) >> 1)) & 0xFF);
			case 6:
				for (i in n...count)
					dest.set(destPos + i, (pixels.get(z + i) - paeth(pixels.get(z + i - n), 0, 0)) & 0xFF);
			case _:
		}
	}

	static inline function bitrev(code:Int, codebits:Int):Int {
		var res = 0;
		while (codebits-- > 0) {
			res = (res << 1) | (code & 1);
			code >>= 1;
		}
		return res;
	}

	static inline function countm(data:Bytes, a:Int, b:Int, limit:Int):Int {
		var i = 0;
		while (i < limit && i < 258) {
			if (data.get(a + i) != data.get(b + i))
				break;
			i++;
		}
		return i;
	}

	// stbiw__zhash, in 32-bit unsigned arithmetic: | 0 keeps a sum to 32 bits in JS.
	static inline function zhash(data:Bytes, p:Int):Int {
		var hash = data.get(p) + (data.get(p + 1) << 8) + (data.get(p + 2) << 16);
		hash ^= hash << 3;
		hash = (hash + (hash >>> 5)) | 0;
		hash ^= hash << 4;
		hash = (hash + (hash >>> 17)) | 0;
		hash ^= hash << 25;
		hash = (hash + (hash >>> 6)) | 0;
		return hash;
	}

	// stbi_zlib_compress, stb_image_write's own.
	static function zlibCompress(data:Bytes, quality:Int):Bytes {
		var dataLen = data.length;
		if (quality < 5)
			quality = 5;
		// A literal takes at most 9 bits and a match at most 9 a byte; stored blocks take 5 bytes each besides the data.
		var capacity = 2 + Std.int(dataLen / 8) * 9 + 16 + 4;
		var stored = 2 + dataLen + Std.int((dataLen + 32766) / 32767) * 5 + 4;
		var out = Bytes.alloc(capacity > stored ? capacity : stored);
		var o = 0;
		var bitbuf = 0, bitcount = 0;
		inline function add(code:Int, codebits:Int):Void {
			bitbuf |= code << bitcount;
			bitcount += codebits;
			while (bitcount >= 8) {
				out.set(o++, bitbuf & 0xFF);
				bitbuf >>>= 8;
				bitcount -= 8;
			}
		}
		// The fixed Huffman codes, bit-reversed: literals and lengths, 0 to 287.
		var fixed = new Vector<Int>(288, 0);
		var fixedBits = new Vector<Int>(288, 0);
		for (n in 0...288) {
			if (n <= 143) {
				fixed[n] = bitrev(0x30 + n, 8);
				fixedBits[n] = 8;
			} else if (n <= 255) {
				fixed[n] = bitrev(0x190 + n - 144, 9);
				fixedBits[n] = 9;
			} else if (n <= 279) {
				fixed[n] = bitrev(n - 256, 7);
				fixedBits[n] = 7;
			} else {
				fixed[n] = bitrev(0xc0 + n - 280, 8);
				fixedBits[n] = 8;
			}
		}

		out.set(o++, 0x78); // DEFLATE, 32K window
		out.set(o++, 0x5e); // FLEVEL = 1
		add(1, 1); // BFINAL = 1
		add(1, 2); // BTYPE = 1, fixed Huffman

		// Each hash's list of positions, oldest first, at most 2 * quality long.
		var width = 2 * quality;
		var table = new Vector<Int>(ZHASH * width, 0);
		var counts = new Vector<Int>(ZHASH, 0);

		var i = 0;
		while (i < dataLen - 3) {
			// The hash of the next 3 bytes.
			var h = zhash(data, i) & (ZHASH - 1), best = 3;
			var bestloc = -1;
			var base = h * width;
			var n = counts[h];
			for (j in 0...n) {
				var at = table[base + j];
				// Within the window.
				if (at > i - 32768) {
					var d = countm(data, at, i, dataLen - i);
					if (d >= best) {
						best = d;
						bestloc = at;
					}
				}
			}
			// A full list loses its older half.
			if (n == 2 * quality) {
				for (j in 0...quality)
					table[base + j] = table[base + quality + j];
				counts[h] = quality;
			}
			table[base + counts[h]] = i;
			counts[h]++;

			if (bestloc >= 0) {
				// Lazy matching: when the next byte's match is longer, this byte is a literal.
				h = zhash(data, i + 1) & (ZHASH - 1);
				base = h * width;
				n = counts[h];
				for (j in 0...n) {
					var at = table[base + j];
					if (at > i - 32767) {
						var e = countm(data, at, i + 1, dataLen - i - 1);
						if (e > best) {
							bestloc = -1;
							break;
						}
					}
				}
			}

			if (bestloc >= 0) {
				var d = i - bestloc;
				var j = 0;
				while (best > LENGTHC[j + 1] - 1)
					j++;
				add(fixed[j + 257], fixedBits[j + 257]);
				if (LENGTHEB[j] != 0)
					add(best - LENGTHC[j], LENGTHEB[j]);
				j = 0;
				while (d > DISTC[j + 1] - 1)
					j++;
				add(bitrev(j, 5), 5);
				if (DISTEB[j] != 0)
					add(d - DISTC[j], DISTEB[j]);
				i += best;
			} else {
				var b = data.get(i);
				add(fixed[b], fixedBits[b]);
				++i;
			}
		}
		// The last bytes.
		while (i < dataLen) {
			var b = data.get(i);
			add(fixed[b], fixedBits[b]);
			i++;
		}
		add(fixed[256], fixedBits[256]); // end of block
		// Zero bits to the byte boundary.
		while (bitcount != 0)
			add(0, 1);

		// Stored instead, when compressing made it larger.
		if (o > dataLen + 2 + Std.int((dataLen + 32766) / 32767) * 5) {
			o = 2;
			var j = 0;
			while (j < dataLen) {
				var blocklen = dataLen - j;
				if (blocklen > 32767)
					blocklen = 32767;
				out.set(o++, dataLen - j == blocklen ? 1 : 0); // BFINAL, BTYPE = 0: stored
				out.set(o++, blocklen & 0xFF); // LEN
				out.set(o++, (blocklen >> 8) & 0xFF);
				out.set(o++, ~blocklen & 0xFF); // NLEN
				out.set(o++, (~blocklen >> 8) & 0xFF);
				out.blit(o, data, j, blocklen);
				o += blocklen;
				j += blocklen;
			}
		}

		// The input's Adler-32. stb_image_write reduces every 5552 bytes; reducing more often gives the same sums and keeps them
		// under 2^31.
		var s1 = 1, s2 = 0;
		var j = 0;
		while (j < dataLen) {
			var end = j + 2048 < dataLen ? j + 2048 : dataLen;
			for (k in j...end) {
				s1 += data.get(k);
				s2 += s1;
			}
			s1 %= 65521;
			s2 %= 65521;
			j = end;
		}
		out.set(o++, (s2 >> 8) & 0xFF);
		out.set(o++, s2 & 0xFF);
		out.set(o++, (s1 >> 8) & 0xFF);
		out.set(o++, s1 & 0xFF);
		return out.sub(0, o);
	}
}
