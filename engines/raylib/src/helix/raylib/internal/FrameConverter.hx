package helix.raylib.internal;

import haxe.io.Bytes;

/** Holds miniaudio's `ma_convert_frames` as raylib 5.5's `WaveFormat` and `LoadSoundFromWave` call it, ported byte for byte: samples
	converted between unsigned 8-bit, signed 16-bit and 32-bit float, between channel counts by miniaudio's default channel maps and
	its rectangular mix, and between rates by its linear resampler with a fourth-order low-pass filter.

	A format is a sample size in bits as raylib maps it: 8 is unsigned 8-bit, 16 signed 16-bit, and any other 32-bit float. The steps
	run as miniaudio's data converter runs them, in its 4096-byte blocks, with its arithmetic: single precision where it is single, its
	fixed point for 16-bit filtering, mixing and resampling. Its quirks are kept: a 16-bit mix down to one channel divides a negative
	sum as unsigned, and 32-bit floats become 16-bit samples by its x86-64 SSE2 path wherever its buffers are 16-byte aligned, which
	saturates a sample below -1 to -32768 where its plain path clips to -32767. Every buffer is taken to start aligned, as `malloc`'s
	and the converter's own do. */
@:noCompletion
class FrameConverter {
	/** Returns the frames a conversion is expected to give, as `ma_convert_frames` returns them when given no output.

		@param frameCountIn  The frames converted.
		@param formatIn  The input's sample size in bits.
		@param channelsIn  The input's channels.
		@param sampleRateIn  The input's frames a second.
		@param formatOut  The output's sample size in bits.
		@param channelsOut  The output's channels.
		@param sampleRateOut  The output's frames a second.
		@return  The frames, or 0 when there is no input or the conversion can't be made (a channel count under 1, or a rate under 1
			where the rates differ). */
	public static function expectedFrames(frameCountIn:Int, formatIn:Int, channelsIn:Int, sampleRateIn:Int, formatOut:Int, channelsOut:Int,
			sampleRateOut:Int):Int {
		if (frameCountIn <= 0)
			return 0;
		var converter = Converter.make(formatOf(formatIn), channelsIn, sampleRateIn, formatOf(formatOut), channelsOut, sampleRateOut);
		if (converter == null)
			return 0;
		return converter.expected(frameCountIn);
	}

	/** Converts frames, as `ma_convert_frames` converts them into an output it is given.

		@param out  Receives the frames, interleaved, little-endian.
		@param frameCountOut  The most frames written.
		@param formatOut  The output's sample size in bits.
		@param channelsOut  The output's channels.
		@param sampleRateOut  The output's frames a second.
		@param data  The input's frames, interleaved, little-endian; bytes past its end are read as 0.
		@param frameCountIn  The frames converted.
		@param formatIn  The input's sample size in bits.
		@param channelsIn  The input's channels.
		@param sampleRateIn  The input's frames a second.
		@return  The frames written, or 0 when there is no input or the conversion can't be made. */
	public static function convert(out:Bytes, frameCountOut:Int, formatOut:Int, channelsOut:Int, sampleRateOut:Int, data:Bytes, frameCountIn:Int,
			formatIn:Int, channelsIn:Int, sampleRateIn:Int):Int {
		if (frameCountIn <= 0)
			return 0;
		var fIn = formatOf(formatIn), fOut = formatOf(formatOut);
		var converter = Converter.make(fIn, channelsIn, sampleRateIn, fOut, channelsOut, sampleRateOut);
		if (converter == null)
			return 0;
		var needed = frameCountIn * fIn * channelsIn;
		var input = data;
		if (data == null || data.length < needed) {
			input = Bytes.alloc(needed);
			if (data != null)
				input.blit(0, data, 0, data.length);
		}
		return converter.process(input, frameCountIn, out, frameCountOut < 0 ? 0 : frameCountOut);
	}

