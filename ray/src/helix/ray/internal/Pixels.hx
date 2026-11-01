package helix.ray.internal;

import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.FPHelper;

/** Holds raylib's pixel formats (`rtextures.c`), ported byte for byte: reading a format's pixels as 8-bit colors or as floats,
	writing them back, one pixel's color read and written, and the half floats. Colors here are packed as an image's RGBA bytes read
	as one little-endian Int32: red in the low byte, alpha in the high.

	They are raylib 5.5's, but for `LoadImageDataNormalized` and `GetPixelColor`, which are 6.2's: an R32 or R16 image's pixels each
	read from their own place, and R5G5B5A1's blue from its own five bits (docs/DECISIONS.md 24). raylib's arithmetic is in single
	precision; `f32` rounds each step as it does. `SetPixelColor` writes no float format, as raylib's doesn't. */
@:noCompletion
class Pixels {
	public static inline final GRAYSCALE = 1;
	public static inline final GRAY_ALPHA = 2;
	public static inline final R5G6B5 = 3;
	public static inline final R8G8B8 = 4;
	public static inline final R5G5B5A1 = 5;
	public static inline final R4G4B4A4 = 6;
	public static inline final R8G8B8A8 = 7;
	public static inline final R32 = 8;
	public static inline final R32G32B32 = 9;
	public static inline final R32G32B32A32 = 10;
	public static inline final R16 = 11;
	public static inline final R16G16B16 = 12;
	public static inline final R16G16B16A16 = 13;

	/** The first compressed format: raylib's image functions refuse it and those after it. */
	public static inline final COMPRESSED = 14;

	/** A number rounded to single precision, as each of raylib's float operations rounds. */
	public static inline function f32(x:Float):Float {
		#if js
		return js.lib.Math.fround(x);
		#elseif cpp
		var single:cpp.Float32 = x;
		return single;
		#else
		return FPHelper.i32ToFloat(FPHelper.floatToI32(x));
		#end
	}

	/** A number as C's `(unsigned char)` cast makes it: truncated, its low 8 bits. */
	public static inline function byte(x:Float):Int {
		return Std.int(x) & 255;
	}

	/** C's `round`: halves away from zero. */
	public static inline function round(x:Float):Float {
		return x < 0 ? -Math.floor(-x + 0.5) : Math.floor(x + 0.5);
	}

	/** Packs four channels, 0 to 255 each (higher bits dropped, as C's unsigned char drops them). */
	public static inline function pack(r:Int, g:Int, b:Int, a:Int):Int {
		return (r & 255) | (g & 255) << 8 | (b & 255) << 16 | (a & 255) << 24;
	}

	/** A packed color as 0xAARRGGBB, as helix-services' images take colors. */
	public static inline function argb(rgba:Int):Int {
		return (rgba & 0xff00ff00) | ((rgba >> 16) & 255) | ((rgba & 255) << 16);
	}

	/** A packed color from a ray `Color`. */
	public static inline function ofColor(c:helix.ray.Color):Int {
		return pack(c.r, c.g, c.b, c.a);
	}

	/** A ray `Color` from a packed color. */
	public static inline function toColor(rgba:Int):helix.ray.Color {
		return new helix.ray.Color(rgba & 255, (rgba >> 8) & 255, (rgba >> 16) & 255, (rgba >>> 24) & 255);
	}

	// raylib's grayscale weights, as float literals.
	static final LR = f32(0.299);
	static final LG = f32(0.587);
	static final LB = f32(0.114);
	static final ONE_31 = f32(1 / 31);
	static final ONE_63 = f32(1 / 63);
	static final ONE_15 = f32(1 / 15);
	// PIXELFORMAT_UNCOMPRESSED_R5G5B5A1_ALPHA_THRESHOLD, 50, over 255.
	static final ALPHA_THRESHOLD = f32(50 / 255);

	/** raylib's grayscale of three channels as fractions: 0.299 red, 0.587 green, 0.114 blue, in floats. */
	public static inline function luma(x:Float, y:Float, z:Float):Float {
		return f32(f32(f32(x * LR) + f32(y * LG)) + f32(z * LB));
	}

