package helix.ray.internal;

import haxe.io.Bytes;

/** Holds what helix-ray's wave readers do to the platform's decoded samples to give raylib's: Ogg's floats made 16-bit as stb_vorbis
	makes them; an MP3's Xing, Info or VBRI tag hidden, so the decoder reads every frame as raylib 5.5's dr_mp3 does, and its floats
	made dr_mp3's 16-bit steps. */
@:noCompletion
class Waves {
	/** Returns the rate a sound file's header records (helix-formats' `AudioHeader.readSampleRate`, given its first 64 KiB), the rate
		raylib keeps and helix-ray asks the platform's decoder for.

		@param data  The file.
		@return  The frames a second, or 0 when the header can't be read. */
	public static function readSampleRate(data:Bytes):Int
		return helix.formats.audio.AudioHeader.readSampleRate(data.length > 65536 ? data.sub(0, 65536) : data);

	/** Returns floats as 16-bit samples, as stb_vorbis's `stb_vorbis_get_samples_short_interleaved` makes them: each scaled by 32768,
		rounded to the nearest, a half to even (its float addition of 384), and held to -32768 to 32767.

		@param floats  The 32-bit float samples.
		@param count  How many samples to give: those past the floats are silence.
		@return  The 16-bit samples, little-endian. */
	public static function toInt16(floats:Bytes, count:Int):Bytes {
		var out = Bytes.alloc(count * 2), given = Std.int(floats.length / 4);
		for (i in 0...(count < given ? count : given)) {
			var scaled = floats.getFloat(i * 4) * 32768;
			var low = Math.ffloor(scaled), rest = scaled - low;
			var v = rest > 0.5 || (rest == 0.5 && Math.abs(low % 2) == 1) ? low + 1 : low;
			out.setUInt16(i * 2, Std.int(v < -32768 ? -32768 : v > 32767 ? 32767 : v) & 0xFFFF);
		}
		return out;
	}

	/** Returns an MP3 file with its first frame's Xing, Info or VBRI tag hidden (its four letters zeroed), so a decoder that trims the
		LAME delay and padding the tag records, and skips the tag's frame, decodes that frame as silence and keeps every sample, as
		raylib 5.5's dr_mp3 (0.6.39), which reads no tag, does. A file without one is returned as it is.

		@param data  The file.
		@return  The file, or a copy with its tag hidden. */
	public static function hideMp3Tag(data:Bytes):Bytes {
		var p = tagsEnd(data);
		if (p + 4 > data.length || data.get(p) != 0xFF || (data.get(p + 1) & 0xE0) != 0xE0)
			return data;
		var mpeg1 = ((data.get(p + 1) >> 3) & 3) == 3,
			mono = (data.get(p + 3) >> 6) == 3;
		var tag = -1;
		for (at in [p + 4 + (mpeg1 ? (mono ? 17 : 32) : (mono ? 9 : 17)), p + 36])
			if (tag < 0 && at + 4 <= data.length) {
				if (matches(data, at, "Xing") || matches(data, at, "Info") || (at == p + 36 && matches(data, at, "VBRI")))
					tag = at;
			}
		if (tag < 0)
			return data;
		var copy = data.sub(0, data.length);
		copy.fill(tag, 4, 0);
		return copy;
	}