	// The bytes a sample of raylib's sample size takes in miniaudio: u8, s16, else f32.
	static function formatOf(sampleSize:Int):Int {
		return sampleSize == 8 ? 1 : sampleSize == 16 ? 2 : 4;
	}
}

/** The data converter: its configuration's steps and its execution path. Formats are the bytes a sample takes: 1 (u8), 2 (s16) or 4
	(f32). */
private class Converter {
	static inline final BLOCK = 4096;

	final formatIn:Int;
	final formatOut:Int;
	final channelsIn:Int;
	final channelsOut:Int;
	final mid:Int;
	final hasPre:Bool;
	final hasPost:Bool;
	final channels:Null<Channels>;
	final resampler:Null<Resampler>;
	final path:Int;
	final tempIn = Bytes.alloc(BLOCK);
	final tempMid = Bytes.alloc(BLOCK);
	final tempOut = Bytes.alloc(BLOCK);

	function new(formatIn:Int, channelsIn:Int, formatOut:Int, channelsOut:Int, mid:Int, channels:Null<Channels>, resampler:Null<Resampler>) {
		this.formatIn = formatIn;
		this.formatOut = formatOut;
		this.channelsIn = channelsIn;
		this.channelsOut = channelsOut;
		this.mid = mid;
		this.channels = channels;
		this.resampler = resampler;
		var pre = false, post = false;
		if (channels == null && resampler == null)
			post = formatIn != formatOut;
		else {
			pre = formatIn != mid;
			post = formatOut != mid;
		}
		hasPre = pre;
		hasPost = post;
		// 0 passthrough, 1 format only, 2 channels only, 3 resample only, 4 resample first, 5 channels first.
		if (!pre && !post && channels == null && resampler == null)
			path = 0;
		else if (channelsIn < channelsOut)
			path = resampler != null ? 4 : 2;
		else if (channels != null)
			path = resampler != null ? 5 : 2;
		else
			path = resampler != null ? 3 : 1;
	}

	/** The converter `ma_data_converter_init` makes, or null where it fails. */
	public static function make(formatIn:Int, channelsIn:Int, rateIn:Int, formatOut:Int, channelsOut:Int, rateOut:Int):Null<Converter> {
		if (channelsIn < 1 || channelsOut < 1)
			return null;
		var resampling = rateIn != rateOut;
		var mid = formatOut != 1 ? formatOut : formatIn != 1 ? formatIn : 4;
		var channels = channelsIn == channelsOut ? null : new Channels(mid, channelsIn, channelsOut);
		var resampler:Null<Resampler> = null;
		if (resampling) {
			if (rateIn <= 0 || rateOut <= 0)
				return null;
			resampler = new Resampler(mid, channelsIn < channelsOut ? channelsIn : channelsOut, rateIn, rateOut);
		}
		return new Converter(formatIn, channelsIn, formatOut, channelsOut, mid, channels, resampler);
	}

	/** `ma_data_converter_get_expected_output_frame_count`. */
	public function expected(frameCountIn:Int):Int {
		return resampler == null ? frameCountIn : resampler.expected(frameCountIn);
	}

	/** `ma_data_converter_process_pcm_frames` over the whole input; the frames written. */
	public function process(data:Bytes, frameCountIn:Int, out:Bytes, frameCountOut:Int):Int {
		return switch path {
			case 0:
				var n = min(frameCountIn, frameCountOut);
				out.blit(0, data, 0, n * formatOut * channelsOut);
				n;
			case 1:
				var n = min(frameCountIn, frameCountOut);
				Samples.convert(out, 0, formatOut, data, 0, formatIn, n * channelsIn);
				n;
			case 2: channelsOnly(data, frameCountIn, out, frameCountOut);
			case 3: resampleOnly(data, frameCountIn, out, frameCountOut);
			case 4: resampleFirst(data, frameCountIn, out, frameCountOut);
			case _: channelsFirst(data, frameCountIn, out, frameCountOut);
		}
	}