	/** raylib's `HalfToFloat`: a half float's bits as a float. */
	public static function halfToFloat(x:Int):Float {
		var e = (x & 0x7C00) >> 10;
		var m = (x & 0x03FF) << 13;
		// The exponent of m as a float: its leading zeros, for a denormal.
		var v = FPHelper.floatToI32(m) >>> 23;
		var r = (x & 0x8000) << 16;
		if (e != 0)
			r |= (e + 112) << 23 | m;
		else if (m != 0)
			r |= (v - 37) << 23 | ((m << (150 - v)) & 0x007FE000);
		return FPHelper.i32ToFloat(r);
	}

	/** raylib's `FloatToHalf`: a float as a half float's bits, rounded to nearest, saturating. */
	public static function floatToHalf(x:Float):Int {
		var b = (FPHelper.floatToI32(x) + 0x00001000) | 0;
		var e = (b & 0x7F800000) >>> 23;
		var m = b & 0x007FFFFF;
		var r = (b & 0x80000000) >>> 16;
		if (e > 112)
			r |= (((e - 112) << 10) & 0x7C00) | m >> 13;
		if (e < 113 && e > 101)
			r |= (((0x007FF000 + m) >> (125 - e)) + 1) >> 1;
		if (e > 143)
			r |= 0x7FFF;
		return r & 0xFFFF;
	}

	/** raylib's `LoadImageColors`: an image's pixels as 8-bit RGBA, `width * height * 4` bytes. A compressed format gives clear black,
		and a warning.

		@param data  The pixels.
		@param width  The width.
		@param height  The height.
		@param format  Their format.
		@return  The colors. */
	public static function colors(data:Bytes, width:Int, height:Int, format:Int):Bytes {
		var count = width * height, out = Bytes.alloc(count * 4);
		out.fill(0, out.length, 0);
		if (format >= COMPRESSED) {
			Runtime.log(4, "IMAGE: Pixel data retrieval not supported for compressed image formats");
			return out;
		}
		if (format == R32 || format == R32G32B32 || format == R32G32B32A32)
			Runtime.log(4, "IMAGE: Pixel format converted from 32bit to 8bit per channel");
		if (format == R16 || format == R16G16B16 || format == R16G16B16A16)
			Runtime.log(4, "IMAGE: Pixel format converted from 16bit to 8bit per channel");
		if (format == R8G8B8A8) {
			out.blit(0, data, 0, count * 4 < data.length ? count * 4 : data.length);
			return out;
		}
		for (i in 0...count)
			out.setInt32(i * 4, loadColor(data, i, format));
		return out;
	}

	/** One pixel's color as `LoadImageColors` reads it, by the pixel's index.

		@param data  The pixels.
		@param i  The pixel's index.
		@param format  Their format, uncompressed.
		@return  The packed color; 0 for a format it doesn't read. */
	public static function loadColor(data:Bytes, i:Int, format:Int):Int {
		return switch format {
			case GRAYSCALE:
				var v = data.get(i);
				pack(v, v, v, 255);
			case GRAY_ALPHA:
				var v = data.get(i * 2);
				pack(v, v, v, data.get(i * 2 + 1));
			case R5G5B5A1:
				var p = data.getUInt16(i * 2);
				pack(((p >> 11) & 31) * 8, ((p >> 6) & 31) * 8, ((p >> 1) & 31) * 8, (p & 1) * 255);
			case R5G6B5:
				var p = data.getUInt16(i * 2);
				pack(((p >> 11) & 31) * 8, ((p >> 5) & 63) * 4, (p & 31) * 8, 255);
			case R4G4B4A4:
				var p = data.getUInt16(i * 2);
				pack(((p >> 12) & 15) * 17, ((p >> 8) & 15) * 17, ((p >> 4) & 15) * 17, (p & 15) * 17);
			case R8G8B8A8:
				data.getInt32(i * 4);
			case R8G8B8:
				pack(data.get(i * 3), data.get(i * 3 + 1), data.get(i * 3 + 2), 255);
			case R32:
				pack(byte(f32(data.getFloat(i * 4) * 255)), 0, 0, 255);
			case R32G32B32:
				pack(byte(f32(data.getFloat(i * 12) * 255)), byte(f32(data.getFloat(i * 12 + 4) * 255)), byte(f32(data.getFloat(i * 12 + 8) * 255)), 255);
			case R32G32B32A32:
				pack(byte(f32(data.getFloat(i * 16) * 255)), byte(f32(data.getFloat(i * 16 + 4) * 255)), byte(f32(data.getFloat(i * 16 + 8) * 255)),
					byte(f32(data.getFloat(i * 16 + 12) * 255)));
			case R16:
				pack(byte(f32(halfToFloat(data.getUInt16(i * 2)) * 255)), 0, 0, 255);
			case R16G16B16:
				pack(byte(f32(halfToFloat(data.getUInt16(i * 6)) * 255)), byte(f32(halfToFloat(data.getUInt16(i * 6 + 2)) * 255)),
					byte(f32(halfToFloat(data.getUInt16(i * 6 + 4)) * 255)), 255);
			case R16G16B16A16:
				pack(byte(f32(halfToFloat(data.getUInt16(i * 8)) * 255)), byte(f32(halfToFloat(data.getUInt16(i * 8 + 2)) * 255)),
					byte(f32(halfToFloat(data.getUInt16(i * 8 + 4)) * 255)), byte(f32(halfToFloat(data.getUInt16(i * 8 + 6)) * 255)));
			case _: 0;
		};
	}

