package helix.formats.qoi;

import haxe.ds.Vector;
import haxe.io.Bytes;

/** Represents an image read from a QOI file ("Quite OK Image"): its size, its channels and its pixels; and provides writing one.

	Reading and writing are qoi.h's (raylib 5.5's copy) `qoi_decode` and `qoi_encode`, ported, so a file is written byte for byte as
	raylib's `ExportImage` writes it, and read as `LoadImage` reads it: with the channels the file has. The pixels are 8 bits a channel,
	rows top first.

	```haxe
	var qoi = QoiFile.write(64, 32, 4, pixels);
	var image = QoiFile.read(qoi);
	trace(image.width, image.height, image.channelCount);
	``` */
class QoiFile {
	/** Gets the image's width, in pixels. */
	public final width:Int;

	/** Gets the image's height, in pixels. */
	public final height:Int;

	/** Gets the number of channels a pixel has: 3 (RGB) or 4 (RGBA). */
	public final channelCount:Int;

	/** Gets a value indicating whether every channel is linear: false when the color channels are sRGB with a linear alpha, as raylib
		writes them. QOI only records it; the pixels are the same either way. */
	public final linear:Bool;

	/** Gets the pixels, rows top first, each pixel `channelCount` bytes. */
	public final pixels:Bytes;

	function new(width:Int, height:Int, channelCount:Int, linear:Bool, pixels:Bytes) {
		this.width = width;
		this.height = height;
		this.channelCount = channelCount;
		this.linear = linear;
		this.pixels = pixels;
	}

	/** Reads a QOI file.

		A file whose data ends early leaves its last pixels the color it ended on, as qoi.h does.

		@param data  The file.
		@return  The image, with the channels the file has.
		@throws String  It isn't a QOI file: it is too short, its magic or header is wrong, or its size is over 400 million pixels. */
	public static function read(data:Bytes):QoiFile {
		var size = data.length;
		if (size < HEADER_SIZE + PADDING.length)
			throw "not a QOI file: too short";
		var headerMagic = read32(data, 0);
		var width = read32(data, 4);
		var height = read32(data, 8);
		var channelCount = data.get(12);
		var colorspace = data.get(13);
		if (width == 0 || height == 0 || channelCount < 3 || channelCount > 4 || colorspace > 1 || headerMagic != MAGIC || !fits(width, height))
			throw "not a QOI file: its header is wrong";

		var pxLen = width * height * channelCount;
		var pixels = Bytes.alloc(pxLen);
		var index = new Vector<Int>(64, 0);
		var r = 0, g = 0, b = 0, a = 255;
		var p = HEADER_SIZE, run = 0;
		var chunksLen = size - PADDING.length;
		var pxPos = 0;
		while (pxPos < pxLen) {
			if (run > 0)
				run--;
			else if (p < chunksLen) {
				var b1 = data.get(p++);
				if (b1 == OP_RGB) {
					r = data.get(p++);
					g = data.get(p++);
					b = data.get(p++);
				} else if (b1 == OP_RGBA) {
					r = data.get(p++);
					g = data.get(p++);
					b = data.get(p++);
					a = data.get(p++);
				} else if ((b1 & MASK_2) == OP_INDEX) {
					var px = index[b1];
					r = px >>> 24;
					g = (px >>> 16) & 0xFF;
					b = (px >>> 8) & 0xFF;
					a = px & 0xFF;
				} else if ((b1 & MASK_2) == OP_DIFF) {
					r = (r + ((b1 >> 4) & 0x03) - 2) & 0xFF;
					g = (g + ((b1 >> 2) & 0x03) - 2) & 0xFF;
					b = (b + (b1 & 0x03) - 2) & 0xFF;
				} else if ((b1 & MASK_2) == OP_LUMA) {
					var b2 = data.get(p++);
					var vg = (b1 & 0x3f) - 32;
					r = (r + vg - 8 + ((b2 >> 4) & 0x0f)) & 0xFF;
					g = (g + vg) & 0xFF;
					b = (b + vg - 8 + (b2 & 0x0f)) & 0xFF;
				} else if ((b1 & MASK_2) == OP_RUN)
					run = b1 & 0x3f;
				index[hash(r, g, b, a)] = pack(r, g, b, a);
			}
			pixels.set(pxPos, r);
			pixels.set(pxPos + 1, g);
			pixels.set(pxPos + 2, b);
			if (channelCount == 4)
				pixels.set(pxPos + 3, a);
			pxPos += channelCount;
		}
		return new QoiFile(width, height, channelCount, colorspace == 1, pixels);
	}