	function channelsOnly(data:Bytes, frameCountIn:Int, out:Bytes, frameCountOut:Int):Int {
		var n = min(frameCountIn, frameCountOut);
		if (!hasPre && !hasPost) {
			channels.process(out, 0, data, 0, n);
			return n;
		}
		var done = 0;
		while (done < n) {
			var outCap = Std.int(BLOCK / (mid * channelsOut));
			var src = done * formatIn * channelsIn,
				dst = done * formatOut * channelsOut;
			var k:Int;
			if (hasPre) {
				var inCap = Std.int(BLOCK / (mid * channelsIn));
				k = min(n - done, inCap);
				if (hasPost)
					k = min(k, outCap);
				Samples.convert(tempIn, 0, mid, data, src, formatIn, k * channelsIn);
				if (hasPost)
					channels.process(tempOut, 0, tempIn, 0, k);
				else
					channels.process(out, dst, tempIn, 0, k);
			} else {
				k = min(n - done, outCap);
				channels.process(tempOut, 0, data, src, k);
			}
			if (hasPost)
				Samples.convert(out, dst, formatOut, tempOut, 0, mid, k * channelsOut);
			done += k;
		}
		return n;
	}

	function resampleOnly(data:Bytes, frameCountIn:Int, out:Bytes, frameCountOut:Int):Int {
		var rs = resampler;
		if (!hasPre && !hasPost) {
			rs.process(data, 0, frameCountIn, out, 0, frameCountOut);
			return rs.produced;
		}
		var doneIn = 0, doneOut = 0, ch = rs.channels;
		while (doneOut < frameCountOut) {
			var outCap = Std.int(BLOCK / (mid * ch));
			var src = doneIn * formatIn * channelsIn,
				dst = doneOut * formatOut * channelsOut;
			if (hasPre) {
				var inCap = Std.int(BLOCK / (mid * ch));
				var nIn = min(frameCountIn - doneIn, inCap);
				if (hasPost)
					nIn = min(nIn, outCap);
				Samples.convert(tempIn, 0, mid, data, src, formatIn, nIn * channelsIn);
				var nOut = frameCountOut - doneOut;
				if (hasPost) {
					nOut = min(nOut, outCap);
					rs.process(tempIn, 0, nIn, tempOut, 0, nOut);
				} else
					rs.process(tempIn, 0, nIn, out, dst, nOut);
			} else
				rs.process(data, src, frameCountIn - doneIn, tempOut, 0, min(frameCountOut - doneOut, outCap));
			var nIn = rs.consumed, nOut = rs.produced;
			if (hasPost)
				Samples.convert(out, dst, formatOut, tempOut, 0, mid, nOut * ch);
			doneIn += nIn;
			doneOut += nOut;
			if (nOut == 0)
				break;
		}
		return doneOut;
	}

	function resampleFirst(data:Bytes, frameCountIn:Int, out:Bytes, frameCountOut:Int):Int {
		var rs = resampler;
		var inCap = Std.int(BLOCK / (mid * rs.channels)),
			midCap = inCap,
			outCap = Std.int(BLOCK / (mid * channelsOut));
		var doneIn = 0, doneOut = 0;
		while (doneOut < frameCountOut) {
			var src = doneIn * formatIn * channelsIn,
				dst = doneOut * formatOut * channelsOut;
			var nIn = frameCountIn - doneIn;
			if (hasPre)
				nIn = min(nIn, inCap);
			var nOut = min(frameCountOut - doneOut, midCap);
			if (hasPost)
				nOut = min(nOut, outCap);
			nIn = minFloat(nIn, rs.required(nOut));
			if (hasPre) {
				Samples.convert(tempIn, 0, mid, data, src, formatIn, nIn * channelsIn);
				rs.process(tempIn, 0, nIn, tempMid, 0, nOut);
			} else
				rs.process(data, src, nIn, tempMid, 0, nOut);
			nIn = rs.consumed;
			nOut = rs.produced;
			if (hasPost) {
				channels.process(tempOut, 0, tempMid, 0, nOut);
				Samples.convert(out, dst, formatOut, tempOut, 0, mid, nOut * channelsOut);
			} else
				channels.process(out, dst, tempMid, 0, nOut);
			doneIn += nIn;
			doneOut += nOut;
			if (nOut == 0)
				break;
		}
		return doneOut;
	}