	/** raylib 6.2's `LoadImageDataNormalized`: an image's pixels as floats, red, green, blue and alpha, 0 to 1 for the integer formats.
		A compressed format gives zeros, and a warning.

		@param data  The pixels.
		@param count  How many.
		@param format  Their format.
		@return  Four floats a pixel. */
	public static function normalized(data:Bytes, count:Int, format:Int):Vector<Float> {
		var out = new Vector<Float>(count * 4);
		for (i in 0...count * 4)
			out[i] = 0;
		if (format >= COMPRESSED) {
			Runtime.log(4, "IMAGE: Pixel data retrieval not supported for compressed image formats");
			return out;
		}
		inline function set(i:Int, x:Float, y:Float, z:Float, w:Float) {
			out[i * 4] = x;
			out[i * 4 + 1] = y;
			out[i * 4 + 2] = z;
			out[i * 4 + 3] = w;
		}
		inline function unit(v:Int):Float
			return f32(v / 255);
		for (i in 0...count)
			switch format {
				case GRAYSCALE:
					var v = unit(data.get(i));
					set(i, v, v, v, 1);
				case GRAY_ALPHA:
					var v = unit(data.get(i * 2));
					set(i, v, v, v, unit(data.get(i * 2 + 1)));
				case R5G5B5A1:
					var p = data.getUInt16(i * 2);
					set(i, f32(((p >> 11) & 31) * ONE_31), f32(((p >> 6) & 31) * ONE_31), f32(((p >> 1) & 31) * ONE_31), (p & 1) == 0 ? 0 : 1);
				case R5G6B5:
					var p = data.getUInt16(i * 2);
					set(i, f32(((p >> 11) & 31) * ONE_31), f32(((p >> 5) & 63) * ONE_63), f32((p & 31) * ONE_31), 1);
				case R4G4B4A4:
					var p = data.getUInt16(i * 2);
					set(i, f32(((p >> 12) & 15) * ONE_15), f32(((p >> 8) & 15) * ONE_15), f32(((p >> 4) & 15) * ONE_15), f32((p & 15) * ONE_15));
				case R8G8B8A8:
					set(i, unit(data.get(i * 4)), unit(data.get(i * 4 + 1)), unit(data.get(i * 4 + 2)), unit(data.get(i * 4 + 3)));
				case R8G8B8:
					set(i, unit(data.get(i * 3)), unit(data.get(i * 3 + 1)), unit(data.get(i * 3 + 2)), 1);
				case R32:
					set(i, data.getFloat(i * 4), 0, 0, 1);
				case R32G32B32:
					set(i, data.getFloat(i * 12), data.getFloat(i * 12 + 4), data.getFloat(i * 12 + 8), 1);
				case R32G32B32A32:
					set(i, data.getFloat(i * 16), data.getFloat(i * 16 + 4), data.getFloat(i * 16 + 8), data.getFloat(i * 16 + 12));
				case R16:
					set(i, halfToFloat(data.getUInt16(i * 2)), 0, 0, 1);
				case R16G16B16:
					set(i, halfToFloat(data.getUInt16(i * 6)), halfToFloat(data.getUInt16(i * 6 + 2)), halfToFloat(data.getUInt16(i * 6 + 4)), 1);
				case R16G16B16A16:
					set(i, halfToFloat(data.getUInt16(i * 8)), halfToFloat(data.getUInt16(i * 8 + 2)), halfToFloat(data.getUInt16(i * 8 + 4)),
						halfToFloat(data.getUInt16(i * 8 + 6)));
				case _:
			}
		return out;
	}