	/** Writes pixels as a QOI file.

		The file says its color channels are sRGB with a linear alpha, as raylib's `ExportImage` writes it. Bytes past the image's are
		ignored.

		@param width  The image's width, in pixels.
		@param height  The image's height, in pixels.
		@param channelCount  The channels a pixel has: 3 (RGB) or 4 (RGBA), a byte each.
		@param pixels  The pixels, rows top first, each `width * channelCount` bytes.
		@return  The QOI file.
		@throws String  The width or height is under 1, the size is over 400 million pixels, the channels are neither 3 nor 4, or there
			are fewer pixels than the size needs. */
	public static function write(width:Int, height:Int, channelCount:Int, pixels:Bytes):Bytes {
		if (width < 1 || height < 1 || !fits(width, height))
			throw 'A QOI of $width x $height pixels: both must be 1 or more, and 400 million pixels at most';
		if (channelCount != 3 && channelCount != 4)
			throw 'A QOI of $channelCount channels: it takes 3 or 4';
		var pxLen = width * height * channelCount;
		if (pixels.length < pxLen)
			throw 'A QOI of $width x $height x $channelCount needs $pxLen bytes, given ${pixels.length}';

		var bytes = Bytes.alloc(width * height * (channelCount + 1) + HEADER_SIZE + PADDING.length);
		var p = 0;
		write32(bytes, p, MAGIC);
		write32(bytes, p + 4, width);
		write32(bytes, p + 8, height);
		p += 12;
		bytes.set(p++, channelCount);
		bytes.set(p++, SRGB);

		var index = new Vector<Int>(64, 0);
		var run = 0;
		var pr = 0, pg = 0, pb = 0, pa = 255;
		var r = pr, g = pg, b = pb, a = pa;
		var pxEnd = pxLen - channelCount;
		var pxPos = 0;
		while (pxPos < pxLen) {
			r = pixels.get(pxPos);
			g = pixels.get(pxPos + 1);
			b = pixels.get(pxPos + 2);
			if (channelCount == 4)
				a = pixels.get(pxPos + 3);

			if (r == pr && g == pg && b == pb && a == pa) {
				run++;
				if (run == 62 || pxPos == pxEnd) {
					bytes.set(p++, OP_RUN | (run - 1));
					run = 0;
				}
			} else {
				if (run > 0) {
					bytes.set(p++, OP_RUN | (run - 1));
					run = 0;
				}
				var indexPos = hash(r, g, b, a);
				var px = pack(r, g, b, a);
				if (index[indexPos] == px)
					bytes.set(p++, OP_INDEX | indexPos);
				else {
					index[indexPos] = px;
					if (a == pa) {
						var vr = signed(r - pr);
						var vg = signed(g - pg);
						var vb = signed(b - pb);
						var vgR = signed(vr - vg);
						var vgB = signed(vb - vg);
						if (vr > -3 && vr < 2 && vg > -3 && vg < 2 && vb > -3 && vb < 2)
							bytes.set(p++, OP_DIFF | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2));
						else if (vgR > -9 && vgR < 8 && vg > -33 && vg < 32 && vgB > -9 && vgB < 8) {
							bytes.set(p++, OP_LUMA | (vg + 32));
							bytes.set(p++, (vgR + 8) << 4 | (vgB + 8));
						} else {
							bytes.set(p++, OP_RGB);
							bytes.set(p++, r);
							bytes.set(p++, g);
							bytes.set(p++, b);
						}
					} else {
						bytes.set(p++, OP_RGBA);
						bytes.set(p++, r);
						bytes.set(p++, g);
						bytes.set(p++, b);
						bytes.set(p++, a);
					}
				}
			}
			pr = r;
			pg = g;
			pb = b;
			pa = a;
			pxPos += channelCount;
		}
		for (v in PADDING)
			bytes.set(p++, v);
		return bytes.sub(0, p);
	}

	/* Ported from qoi.h, raylib 5.5's copy:

		Copyright (c) 2021, Dominic Szablewski - https://phoboslab.org
		SPDX-License-Identifier: MIT

		Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
		(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify,
		merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included
		in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
		NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
		CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE. */
	static inline final OP_INDEX = 0x00;
	static inline final OP_DIFF = 0x40;
	static inline final OP_LUMA = 0x80;
	static inline final OP_RUN = 0xc0;
	static inline final OP_RGB = 0xfe;
	static inline final OP_RGBA = 0xff;
	static inline final MASK_2 = 0xc0;
	static inline final MAGIC = 0x716F6966; // "qoif"
	static inline final HEADER_SIZE = 14;
	static inline final PIXELS_MAX = 400000000;
	static inline final SRGB = 0;
	static final PADDING = [0, 0, 0, 0, 0, 0, 0, 1];

	// qoi.h's guard, height < QOI_PIXELS_MAX / width in unsigned arithmetic; a width read past 2^31 is negative here.
	static function fits(width:Int, height:Int):Bool
		return width > 0 && height > 0 && height < Std.int(PIXELS_MAX / width);

	static inline function hash(r:Int, g:Int, b:Int, a:Int):Int
		return (r * 3 + g * 5 + b * 7 + a * 11) % 64;

	static inline function pack(r:Int, g:Int, b:Int, a:Int):Int
		return (r << 24) | (g << 16) | (b << 8) | a;

	// A byte's difference as a signed char holds it.
	static inline function signed(v:Int):Int {
		v &= 0xFF;
		return v < 128 ? v : v - 256;
	}

	static inline function read32(data:Bytes, p:Int):Int
		return (data.get(p) << 24) | (data.get(p + 1) << 16) | (data.get(p + 2) << 8) | data.get(p + 3);

	static inline function write32(bytes:Bytes, p:Int, v:Int):Void {
		bytes.set(p, v >>> 24);
		bytes.set(p + 1, (v >>> 16) & 0xFF);
		bytes.set(p + 2, (v >>> 8) & 0xFF);
		bytes.set(p + 3, v & 0xFF);
	}
}