	function channelsFirst(data:Bytes, frameCountIn:Int, out:Bytes, frameCountOut:Int):Int {
		var rs = resampler;
		var inCap = Std.int(BLOCK / (mid * channelsIn)),
			midCap = Std.int(BLOCK / (mid * channelsOut)),
			outCap = Std.int(BLOCK / (mid * rs.channels));
		var doneIn = 0, doneOut = 0;
		while (doneOut < frameCountOut) {
			var src = doneIn * formatIn * channelsIn,
				dst = doneOut * formatOut * channelsOut;
			var nOut = min(frameCountOut - doneOut, midCap);
			if (hasPost)
				nOut = min(nOut, outCap);
			var nIn = frameCountIn - doneIn;
			if (hasPre)
				nIn = min(nIn, inCap);
			nIn = min(nIn, midCap);
			nIn = minFloat(nIn, rs.required(nOut));
			if (hasPre) {
				Samples.convert(tempIn, 0, mid, data, src, formatIn, nIn * channelsIn);
				channels.process(tempMid, 0, tempIn, 0, nIn);
			} else
				channels.process(tempMid, 0, data, src, nIn);
			if (hasPost)
				rs.process(tempMid, 0, nIn, tempOut, 0, nOut);
			else
				rs.process(tempMid, 0, nIn, out, dst, nOut);
			nIn = rs.consumed;
			nOut = rs.produced;
			if (hasPost)
				Samples.convert(out, dst, formatOut, tempOut, 0, mid, nOut * channelsOut);
			doneIn += nIn;
			doneOut += nOut;
			if (nOut == 0)
				break;
		}
		return doneOut;
	}

	static inline function min(a:Int, b:Int):Int {
		return a < b ? a : b;
	}

	// An Int against a count that may pass an Int's range.
	static inline function minFloat(a:Int, b:Float):Int {
		return a < b ? a : Std.int(b);
	}
}

/** miniaudio's sample conversions without dither (`ma_pcm_convert`), and reading and writing a sample. */
private class Samples {
	static final U8_TO_F32 = Samples.f32(0.00784313725490196078);

	/** Converts count samples from src at srcAt to dst at dstAt. */
	public static function convert(dst:Bytes, dstAt:Int, formatOut:Int, src:Bytes, srcAt:Int, formatIn:Int, count:Int):Void {
		if (formatOut == formatIn) {
			dst.blit(dstAt, src, srcAt, count * formatOut);
			return;
		}
		switch [formatIn, formatOut] {
			case [1, 2]:
				for (i in 0...count)
					setS16(dst, dstAt + i * 2, (src.get(srcAt + i) - 128) << 8);
			case [1, 4]:
				for (i in 0...count)
					dst.setFloat(dstAt + i * 4, Samples.f32(Samples.f32(src.get(srcAt + i) * U8_TO_F32) - 1));
			case [2, 1]:
				for (i in 0...count)
					dst.set(dstAt + i, ((s16(src, srcAt + i * 2) >> 8) + 128) & 255);
			case [2, 4]:
				for (i in 0...count)
					dst.setFloat(dstAt + i * 4, s16(src, srcAt + i * 2) * 0.000030517578125);
			case [4, 1]:
				for (i in 0...count) {
					var x = src.getFloat(srcAt + i * 4);
					x = x < -1 ? -1 : x > 1 ? 1 : x;
					dst.set(dstAt + i, Std.int(Samples.f32(Samples.f32(x + 1) * 127.5)) & 255);
				}
			case _:
				f32ToS16(dst, dstAt, src, srcAt, count);
		}
	}