	/** raylib's `ImageFormat`, from the floats `normalized` gives: the pixels in a format, or null for a format it doesn't write.

		@param pixels  Four floats a pixel.
		@param count  How many pixels.
		@param format  The format to write.
		@return  The pixels. */
	public static function formatted(pixels:Vector<Float>, count:Int, format:Int):Null<Bytes> {
		var size = helix.ray.raylib.RTextures.GetPixelDataSize(count, 1, format);
		if (format < GRAYSCALE || format >= COMPRESSED)
			return null;
		var out = Bytes.alloc(size);
		for (i in 0...count) {
			var x = pixels[i * 4],
				y = pixels[i * 4 + 1],
				z = pixels[i * 4 + 2],
				w = pixels[i * 4 + 3];
			switch format {
				case GRAYSCALE:
					out.set(i, byte(f32(luma(x, y, z) * 255)));
				case GRAY_ALPHA:
					out.set(i * 2, byte(f32(luma(x, y, z) * 255)));
					out.set(i * 2 + 1, byte(f32(w * 255)));
				case R5G6B5:
					var r = byte(round(f32(x * 31))),
						g = byte(round(f32(y * 63))),
						b = byte(round(f32(z * 31)));
					out.setUInt16(i * 2, (r << 11 | g << 5 | b) & 0xFFFF);
				case R8G8B8:
					out.set(i * 3, byte(f32(x * 255)));
					out.set(i * 3 + 1, byte(f32(y * 255)));
					out.set(i * 3 + 2, byte(f32(z * 255)));
				case R5G5B5A1:
					var r = byte(round(f32(x * 31))),
						g = byte(round(f32(y * 31))),
						b = byte(round(f32(z * 31))),
						a = w > ALPHA_THRESHOLD ? 1 : 0;
					out.setUInt16(i * 2, (r << 11 | g << 6 | b << 1 | a) & 0xFFFF);
				case R4G4B4A4:
					var r = byte(round(f32(x * 15))),
						g = byte(round(f32(y * 15))),
						b = byte(round(f32(z * 15))),
						a = byte(round(f32(w * 15)));
					out.setUInt16(i * 2, (r << 12 | g << 8 | b << 4 | a) & 0xFFFF);
				case R8G8B8A8:
					out.set(i * 4, byte(f32(x * 255)));
					out.set(i * 4 + 1, byte(f32(y * 255)));
					out.set(i * 4 + 2, byte(f32(z * 255)));
					out.set(i * 4 + 3, byte(f32(w * 255)));
				case R32:
					out.setFloat(i * 4, luma(x, y, z));
				case R32G32B32:
					out.setFloat(i * 12, x);
					out.setFloat(i * 12 + 4, y);
					out.setFloat(i * 12 + 8, z);
				case R32G32B32A32:
					out.setFloat(i * 16, x);
					out.setFloat(i * 16 + 4, y);
					out.setFloat(i * 16 + 8, z);
					out.setFloat(i * 16 + 12, w);
				case R16:
					out.setUInt16(i * 2, floatToHalf(luma(x, y, z)));
				case R16G16B16:
					out.setUInt16(i * 6, floatToHalf(x));
					out.setUInt16(i * 6 + 2, floatToHalf(y));
					out.setUInt16(i * 6 + 4, floatToHalf(z));
				case R16G16B16A16:
					out.setUInt16(i * 8, floatToHalf(x));
					out.setUInt16(i * 8 + 2, floatToHalf(y));
					out.setUInt16(i * 8 + 4, floatToHalf(z));
					out.setUInt16(i * 8 + 6, floatToHalf(w));
				case _:
			}
		}
		return out;
	}

