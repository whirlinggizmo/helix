package helix.formats.wav;

import haxe.io.Bytes;
import haxe.io.FPHelper;

/** Represents the sound read from a WAV file: its rate, channels, sample size and samples; and provides writing one.

	Reading is dr_wav 0.13.16's (raylib 5.5's copy), ported: a RIFF WAVE file of integer, floating-point, A-law or mu-law samples, its
	format given plainly or as `WAVE_FORMAT_EXTENSIBLE`. Chunks before the samples that it doesn't need are skipped; those after them are
	never read. `toInt16` converts the samples as raylib's `LoadWave` does, and `toFloat32` as its music streams of 32-bit files do.
	Writing is raylib's `ExportWave`, byte for byte.

	```haxe
	var wav = WavFile.read(bytes);
	trace(wav.sampleRate, wav.channelCount, wav.frameCount / wav.sampleRate);
	var samples = wav.toInt16(); // raylib's Wave: sampleSize 16
	var file = WavFile.write(wav.sampleRate, wav.channelCount, 16, wav.frameCount, samples);
	``` */
class WavFile {
	/** Gets the frames a second, 1 to 384000. */
	public final sampleRate:Int;

	/** Gets the number of channels a frame has, 1 to 256: 1 is mono, 2 stereo. */
	public final channelCount:Int;

	/** Gets the bits a sample takes in `samples`: 8, 16, 24, 32 or more for `Pcm`, 32 or 64 for `FloatingPoint`, 8 for `ALaw` and
		`MuLaw`. A file whose samples have bits not a multiple of 8 (12 in 16, say) gives the size they are stored in. */
	public final sampleSize:Int;

	/** Gets how the samples are stored. */
	public final encoding:WavEncoding;

	/** Gets the frames, a sample for each channel. */
	public final frameCount:Int;

	/** Gets the samples as the file stores them: `frameCount` frames, each a sample for each channel in turn, each `sampleSize / 8`
		bytes, little-endian. */
	public final samples:Bytes;

	function new(sampleRate:Int, channelCount:Int, sampleSize:Int, encoding:WavEncoding, frameCount:Int, samples:Bytes) {
		this.sampleRate = sampleRate;
		this.channelCount = channelCount;
		this.sampleSize = sampleSize;
		this.encoding = encoding;
		this.frameCount = frameCount;
		this.samples = samples;
	}