	// ma_pcm_f32_to_s16 on x86-64: its SSE2 blocks of 8 where both buffers are 16-byte aligned (no clip: truncated, then saturated), the
	// rest clipped and truncated.
	static function f32ToS16(dst:Bytes, dstAt:Int, src:Bytes, srcAt:Int, count:Int):Void {
		var i = 0;
		if (dstAt % 16 == 0 && srcAt % 16 == 0) {
			var blocks = count >> 3;
			for (_ in 0...blocks) {
				for (j in 0...8) {
					var v = Samples.f32(src.getFloat(srcAt + (i + j) * 4) * 32767);
					// cvttps2dq: truncated, or 0x80000000 when out of range.
					var outOfRange = Math.isNaN(v) || v >= 2147483648.0 || v < -2147483648.0;
					var t = outOfRange ? -2147483648.0 : v < 0 ? Math.fceil(v) : Math.ffloor(v);
					setS16(dst, dstAt + (i + j) * 2, Std.int(t < -32768 ? -32768 : t > 32767 ? 32767 : t));
				}
				i += 8;
			}
		}
		while (i < count) {
			var x = src.getFloat(srcAt + i * 4);
			x = x < -1 ? -1 : x > 1 ? 1 : x;
			setS16(dst, dstAt + i * 2, Math.isNaN(x) ? 0 : Std.int(Samples.f32(x * 32767)));
			i++;
		}
	}

	/** A number rounded to single precision, as each of C's float operations rounds. */
	public static inline function f32(x:Float):Float {
		#if js
		return js.lib.Math.fround(x);
		#elseif cpp
		var single:cpp.Float32 = x;
		return single;
		#else
		return haxe.io.FPHelper.i32ToFloat(haxe.io.FPHelper.floatToI32(x));
		#end
	}

	/** A signed 16-bit sample. */
	public static inline function s16(b:Bytes, at:Int):Int {
		return (b.getUInt16(at) << 16) >> 16;
	}

	/** Writes the low 16 bits of a sample. */
	public static inline function setS16(b:Bytes, at:Int, v:Int):Void {
		b.setUInt16(at, v & 0xffff);
	}

	/** A 32-bit multiply, wrapping as C's does. */
	public static inline function imul(a:Int, b:Int):Int {
		#if js
		return js.Syntax.code("Math.imul({0}, {1})", a, b);
		#else
		return a * b;
		#end
	}
}

/** miniaudio's channel converter with no channel maps given (its default, Microsoft's, for both) and its default (rectangular) mix: one
	channel spread to all, all averaged into one, or a weight for each pair. */
private class Channels {
	// Planes: left, right, front, back, bottom, top; by channel position (MA_CHANNEL_*), floats as miniaudio's table holds them.
	static final PLANES:Array<Float> = [
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, .5, 0, .5, 0, 0, 0, 0, .5, .5, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, .5, 0, 0, .5, 0, 0, 0, .5, 0, .5, 0,
		0, .25, 0, .75, 0, 0, 0, 0, .25, .75, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, .33, 0, .33, 0, 0, .34, 0, 0,
		.5, 0, 0, .5, 0, .33, .33, 0, 0, .34, .33, 0, 0, .33, 0, .34, 0, 0, 0, .5, 0, .5, 0, .33, 0, .33, 0, .34
	].map(v -> Samples.f32(v));

	final format:Int;
	final channelsIn:Int;
	final channelsOut:Int;
	// 0 mono out, 1 mono in, 2 weights.
	final path:Int;
	final weightsF32:Array<Array<Float>> = [];
	final weightsS16:Array<Array<Int>> = [];