	/** raylib 6.2's `GetPixelColor`: one pixel's color.

		@param data  The pixels.
		@param at  The pixel's first byte.
		@param format  Their format.
		@return  The packed color; 0 for a format it doesn't read. */
	public static function getColor(data:Bytes, at:Int, format:Int):Int {
		return switch format {
			case GRAYSCALE:
				var v = data.get(at);
				pack(v, v, v, 255);
			case GRAY_ALPHA:
				var v = data.get(at);
				pack(v, v, v, data.get(at + 1));
			case R5G6B5:
				var p = data.getUInt16(at);
				pack(Std.int((p >> 11) * 255 / 31), Std.int(((p >> 5) & 63) * 255 / 63), Std.int((p & 31) * 255 / 31), 255);
			case R5G5B5A1:
				var p = data.getUInt16(at);
				pack(Std.int((p >> 11) * 255 / 31), Std.int(((p >> 6) & 31) * 255 / 31), Std.int(((p >> 1) & 31) * 255 / 31), (p & 1) != 0 ? 255 : 0);
			case R4G4B4A4:
				var p = data.getUInt16(at);
				pack(Std.int((p >> 12) * 255 / 15), Std.int(((p >> 8) & 15) * 255 / 15), Std.int(((p >> 4) & 15) * 255 / 15), Std.int((p & 15) * 255 / 15));
			case R8G8B8A8:
				data.getInt32(at);
			case R8G8B8:
				pack(data.get(at), data.get(at + 1), data.get(at + 2), 255);
			case R32:
				var v = byte(f32(data.getFloat(at) * 255));
				pack(v, v, v, 255);
			case R32G32B32:
				pack(byte(f32(data.getFloat(at) * 255)), byte(f32(data.getFloat(at + 4) * 255)), byte(f32(data.getFloat(at + 8) * 255)), 255);
			case R32G32B32A32:
				pack(byte(f32(data.getFloat(at) * 255)), byte(f32(data.getFloat(at + 4) * 255)), byte(f32(data.getFloat(at + 8) * 255)),
					byte(f32(data.getFloat(at + 12) * 255)));
			case R16:
				var v = byte(f32(halfToFloat(data.getUInt16(at)) * 255));
				pack(v, v, v, 255);
			case R16G16B16:
				pack(byte(f32(halfToFloat(data.getUInt16(at)) * 255)), byte(f32(halfToFloat(data.getUInt16(at + 2)) * 255)),
					byte(f32(halfToFloat(data.getUInt16(at + 4)) * 255)), 255);
			case R16G16B16A16:
				pack(byte(f32(halfToFloat(data.getUInt16(at)) * 255)), byte(f32(halfToFloat(data.getUInt16(at + 2)) * 255)),
					byte(f32(halfToFloat(data.getUInt16(at + 4)) * 255)), byte(f32(halfToFloat(data.getUInt16(at + 6)) * 255)));
			case _: 0;
		}
	}