	/** Reads a WAV file.

		The frames are those whole in the data chunk; a data chunk whose size is 0 or 0xFFFFFFFF, as a streamed file leaves it, runs to
		the file's end, and one larger than the file stops at its end. A `fact` chunk is skipped, as dr_wav skips it for these encodings.

		@param data  The file.
		@return  The sound, its samples as the file stores them.
		@throws String  It isn't a WAV file this reads: it has no RIFF WAVE header (RIFX, RF64, Wave64 and AIFF aren't read), no
			format or data chunk, a format out of range, or samples stored some other way (ADPCM and compressed encodings aren't read). */
	public static function read(data:Bytes):WavFile {
		var size = data.length;
		if (!matches(data, 0, "RIFF") || !matches(data, 8, "WAVE"))
			throw "not a WAV file: no RIFF WAVE header";
		var formatTag = 0, channelCount = 0, sampleRate = 0, blockAlign = 0, bitsPerSample = 0, subFormat = 0;
		var foundFormat = false;
		var dataPos = -1, dataSize = 0;
		var p = 12;
		while (p + 8 <= size) {
			var chunkSize = data.getInt32(p + 4);
			var start = p + 8;
			var padding = chunkSize & 1;
			var unsignedSize:Float = unsigned(chunkSize);
			if (matches(data, p, "fmt ")) {
				if (start + 16 > size)
					throw "not a WAV file: its format chunk ends early";
				foundFormat = true;
				formatTag = data.getUInt16(start);
				channelCount = data.getUInt16(start + 2);
				sampleRate = data.getInt32(start + 4);
				blockAlign = data.getUInt16(start + 12);
				bitsPerSample = data.getUInt16(start + 14);
				subFormat = 0;
				var next = start + 16;
				if (unsignedSize > 16) {
					if (start + 18 > size)
						throw "not a WAV file: its format chunk ends early";
					var extendedSize = data.getUInt16(start + 16);
					if (extendedSize > 0) {
						if (formatTag == EXTENSIBLE) {
							if (extendedSize != 22 || start + 18 + 22 > size)
								throw "not a WAV file: its extensible format is wrong";
							subFormat = data.getUInt16(start + 18 + 6);
						} else if (start + 18 + extendedSize > size)
							throw "not a WAV file: its format chunk ends early";
					}
					if (unsignedSize > size - start)
						throw "not a WAV file: its format chunk ends early";
					next = start + chunkSize;
				}
				if (next + padding > size)
					break;
				p = next + padding;
			} else if (matches(data, p, "data")) {
				dataPos = start;
				dataSize = chunkSize;
				break;
			} else if (matches(data, p, "fact")) {
				if (start + 4 > size)
					throw "not a WAV file: its fact chunk ends early";
				if (unsignedSize < 4 || unsignedSize + padding > size - start)
					break;
				p = start + chunkSize + padding;
			} else {
				if (unsignedSize + padding > size - start)
					break;
				p = start + chunkSize + padding;
			}
		}
		if (!foundFormat || dataPos < 0)
			throw "not a WAV file: it has no format or no data chunk";
		if (sampleRate <= 0 || sampleRate > 384000 || channelCount == 0 || channelCount > 256 || bitsPerSample == 0 || bitsPerSample > 64 || blockAlign == 0)
			throw "not a WAV file: its format is out of range";
		var tag = formatTag == EXTENSIBLE ? subFormat : formatTag;
		if (tag != PCM && tag != IEEE_FLOAT && tag != ALAW && tag != MULAW)
			throw 'a WAV file of format 0x${StringTools.hex(tag, 4)}: only integer, floating-point, A-law and mu-law samples are read';
		var bytesPerFrame = (bitsPerSample & 7) == 0 ? (bitsPerSample * channelCount) >> 3 : blockAlign;
		var bytesPerSample = Std.int(bytesPerFrame / channelCount);
		if (bytesPerSample == 0 || bytesPerFrame % channelCount != 0)
			throw "a WAV file whose samples aren't a whole number of bytes";
		if ((tag == ALAW || tag == MULAW) && bytesPerSample != 1)
			throw "a WAV file of A-law or mu-law samples of more than a byte";
		if (tag == PCM && bytesPerSample > 8 || tag == IEEE_FLOAT && bytesPerSample != 4 && bytesPerSample != 8)
			throw 'a WAV file of ${bytesPerSample * 8}-bit ${tag == PCM ? "integer" : "floating-point"} samples';
		var available = size - dataPos;
		if (dataSize == 0 || dataSize < 0 || dataSize > available)
			dataSize = available;
		var frameCount = Std.int(dataSize / bytesPerFrame);
		var encoding:WavEncoding = cast tag;
		return new WavFile(sampleRate, channelCount, bytesPerSample * 8, encoding, frameCount, data.sub(dataPos, frameCount * bytesPerFrame));
	}