	public function new(format:Int, channelsIn:Int, channelsOut:Int) {
		this.format = format;
		this.channelsIn = channelsIn;
		this.channelsOut = channelsOut;
		path = channelsOut == 1 ? 0 : channelsIn == 1 ? 1 : 2;
		if (path != 2)
			return;
		var weights = [for (_ in 0...channelsIn) [for (_ in 0...channelsOut) 0.]];
		for (i in 0...channelsIn)
			for (o in 0...channelsOut)
				if (position(channelsIn, i) == position(channelsOut, o))
					weights[i][o] = 1;
		for (i in 0...channelsIn) {
			var p = position(channelsIn, i);
			if (spatial(p) && !contains(channelsOut, p))
				for (o in 0...channelsOut) {
					var q = position(channelsOut, o);
					if (spatial(q) && weights[i][o] == 0)
						weights[i][o] = rectangular(p, q);
				}
		}
		for (o in 0...channelsOut) {
			var q = position(channelsOut, o);
			if (spatial(q) && !contains(channelsIn, q))
				for (i in 0...channelsIn) {
					var p = position(channelsIn, i);
					// The 16-bit weights are compared once fixed, as miniaudio keeps them.
					if (spatial(p) && (format == 4 ? weights[i][o] == 0 : fixed(weights[i][o]) == 0))
						weights[i][o] = rectangular(p, q);
				}
		}
		for (i in 0...channelsIn) {
			weightsF32.push(weights[i]);
			weightsS16.push([for (w in weights[i]) fixed(w)]);
		}
	}

	/** Converts count frames of src at srcAt into dst at dstAt. */
	public function process(dst:Bytes, dstAt:Int, src:Bytes, srcAt:Int, count:Int):Void {
		var ci = channelsIn, co = channelsOut;
		switch path {
			case 0:
				if (format == 4)
					for (f in 0...count) {
						var t = 0.;
						for (c in 0...ci)
							t = Samples.f32(t + src.getFloat(srcAt + (f * ci + c) * 4));
						dst.setFloat(dstAt + f * 4, Samples.f32(t / ci));
					}
				else
					for (f in 0...count) {
						var t = 0;
						for (c in 0...ci)
							t = (t + Samples.s16(src, srcAt + (f * ci + c) * 2)) | 0;
						// C divides the int32 sum by the uint32 channel count as unsigned.
						var u:Float = t < 0 ? t + 4294967296.0 : t;
						var q = Math.ffloor(u / ci);
						Samples.setS16(dst, dstAt + f * 2, Std.int(q % 65536));
					}
			case 1:
				for (f in 0...count)
					for (c in 0...co)
						dst.blit(dstAt + (f * co + c) * format, src, srcAt + f * format, format);
			case _:
				dst.fill(dstAt, count * co * format, 0);
				if (format == 4)
					for (f in 0...count)
						for (i in 0...ci) {
							var x = src.getFloat(srcAt + (f * ci + i) * 4),
								w = weightsF32[i];
							for (o in 0...co) {
								var at = dstAt + (f * co + o) * 4;
								dst.setFloat(at, Samples.f32(dst.getFloat(at) + Samples.f32(x * w[o])));
							}
						}
				else
					for (f in 0...count)
						for (i in 0...ci) {
							var x = Samples.s16(src, srcAt + (f * ci + i) * 2),
								w = weightsS16[i];
							for (o in 0...co) {
								var at = dstAt + (f * co + o) * 2;
								var s = Samples.s16(dst, at) + (Samples.imul(x, w[o]) >> 12);
								Samples.setS16(dst, at, s < -32768 ? -32768 : s > 32767 ? 32767 : s);
							}
						}
		}
	}

	// ma_channel_converter_float_to_fixed: the weight times 4096, in single precision, truncated.
	static function fixed(weight:Float):Int {
		return Std.int(Samples.f32(weight * 4096));
	}

	// The default (Microsoft) channel map's position of a channel (MA_CHANNEL_*).
	static function position(count:Int, index:Int):Int {
		if (count == 0 || index >= count)
			return 0;
		var map = switch count {
			case 1: [1];
			case 2: [2, 3];
			case 3: [2, 3, 4];
			case 4: [2, 3, 4, 10];
			case 5: [2, 3, 4, 6, 7];
			case 6: [2, 3, 4, 5, 11, 12];
			case 7: [2, 3, 4, 5, 10, 11, 12];
			case _: [2, 3, 4, 5, 6, 7, 11, 12];
		}
		if (index < map.length)
			return map[index];
		return count > 8 && index < 32 ? 20 + index - 8 : 0;
	}

