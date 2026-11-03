package helix.formats.qoa;

import haxe.Int32;
import haxe.io.Bytes;

/** Represents the sound read from a QOA file ("Quite OK Audio"): its rate, channels and 16-bit samples.

	Reading is qoa.h's `qoa_decode` (raylib 5.5's copy), ported, so its samples are those raylib's `LoadWave` gives, bit for bit. A file
	whose frames end early, or stop being valid, gives the frames read until then, as qoa.h does. A streamed file (its frame count 0)
	isn't read, as qoa.h doesn't read one.

	```haxe
	var qoa = QoaFile.read(bytes);
	trace(qoa.sampleRate, qoa.channelCount, qoa.frameCount / qoa.sampleRate);
	var samples = qoa.samples; // raylib's Wave: sampleSize 16
	``` */
class QoaFile {
	/** Gets the frames a second, 1 to 16777215. */
	public final sampleRate:Int;

	/** Gets the number of channels a frame has, 1 to 255: 1 is mono, 2 stereo. */
	public final channelCount:Int;

	/** Gets the frames read, a sample for each channel. */
	public final frameCount:Int;

	/** Gets the samples: `frameCount` frames, each a sample for each channel in turn, 16-bit signed and little-endian. */
	public final samples:Bytes;

	function new(sampleRate:Int, channelCount:Int, frameCount:Int, samples:Bytes) {
		this.sampleRate = sampleRate;
		this.channelCount = channelCount;
		this.frameCount = frameCount;
		this.samples = samples;
	}

	/** Reads a QOA file.

		@param data  The file.
		@return  The sound.
		@throws String  It isn't a QOA file qoa.h reads: it is under 16 bytes, its magic is wrong, or its frame count, channels or rate
			is 0. */
	public static function read(data:Bytes):QoaFile {
		var size = data.length;
		if (size < MIN_FILESIZE || read32(data, 0) != MAGIC)
			throw "not a QOA file: its header is wrong";
		var frames = read32(data, 4);
		var channels = data.get(8),
			rate = (data.get(9) << 16) | (data.get(10) << 8) | data.get(11);
		if (frames == 0 || channels == 0 || rate == 0)
			throw "not a QOA file: its frame count, channels or rate is 0";
		// qoa.h's buffer holds the frames the header gives; an int over 2^31 is negative here, which no file this reads has.
		if (frames < 0 || frames > 0x7FFFFFFF / (2 * channels))
			throw "not a QOA file: too many frames";
		var out = Bytes.alloc(frames * channels * 2);
		var history = [for (_ in 0...channels * LMS_LEN) 0],
			weights = [for (_ in 0...channels * LMS_LEN) 0];
		var p = 8, index = 0;
		while (index < frames) {
			var got = frame(data, p, size - p, channels, rate, history, weights, out, index, frames);
			if (got.bytes == 0)
				break;
			p += got.bytes;
			index += got.frames;
		}
		// A last frame giving more than the header's count overruns qoa.h's buffer; only the header's are kept here.
		if (index > frames)
			index = frames;
		return new QoaFile(rate, channels, index, index == frames ? out : out.sub(0, index * channels * 2));
	}