	/** Returns the samples as 16-bit signed integers, as raylib's `LoadWave` gives a WAV file's (dr_wav's `drwav_read_pcm_frames_s16`).

		8-bit samples are moved to signed and widened; wider integers keep their top 16 bits; floating point is clamped to -1 to 1 and
		scaled to -32768 to 32767; A-law and mu-law are expanded by G.711's tables.

		@return  `frameCount` frames, a sample for each channel in turn, 2 bytes each, little-endian. */
	public function toInt16():Bytes {
		var count = frameCount * channelCount;
		var out = Bytes.alloc(count * 2);
		var bytes = sampleSize >> 3;
		var p = 0;
		for (i in 0...count) {
			var v = switch encoding {
				case Pcm:
					switch bytes {
						case 1: (samples.get(p) << 8) - 32768;
						case 2: samples.getUInt16(p);
						case 3: samples.getUInt16(p + 1);
						case _: samples.getUInt16(p + bytes - 2);
					}
				case FloatingPoint:
					if (bytes == 4) {
						var x = samples.getFloat(p);
						if (Math.isNaN(x))
							-32768;
						else {
							var c = x < -1 ? -1.0 : (x > 1 ? 1.0 : x);
							Std.int(f32(f32(c + 1) * 32767.5)) - 32768;
						}
					} else {
						var x = samples.getDouble(p);
						if (Math.isNaN(x))
							-32768;
						else {
							var c = x < -1 ? -1.0 : (x > 1 ? 1.0 : x);
							Std.int((c + 1) * 32767.5) - 32768;
						}
					}
				case ALaw:
					ALAW_TABLE[samples.get(p)];
				case MuLaw:
					MULAW_TABLE[samples.get(p)];
			}
			out.setUInt16(i * 2, v & 0xFFFF);
			p += bytes;
		}
		return out;
	}

	/** Returns the samples as 32-bit floating point, -1 to 1, as raylib's music streams read a 32-bit WAV file (dr_wav's
		`drwav_read_pcm_frames_f32`).

		Integers are divided by their range (8-bit samples by 127.5, after moving to signed); A-law and mu-law are expanded to 16 bits
		first; 64-bit floating point is rounded to 32 bits.

		@return  `frameCount` frames, a sample for each channel in turn, 4 bytes each, little-endian. */
	public function toFloat32():Bytes {
		var count = frameCount * channelCount;
		var out = Bytes.alloc(count * 4);
		var bytes = sampleSize >> 3;
		var p = 0;
		for (i in 0...count) {
			var v:Float = switch encoding {
				case Pcm:
					switch bytes {
						case 1: f32(f32(samples.get(p) * U8_SCALE) - 1);
						case 2: signed16(samples.getUInt16(p)) * 0.000030517578125;
						case 3: (signed16(samples.getUInt16(p + 1)) * 256 + samples.get(p)) * 0.00000011920928955078125;
						case 4: samples.getInt32(p) / 2147483648.0;
						case _:
							// The sample as a signed 64-bit integer, its bytes at the top, divided by 2^63.
							var high = 0, low = 0;
							for (j in 0...bytes) {
								var shift = (8 - bytes + j) * 8;
								if (shift >= 32)
									high |= samples.get(p + j) << (shift - 32);
								else
									low |= samples.get(p + j) << shift;
							}
							(high * 4294967296.0 + unsigned(low)) / 9223372036854775807.0;
					}
				case FloatingPoint:
					bytes == 4 ? samples.getFloat(p) : samples.getDouble(p);
				case ALaw:
					signed16(ALAW_TABLE[samples.get(p)]) / 32768.0;
				case MuLaw:
					signed16(MULAW_TABLE[samples.get(p)]) / 32768.0;
			}
			out.setFloat(i * 4, v);
			p += bytes;
		}
		return out;
	}