	static function contains(count:Int, p:Int):Bool {
		for (i in 0...count)
			if (position(count, i) == p)
				return true;
		return false;
	}

	static function spatial(p:Int):Bool {
		if (p == 0 || p == 1 || p == 5 || p >= 20)
			return false;
		for (k in 0...6)
			if (PLANES[p * 6 + k] != 0)
				return true;
		return false;
	}

	static function rectangular(a:Int, b:Int):Float {
		var sum = Samples.f32(PLANES[a * 6] * PLANES[b * 6]);
		for (k in 1...6)
			sum = Samples.f32(sum + Samples.f32(PLANES[a * 6 + k] * PLANES[b * 6 + k]));
		return sum;
	}
}

/** miniaudio's linear resampler (s16 or f32) with its low-pass filter of order 4: two second-order biquads. */
private class Resampler {
	public final channels:Int;

	/** The input frames the last `process` took, and the output frames it gave. */
	public var consumed = 0;

	public var produced = 0;

	final format:Int;
	final rateIn:Int;
	final rateOut:Int;
	final advanceInt:Int;
	final advanceFrac:Int;
	var timeInt = 1;
	var timeFrac = 0;
	final x0:Array<Float>;
	final x1:Array<Float>;
	// Each biquad's coefficients (b0, b1, b2, a1, a2), as floats or as 14-bit fixed point, and its two registers a channel.
	final coefficients:Array<Array<Float>> = [];
	final r1:Array<Array<Float>> = [];
	final r2:Array<Array<Float>> = [];
	final frame:Array<Float>;

	public function new(format:Int, channels:Int, sampleRateIn:Int, sampleRateOut:Int) {
		this.format = format;
		this.channels = channels;
		var a = sampleRateIn, b = sampleRateOut;
		while (b != 0) {
			var t = a;
			a = b;
			b = t % a;
		}
		rateIn = Std.int(sampleRateIn / a);
		rateOut = Std.int(sampleRateOut / a);
		advanceInt = Std.int(rateIn / rateOut);
		advanceFrac = rateIn % rateOut;
		x0 = [for (_ in 0...channels) 0.];
		x1 = [for (_ in 0...channels) 0.];
		frame = [for (_ in 0...channels) 0.];
		var lpfRate:Float = rateIn > rateOut ? rateIn : rateOut;
		var cutoff = (rateIn < rateOut ? rateIn : rateOut) * 0.5 * 1;
		for (i in 0...2) {
			var angle = (1 + i * 2) * (Math.PI / 8);
			var q = 1 / (2 * Math.sin(Math.PI * 0.5 - angle));
			var w = 2 * Math.PI * cutoff / lpfRate;
			var s = Math.sin(w), c = Math.sin(Math.PI * 0.5 - w);
			var alpha = s / (2 * q);
			var b0 = (1 - c) / 2, b1 = 1 - c, b2 = (1 - c) / 2, a0 = 1 + alpha, a1 = -2 * c, a2 = 1 - alpha;
			var raw = [b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0];
			coefficients.push(format == 4 ? raw.map(v -> Samples.f32(v)) : raw.map(v -> (Std.int(v * 16384) : Float)));
			r1.push([for (_ in 0...channels) 0.]);
			r2.push([for (_ in 0...channels) 0.]);
		}
	}

	/** `ma_linear_resampler_get_expected_output_frame_count`. */
	public function expected(frameCountIn:Float):Int {
		var out = Math.ffloor(frameCountIn * rateOut / rateIn);
		var fromFrac = Math.ffloor((timeFrac + out * advanceFrac) / rateOut);
		var preliminary = (timeInt + out * advanceInt) + fromFrac;
		if (preliminary <= frameCountIn)
			out += 1;
		return Std.int(out);
	}