	/** Writes one pixel's color: raylib's `SetPixelColor` with `floats` false, which writes the 8-bit and 16-bit formats alone, and
		`ImageDrawPixel`'s with it true, which writes the float formats too.

		@param data  The pixels.
		@param at  The pixel's first byte.
		@param rgba  The packed color.
		@param format  Their format.
		@param floats  Whether the float formats are written. */
	public static function setColor(data:Bytes, at:Int, rgba:Int, format:Int, floats:Bool):Void {
		var r = rgba & 255,
			g = (rgba >> 8) & 255,
			b = (rgba >> 16) & 255,
			a = (rgba >>> 24) & 255;
		inline function unit(v:Int):Float
			return f32(v / 255);
		switch format {
			case GRAYSCALE:
				data.set(at, byte(f32(luma(unit(r), unit(g), unit(b)) * 255)));
			case GRAY_ALPHA:
				data.set(at, byte(f32(luma(unit(r), unit(g), unit(b)) * 255)));
				data.set(at + 1, a);
			case R5G6B5:
				var rr = byte(round(f32(unit(r) * 31))),
					gg = byte(round(f32(unit(g) * 63))),
					bb = byte(round(f32(unit(b) * 31)));
				data.setUInt16(at, (rr << 11 | gg << 5 | bb) & 0xFFFF);
			case R5G5B5A1:
				var rr = byte(round(f32(unit(r) * 31))),
					gg = byte(round(f32(unit(g) * 31))),
					bb = byte(round(f32(unit(b) * 31)));
				data.setUInt16(at, (rr << 11 | gg << 6 | bb << 1 | (unit(a) > ALPHA_THRESHOLD ? 1 : 0)) & 0xFFFF);
			case R4G4B4A4:
				var rr = byte(round(f32(unit(r) * 15))),
					gg = byte(round(f32(unit(g) * 15))),
					bb = byte(round(f32(unit(b) * 15))),
					aa = byte(round(f32(unit(a) * 15)));
				data.setUInt16(at, (rr << 12 | gg << 8 | bb << 4 | aa) & 0xFFFF);
			case R8G8B8:
				data.set(at, r);
				data.set(at + 1, g);
				data.set(at + 2, b);
			case R8G8B8A8:
				data.setInt32(at, rgba);
			case R32 if (floats):
				data.setFloat(at, luma(unit(r), unit(g), unit(b)));
			case R32G32B32 if (floats):
				data.setFloat(at, unit(r));
				data.setFloat(at + 4, unit(g));
				data.setFloat(at + 8, unit(b));
			case R32G32B32A32 if (floats):
				data.setFloat(at, unit(r));
				data.setFloat(at + 4, unit(g));
				data.setFloat(at + 8, unit(b));
				data.setFloat(at + 12, unit(a));
			case R16 if (floats):
				data.setUInt16(at, floatToHalf(luma(unit(r), unit(g), unit(b))));
			case R16G16B16 if (floats):
				data.setUInt16(at, floatToHalf(unit(r)));
				data.setUInt16(at + 2, floatToHalf(unit(g)));
				data.setUInt16(at + 4, floatToHalf(unit(b)));
			case R16G16B16A16 if (floats):
				data.setUInt16(at, floatToHalf(unit(r)));
				data.setUInt16(at + 2, floatToHalf(unit(g)));
				data.setUInt16(at + 4, floatToHalf(unit(b)));
				data.setUInt16(at + 6, floatToHalf(unit(a)));
			case _:
		}
	}

	/** raylib's `ColorAlphaBlend`, on packed colors: the source, tinted, blended over the destination by its alpha, in integers.

		@param dst  The color underneath.
		@param src  The color drawn over it.
		@param tint  The color the source is multiplied by.
		@return  The blend. */
	public static inline function blend(dst:Int, src:Int, tint:Int):Int {
		var sr = ((src & 255) * ((tint & 255) + 1)) >> 8,
			sg = (((src >> 8) & 255) * (((tint >> 8) & 255) + 1)) >> 8,
			sb = (((src >> 16) & 255) * (((tint >> 16) & 255) + 1)) >> 8,
			sa = (((src >>> 24) & 255) * (((tint >>> 24) & 255) + 1)) >> 8;
		return if (sa == 0) dst; else if (sa == 255) pack(sr, sg, sb, sa); else {
			var alpha = sa + 1, da = (dst >>> 24) & 255;
			var outA = ((alpha * 256 + da * (256 - alpha)) >> 8) & 255;
			inline function channel(s:Int, d:Int):Int
				return (Std.int((s * alpha * 256 + d * da * (256 - alpha)) / outA) >> 8) & 255;
			pack(channel(sr, dst & 255), channel(sg, (dst >> 8) & 255), channel(sb, (dst >> 16) & 255), outA);
		}
	}
}