	/** Returns an MP3's decoded floats as raylib 5.5's dr_mp3 (0.6.39) gives them: decoded to 16-bit samples (minimp3's integer output on
		x86-64: each scaled by 32768, held to -32768 to 32767 and rounded to the nearest, a half to even, as its SSE loop converts, but
		every 16th frame, which its scalar synth_pair converts, a half added and truncated toward zero, then a step down below zero), then
		made floats again over 32768. A first frame of silence goes before them when the decoder left out the frame of a hidden tag
		(`hideMp3Tag`), as Chromium does, so the frames are dr_mp3's: one for each frame of the file.

		@param floats  The 32-bit float samples decoded.
		@param channelCount  The channels they hold.
		@param file  The file decoded, its tag hidden or not.
		@param hidden  Whether `hideMp3Tag` hid a tag in it.
		@return  The samples, 32-bit floats. */
	public static function toMp3Floats(floats:Bytes, channelCount:Int, file:Bytes, hidden:Bool):Bytes {
		var given = Std.int(floats.length / 4), lead = 0;
		if (hidden) {
			var frames = mp3Frames(file);
			if (frames.count > 0 && Std.int(given / channelCount) == (frames.count - 1) * frames.samples)
				lead = frames.samples * channelCount;
		}
		var out = Bytes.alloc((lead + given) * 4);
		for (i in 0...given) {
			var scaled = floats.getFloat(i * 4) * 32768, v:Float;
			if (Std.int((lead + i) / channelCount) % 16 == 0) {
				// minimp3's synth_pair: drmp3d_scale_pcm, truncating toward zero after adding a half, then a step down when below zero.
				v = scaled >= 32766.5 ? 32767 : scaled <= -32767.5 ? -32768 : (scaled + 0.5 < 0 ? Math.fceil(scaled + 0.5) : Math.ffloor(scaled + 0.5));
				if (v < 0)
					v--;
			} else {
				// The SSE loop: held to -32768 to 32767, then rounded to the nearest, a half to even (_mm_cvtps_epi32).
				var held = scaled < -32768 ? -32768 : scaled > 32767 ? 32767 : scaled;
				var low = Math.ffloor(held), rest = held - low;
				v = rest > 0.5 || (rest == 0.5 && Math.abs(low % 2) == 1) ? low + 1 : low;
			}
			out.setFloat((lead + i) * 4, v / 32768);
		}
		return out;
	}

	// The MPEG audio frames of a file after its ID3v2 tags, walked by their lengths from the first, and the samples each decodes to.
	static function mp3Frames(data:Bytes):{count:Int, samples:Int} {
		var p = tagsEnd(data), count = 0, samples = 0;
		while (p + 4 <= data.length) {
			var b1 = data.get(p + 1), b2 = data.get(p + 2);
			var version = (b1 >> 3) & 3,
				layer = (b1 >> 1) & 3,
				index = b2 >> 4,
				rateIndex = (b2 >> 2) & 3;
			if (data.get(p) != 0xFF || (b1 & 0xE0) != 0xE0 || version == 1 || layer == 0 || index == 0 || index == 15 || rateIndex == 3)
				break;
			var mpeg1 = version == 3;
			var rate = [44100, 48000, 32000][rateIndex] >> (mpeg1 ? 0 : version == 2 ? 1 : 2);
			var table = mpeg1 ? (layer == 3 ? 0 : layer == 2 ? 1 : 2) : (layer == 3 ? 3 : 4);
			var bits = BITRATES[table * 15 + index] * 1000,
				padding = (b2 >> 1) & 1;
			samples = layer == 3 ? 384 : layer == 1 && !mpeg1 ? 576 : 1152;
			p += layer == 3 ? (Std.int(12 * bits / rate) + padding) * 4 : Std.int(samples / 8 * bits / rate) + padding;
			count++;
		}
		return {count: count, samples: samples};
	}

	// Where a file's ID3v2 tags end: 0 when it has none.
	static function tagsEnd(data:Bytes):Int {
		var p = 0;
		while (p + 10 <= data.length && matches(data, p, "ID3"))
			p += 10
				+ ((data.get(p + 6) << 21) | (data.get(p + 7) << 14) | (data.get(p + 8) << 7) | data.get(p + 9))
				+ ((data.get(p + 5) & 0x10) != 0 ? 10 : 0);
		return p;
	}

	// MPEG-1 layers I, II and III, then MPEG-2 and 2.5 layer I, then layers II and III: each bitrate index's kilobits a second.
	static final BITRATES = [
		0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448,
		0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384,
		0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320,
		0, 32, 48, 56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256,
		0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160
	];

	// Whether the bytes at p are the ASCII text given.
	static function matches(bytes:Bytes, p:Int, text:String):Bool {
		if (p + text.length > bytes.length)
			return false;
		for (i in 0...text.length)
			if (bytes.get(p + i) != StringTools.fastCodeAt(text, i))
				return false;
		return true;
	}
}