	/** `ma_linear_resampler_get_required_input_frame_count`. */
	public function required(frameCountOut:Int):Float {
		if (frameCountOut == 0)
			return 0;
		var n = frameCountOut - 1;
		return timeInt + n * advanceInt + Math.ffloor((timeFrac + n * advanceFrac) / rateOut);
	}

	/** Resamples up to frameCountIn frames of src at srcAt into up to frameCountOut frames of dst at dstAt; sets consumed and produced. */
	public function process(src:Bytes, srcAt:Int, frameCountIn:Int, dst:Bytes, dstAt:Int, frameCountOut:Int):Void {
		var down = rateIn > rateOut, filtered = rateIn != rateOut;
		var doneIn = 0, doneOut = 0, ch = channels;
		while (doneOut < frameCountOut) {
			while (timeInt > 0 && frameCountIn > doneIn) {
				for (c in 0...ch) {
					x0[c] = x1[c];
					x1[c] = format == 4 ? src.getFloat(srcAt + (doneIn * ch + c) * 4) : Samples.s16(src, srcAt + (doneIn * ch + c) * 2);
				}
				if (down && filtered)
					filter(x1);
				doneIn++;
				timeInt--;
			}
			if (timeInt > 0)
				break;
			if (format == 4) {
				var a = Samples.f32(timeFrac / rateOut);
				for (c in 0...ch)
					frame[c] = Samples.f32(x0[c] + Samples.f32(Samples.f32(x1[c] - x0[c]) * a));
			} else {
				var a = Std.int(timeFrac * 4096. / rateOut);
				for (c in 0...ch) {
					var r = (Samples.imul(Std.int(x0[c]), 4096 - a) + Samples.imul(Std.int(x1[c]), a)) | 0;
					frame[c] = ((r >> 12) << 16) >> 16;
				}
			}
			if (!down && filtered)
				filter(frame);
			for (c in 0...ch)
				if (format == 4)
					dst.setFloat(dstAt + (doneOut * ch + c) * 4, frame[c]);
				else
					Samples.setS16(dst, dstAt + (doneOut * ch + c) * 2, Std.int(frame[c]));
			doneOut++;
			timeInt += advanceInt;
			timeFrac += advanceFrac;
			if (timeFrac >= rateOut) {
				timeFrac -= rateOut;
				timeInt++;
			}
		}
		consumed = doneIn;
		produced = doneOut;
	}

	// The low-pass filter on one frame, in place: each biquad in turn, direct form 2 transposed.
	function filter(x:Array<Float>):Void {
		for (k in 0...2) {
			var q = coefficients[k], s1 = r1[k], s2 = r2[k];
			if (format == 4) {
				var b0 = q[0], b1 = q[1], b2 = q[2], a1 = q[3], a2 = q[4];
				for (c in 0...channels) {
					var v = x[c];
					var y = Samples.f32(Samples.f32(b0 * v) + s1[c]);
					s1[c] = Samples.f32(Samples.f32(Samples.f32(b1 * v) - Samples.f32(a1 * y)) + s2[c]);
					s2[c] = Samples.f32(Samples.f32(b2 * v) - Samples.f32(a2 * y));
					x[c] = y;
				}
			} else {
				var b0 = Std.int(q[0]),
					b1 = Std.int(q[1]),
					b2 = Std.int(q[2]),
					a1 = Std.int(q[3]),
					a2 = Std.int(q[4]);
				for (c in 0...channels) {
					var v = Std.int(x[c]);
					var y = ((Samples.imul(b0, v) + Std.int(s1[c])) | 0) >> 14;
					s1[c] = (Samples.imul(b1, v) - Samples.imul(a1, y) + Std.int(s2[c])) | 0;
					s2[c] = (Samples.imul(b2, v) - Samples.imul(a2, y)) | 0;
					x[c] = y < -32768 ? -32768 : y > 32767 ? 32767 : y;
				}
			}
		}
	}
}