	/** Writes samples as a WAV file, byte for byte as raylib's `ExportWave` writes a `Wave` (dr_wav's writer).

		8, 16 and 24 bits are integer samples (format 1, 8 bits unsigned), and 32 bits floating point (format 3), as raylib's `Wave`
		takes them. The file is a 16-byte format chunk and the data chunk, padded to an even size; it has no `fact` chunk. Bytes past the
		samples are ignored.

		@param sampleRate  The frames a second.
		@param channelCount  The channels a frame has.
		@param sampleSize  The bits a sample takes: 8, 16, 24 or 32.
		@param frameCount  The frames to write, a sample for each channel.
		@param samples  The samples, a sample for each channel in turn, `sampleSize / 8` bytes each, little-endian.
		@return  The WAV file.
		@throws String  The rate is under 1, the channels are outside 1 to 65535, the sample size isn't 8, 16, 24 or 32, the frame
			count is negative, or there are fewer samples than it needs. */
	public static function write(sampleRate:Int, channelCount:Int, sampleSize:Int, frameCount:Int, samples:Bytes):Bytes {
		if (sampleRate < 1 || channelCount < 1 || channelCount > 0xFFFF)
			throw 'A WAV file of $channelCount channels at $sampleRate frames a second: the rate must be 1 or more, the channels 1 to 65535';
		if (sampleSize != 8 && sampleSize != 16 && sampleSize != 24 && sampleSize != 32)
			throw 'A WAV file of $sampleSize-bit samples: it takes 8, 16, 24 or 32';
		var dataSize = frameCount * channelCount * (sampleSize >> 3);
		if (frameCount < 0 || samples.length < dataSize)
			throw 'A WAV file of $frameCount frames of $channelCount channels needs $dataSize bytes, given ${samples.length}';
		var padding = dataSize & 1;
		var out = Bytes.alloc(44 + dataSize + padding);
		out.blit(0, Bytes.ofString("RIFF"), 0, 4);
		out.setInt32(4, 36 + dataSize + padding);
		out.blit(8, Bytes.ofString("WAVEfmt "), 0, 8);
		out.setInt32(16, 16);
		out.setUInt16(20, sampleSize == 32 ? IEEE_FLOAT : PCM);
		out.setUInt16(22, channelCount);
		out.setInt32(24, sampleRate);
		out.setInt32(28, Std.int(sampleSize * sampleRate * channelCount / 8));
		out.setUInt16(32, (channelCount * sampleSize >> 3) & 0xFFFF);
		out.setUInt16(34, sampleSize);
		out.blit(36, Bytes.ofString("data"), 0, 4);
		out.setInt32(40, dataSize);
		out.blit(44, samples, 0, dataSize);
		return out;
	}

	static inline final PCM = 1;
	static inline final IEEE_FLOAT = 3;
	static inline final ALAW = 6;
	static inline final MULAW = 7;
	static inline final EXTENSIBLE = 0xFFFE;

	// dr_wav's 0.00784313725490196078f (2 / 255), as a 32-bit float.
	static final U8_SCALE = f32(0.00784313725490196078);

	// A 32-bit unsigned integer's value.
	// Whether the bytes at p are the ASCII text given (Bytes.getString decodes UTF-8, which arbitrary bytes may not be).
	static function matches(bytes:Bytes, p:Int, text:String):Bool {
		if (p < 0 || p + text.length > bytes.length)
			return false;
		for (i in 0...text.length)
			if (bytes.get(p + i) != StringTools.fastCodeAt(text, i))
				return false;
		return true;
	}

	static inline function unsigned(v:Int):Float
		return v < 0 ? v + 4294967296.0 : v;

	static inline function signed16(v:Int):Int
		return (v << 16) >> 16;

	// The 32-bit float nearest x, as C's float arithmetic rounds each step.
	static inline function f32(x:Float):Float
		return FPHelper.i32ToFloat(FPHelper.floatToI32(x));