	// qoa_decode_frame: decodes the frame at p into out from frame index, returning the bytes it took and the frames it gave; 0 bytes
	// for a frame that is too short or doesn't match the file. Frames past the file's count would overrun qoa.h's buffer; they aren't
	// written here.
	static function frame(data:Bytes, p:Int, size:Int, channels:Int, rate:Int, history:Array<Int>, weights:Array<Int>, out:Bytes, index:Int,
			total:Int):{bytes:Int, frames:Int} {
		var none = {bytes: 0, frames: 0};
		if (size < 8 + LMS_LEN * 4 * channels)
			return none;
		var start = p;
		var frameChannels = data.get(p),
			frameRate = (data.get(p + 1) << 16) | (data.get(p + 2) << 8) | data.get(p + 3);
		var samples = (data.get(p + 4) << 8) | data.get(p + 5),
			frameSize = (data.get(p + 6) << 8) | data.get(p + 7);
		p += 8;
		// qoa.h's unsigned arithmetic, wrapping as it does: a frame size under its header and state is a huge slice count.
		var maxSamples:Int32 = ((frameSize - 8 - LMS_LEN * 4 * channels) >>> 3);
		maxSamples *= SLICE_LEN;
		var over = maxSamples >= 0 && samples * channels > maxSamples;
		if (frameChannels != channels || frameRate != rate || frameSize > size || over)
			return none;
		for (c in 0...channels) {
			for (i in 0...LMS_LEN)
				history[c * LMS_LEN + i] = signed16(data, p + i * 2);
			for (i in 0...LMS_LEN)
				weights[c * LMS_LEN + i] = signed16(data, p + 8 + i * 2);
			p += 16;
		}
		var sampleIndex = 0;
		while (sampleIndex < samples) {
			for (c in 0...channels) {
				var high = read32(data, p), low = read32(data, p + 4);
				p += 8;
				var scalefactor = (high >>> 28) & 0xF;
				var end = sampleIndex + SLICE_LEN < samples ? sampleIndex + SLICE_LEN : samples;
				var h = c * LMS_LEN;
				for (s in sampleIndex...end) {
					// The residual's 3 bits, the first just under the scalefactor's 4: bits 59 to 57 of the slice, then 56 to 54, and so on.
					var bit = 57 - 3 * (s - sampleIndex);
					var quantized = bit >= 32 ? (high >>> (bit - 32)) & 7 : bit <= 29 ? (low >>> bit) & 7 : ((low >>> bit) | (high << (32 - bit))) & 7;
					var predicted:Int32 = 0;
					for (i in 0...LMS_LEN)
						predicted += (weights[h + i] : Int32) * (history[h + i] : Int32);
					var dequantized = DEQUANT[scalefactor * 8 + quantized];
					var reconstructed = clamp16((predicted >> 13) + dequantized);
					var at = index + s;
					if (at < total)
						out.setUInt16((at * channels + c) * 2, reconstructed & 0xFFFF);
					var delta = dequantized >> 4;
					for (i in 0...LMS_LEN) {
						var weight:Int32 = weights[h + i];
						weight += history[h + i] < 0 ? -delta : delta;
						weights[h + i] = weight;
					}
					history[h] = history[h + 1];
					history[h + 1] = history[h + 2];
					history[h + 2] = history[h + 3];
					history[h + 3] = reconstructed;
				}
			}
			sampleIndex += SLICE_LEN;
		}
		return {bytes: p - start, frames: samples};
	}

	static inline function clamp16(v:Int):Int
		return v < -32768 ? -32768 : v > 32767 ? 32767 : v;

	static inline function read32(data:Bytes, p:Int):Int
		return (data.get(p) << 24) | (data.get(p + 1) << 16) | (data.get(p + 2) << 8) | data.get(p + 3);

	static inline function signed16(data:Bytes, p:Int):Int {
		var v = (data.get(p) << 8) | data.get(p + 1);
		return v >= 0x8000 ? v - 0x10000 : v;
	}

	static inline final MIN_FILESIZE = 16;
	static inline final MAGIC = 0x716f6166;
	static inline final SLICE_LEN = 20;
	static inline final LMS_LEN = 4;

	// qoa_dequant_tab: each scalefactor's 8 dequantized residuals.
	static final DEQUANT = [
		   1,    -1,    3,    -3,    5,    -5,     7,     -7,
		   5,    -5,   18,   -18,   32,   -32,    49,    -49,
		  16,   -16,   53,   -53,   95,   -95,   147,   -147,
		  34,   -34,  113,  -113,  203,  -203,   315,   -315,
		  63,   -63,  210,  -210,  378,  -378,   588,   -588,
		 104,  -104,  345,  -345,  621,  -621,   966,   -966,
		 158,  -158,  528,  -528,  950,  -950,  1477,  -1477,
		 228,  -228,  760,  -760, 1368, -1368,  2128,  -2128,
		 316,  -316, 1053, -1053, 1895, -1895,  2947,  -2947,
		 422,  -422, 1405, -1405, 2529, -2529,  3934,  -3934,
		 548,  -548, 1828, -1828, 3290, -3290,  5117,  -5117,
		 696,  -696, 2320, -2320, 4176, -4176,  6496,  -6496,
		 868,  -868, 2893, -2893, 5207, -5207,  8099,  -8099,
		1064, -1064, 3548, -3548, 6386, -6386,  9933,  -9933,
		1286, -1286, 4288, -4288, 7718, -7718, 12005, -12005,
		1536, -1536, 5120, -5120, 9216, -9216, 14336, -14336
	];
}