	// dr_wav's g_drwavAlawTable and g_drwavMulawTable: each byte's 16-bit sample.
	static final ALAW_TABLE = [
		0xEA80, 0xEB80, 0xE880, 0xE980, 0xEE80, 0xEF80, 0xEC80, 0xED80, 0xE280, 0xE380, 0xE080, 0xE180, 0xE680, 0xE780, 0xE480, 0xE580,
		0xF540, 0xF5C0, 0xF440, 0xF4C0, 0xF740, 0xF7C0, 0xF640, 0xF6C0, 0xF140, 0xF1C0, 0xF040, 0xF0C0, 0xF340, 0xF3C0, 0xF240, 0xF2C0,
		0xAA00, 0xAE00, 0xA200, 0xA600, 0xBA00, 0xBE00, 0xB200, 0xB600, 0x8A00, 0x8E00, 0x8200, 0x8600, 0x9A00, 0x9E00, 0x9200, 0x9600,
		0xD500, 0xD700, 0xD100, 0xD300, 0xDD00, 0xDF00, 0xD900, 0xDB00, 0xC500, 0xC700, 0xC100, 0xC300, 0xCD00, 0xCF00, 0xC900, 0xCB00,
		0xFEA8, 0xFEB8, 0xFE88, 0xFE98, 0xFEE8, 0xFEF8, 0xFEC8, 0xFED8, 0xFE28, 0xFE38, 0xFE08, 0xFE18, 0xFE68, 0xFE78, 0xFE48, 0xFE58,
		0xFFA8, 0xFFB8, 0xFF88, 0xFF98, 0xFFE8, 0xFFF8, 0xFFC8, 0xFFD8, 0xFF28, 0xFF38, 0xFF08, 0xFF18, 0xFF68, 0xFF78, 0xFF48, 0xFF58,
		0xFAA0, 0xFAE0, 0xFA20, 0xFA60, 0xFBA0, 0xFBE0, 0xFB20, 0xFB60, 0xF8A0, 0xF8E0, 0xF820, 0xF860, 0xF9A0, 0xF9E0, 0xF920, 0xF960,
		0xFD50, 0xFD70, 0xFD10, 0xFD30, 0xFDD0, 0xFDF0, 0xFD90, 0xFDB0, 0xFC50, 0xFC70, 0xFC10, 0xFC30, 0xFCD0, 0xFCF0, 0xFC90, 0xFCB0,
		0x1580, 0x1480, 0x1780, 0x1680, 0x1180, 0x1080, 0x1380, 0x1280, 0x1D80, 0x1C80, 0x1F80, 0x1E80, 0x1980, 0x1880, 0x1B80, 0x1A80,
		0x0AC0, 0x0A40, 0x0BC0, 0x0B40, 0x08C0, 0x0840, 0x09C0, 0x0940, 0x0EC0, 0x0E40, 0x0FC0, 0x0F40, 0x0CC0, 0x0C40, 0x0DC0, 0x0D40,
		0x5600, 0x5200, 0x5E00, 0x5A00, 0x4600, 0x4200, 0x4E00, 0x4A00, 0x7600, 0x7200, 0x7E00, 0x7A00, 0x6600, 0x6200, 0x6E00, 0x6A00,
		0x2B00, 0x2900, 0x2F00, 0x2D00, 0x2300, 0x2100, 0x2700, 0x2500, 0x3B00, 0x3900, 0x3F00, 0x3D00, 0x3300, 0x3100, 0x3700, 0x3500,
		0x0158, 0x0148, 0x0178, 0x0168, 0x0118, 0x0108, 0x0138, 0x0128, 0x01D8, 0x01C8, 0x01F8, 0x01E8, 0x0198, 0x0188, 0x01B8, 0x01A8,
		0x0058, 0x0048, 0x0078, 0x0068, 0x0018, 0x0008, 0x0038, 0x0028, 0x00D8, 0x00C8, 0x00F8, 0x00E8, 0x0098, 0x0088, 0x00B8, 0x00A8,
		0x0560, 0x0520, 0x05E0, 0x05A0, 0x0460, 0x0420, 0x04E0, 0x04A0, 0x0760, 0x0720, 0x07E0, 0x07A0, 0x0660, 0x0620, 0x06E0, 0x06A0,
		0x02B0, 0x0290, 0x02F0, 0x02D0, 0x0230, 0x0210, 0x0270, 0x0250, 0x03B0, 0x0390, 0x03F0, 0x03D0, 0x0330, 0x0310, 0x0370, 0x0350
	];

	static final MULAW_TABLE = [
		0x8284, 0x8684, 0x8A84, 0x8E84, 0x9284, 0x9684, 0x9A84, 0x9E84, 0xA284, 0xA684, 0xAA84, 0xAE84, 0xB284, 0xB684, 0xBA84, 0xBE84,
		0xC184, 0xC384, 0xC584, 0xC784, 0xC984, 0xCB84, 0xCD84, 0xCF84, 0xD184, 0xD384, 0xD584, 0xD784, 0xD984, 0xDB84, 0xDD84, 0xDF84,
		0xE104, 0xE204, 0xE304, 0xE404, 0xE504, 0xE604, 0xE704, 0xE804, 0xE904, 0xEA04, 0xEB04, 0xEC04, 0xED04, 0xEE04, 0xEF04, 0xF004,
		0xF0C4, 0xF144, 0xF1C4, 0xF244, 0xF2C4, 0xF344, 0xF3C4, 0xF444, 0xF4C4, 0xF544, 0xF5C4, 0xF644, 0xF6C4, 0xF744, 0xF7C4, 0xF844,
		0xF8A4, 0xF8E4, 0xF924, 0xF964, 0xF9A4, 0xF9E4, 0xFA24, 0xFA64, 0xFAA4, 0xFAE4, 0xFB24, 0xFB64, 0xFBA4, 0xFBE4, 0xFC24, 0xFC64,
		0xFC94, 0xFCB4, 0xFCD4, 0xFCF4, 0xFD14, 0xFD34, 0xFD54, 0xFD74, 0xFD94, 0xFDB4, 0xFDD4, 0xFDF4, 0xFE14, 0xFE34, 0xFE54, 0xFE74,
		0xFE8C, 0xFE9C, 0xFEAC, 0xFEBC, 0xFECC, 0xFEDC, 0xFEEC, 0xFEFC, 0xFF0C, 0xFF1C, 0xFF2C, 0xFF3C, 0xFF4C, 0xFF5C, 0xFF6C, 0xFF7C,
		0xFF88, 0xFF90, 0xFF98, 0xFFA0, 0xFFA8, 0xFFB0, 0xFFB8, 0xFFC0, 0xFFC8, 0xFFD0, 0xFFD8, 0xFFE0, 0xFFE8, 0xFFF0, 0xFFF8, 0x0000,
		0x7D7C, 0x797C, 0x757C, 0x717C, 0x6D7C, 0x697C, 0x657C, 0x617C, 0x5D7C, 0x597C, 0x557C, 0x517C, 0x4D7C, 0x497C, 0x457C, 0x417C,
		0x3E7C, 0x3C7C, 0x3A7C, 0x387C, 0x367C, 0x347C, 0x327C, 0x307C, 0x2E7C, 0x2C7C, 0x2A7C, 0x287C, 0x267C, 0x247C, 0x227C, 0x207C,
		0x1EFC, 0x1DFC, 0x1CFC, 0x1BFC, 0x1AFC, 0x19FC, 0x18FC, 0x17FC, 0x16FC, 0x15FC, 0x14FC, 0x13FC, 0x12FC, 0x11FC, 0x10FC, 0x0FFC,
		0x0F3C, 0x0EBC, 0x0E3C, 0x0DBC, 0x0D3C, 0x0CBC, 0x0C3C, 0x0BBC, 0x0B3C, 0x0ABC, 0x0A3C, 0x09BC, 0x093C, 0x08BC, 0x083C, 0x07BC,
		0x075C, 0x071C, 0x06DC, 0x069C, 0x065C, 0x061C, 0x05DC, 0x059C, 0x055C, 0x051C, 0x04DC, 0x049C, 0x045C, 0x041C, 0x03DC, 0x039C,
		0x036C, 0x034C, 0x032C, 0x030C, 0x02EC, 0x02CC, 0x02AC, 0x028C, 0x026C, 0x024C, 0x022C, 0x020C, 0x01EC, 0x01CC, 0x01AC, 0x018C,
		0x0174, 0x0164, 0x0154, 0x0144, 0x0134, 0x0124, 0x0114, 0x0104, 0x00F4, 0x00E4, 0x00D4, 0x00C4, 0x00B4, 0x00A4, 0x0094, 0x0084,
		0x0078, 0x0070, 0x0068, 0x0060, 0x0058, 0x0050, 0x0048, 0x0040, 0x0038, 0x0030, 0x0028, 0x0020, 0x0018, 0x0010, 0x0008, 0x0000
	];
}

/* Ported from dr_wav v0.13.16 (raylib 5.5's copy), by David Reid, which is in the public domain or under MIT No Attribution
	(Copyright 2023 David Reid), at its user's choice; no notice is required. */
