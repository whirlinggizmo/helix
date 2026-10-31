package helix.formats.audio;

import haxe.io.Bytes;

/** Provides reading a sound file's length in seconds from its first bytes, and for some kinds its last, without decoding it.

	It reads WAV, Ogg (Vorbis, Opus, FLAC and Speex), FLAC and MP3 (MPEG audio layers I to III). Given the whole file, it reads the
	start alone; given part of it, the first 64 KiB is enough for all but an MP3 whose tags are larger, and Ogg needs the last bytes too,
	where the last page is.

	```haxe
	var seconds = AudioLength.read(first64k, last64k, fileSize);
	``` */
class AudioLength {
	/** Returns a sound file's length in seconds.

		WAV: the data chunk's frames over the rate; for a compressed encoding, the `fact` chunk's frames, or the data's size over its
		bytes a second. A data chunk whose size is 0 or 0xFFFFFFFF, as a streamed file leaves it, runs to the file's end. Ogg: the last
		page's position over the rate, less Opus's pre-skip; the first stream's pages alone are read, each checked by its CRC. FLAC:
		STREAMINFO's frames over its rate; 0 when it doesn't record them. MP3: ID3v2 tags are skipped; the frames a Xing, Info or VBRI
		header records; otherwise an estimate, the bytes after the tags (and before an ID3v1 tag, when `end` is provided) over the first
		frame's bitrate, exact for a file of one bitrate and off for one whose bitrate varies.

		@param start  The file's first bytes, as many as there are or as are read; 64 KiB is enough for most files.
		@param end  Optional. The file's last bytes, up to 64 KiB; Ogg needs them, MP3 reads an ID3v1 tag from them. When omitted and
			`start` is the whole file, `start` is read for both.
		@param size  The file's size, in bytes.
		@return  The length, in seconds, or 0 when it can't tell: an unknown kind, too few bytes, or a file that doesn't record it. */
	public static function read(start:Bytes, ?end:Bytes, size:Int):Float {
		if (end == null && size <= start.length)
			end = start;
		if (start.length >= 12 && matches(start, 0, "RIFF") && matches(start, 8, "WAVE"))
			return wav(start, size);
		if (start.length >= 4 && matches(start, 0, "OggS"))
			return ogg(start, end);
		var p = 0;
		var tagged = false;
		while (p + 10 <= start.length && matches(start, p, "ID3")) {
			var tagSize = (start.get(p + 6) << 21) | (start.get(p + 7) << 14) | (start.get(p + 8) << 7) | start.get(p + 9);
			p += 10 + tagSize + ((start.get(p + 5) & 0x10) != 0 ? 10 : 0);
			tagged = true;
		}
		if (p + 4 <= start.length && matches(start, p, "fLaC"))
			return flac(start, p);
		return mp3(start, p, tagged, end, size);
	}

	static function wav(start:Bytes, size:Int):Float {
		var tag = -1, channels = 0, rate = 0, byteRate = 0, blockAlign = 0, bits = 0;
		var factFrames = 0.0;
		var p = 12;
		while (p + 8 <= start.length) {
			var chunkSize = unsigned(start.getInt32(p + 4));
			var body = p + 8;
			if (matches(start, p, "fmt ") && body + 16 <= start.length) {
				tag = start.getUInt16(body);
				channels = start.getUInt16(body + 2);
				rate = start.getInt32(body + 4);
				byteRate = start.getInt32(body + 8);
				blockAlign = start.getUInt16(body + 12);
				bits = start.getUInt16(body + 14);
				if (tag == 0xFFFE && chunkSize >= 40 && body + 26 <= start.length)
					tag = start.getUInt16(body + 24);
			} else if (matches(start, p, "fact") && body + 4 <= start.length)
				factFrames = unsigned(start.getInt32(body));
			else if (matches(start, p, "data")) {
				if (tag < 0 || rate <= 0)
					return 0;
				var available = size - body;
				var dataSize = chunkSize == 0 || chunkSize == 4294967295.0 || chunkSize > available ? available : chunkSize;
				if (tag == 1 || tag == 3 || tag == 6 || tag == 7) {
					var bytesPerFrame = (bits & 7) == 0 ? (bits * channels) >> 3 : blockAlign;
					return bytesPerFrame > 0 ? Math.ffloor(dataSize / bytesPerFrame) / rate : 0;
				}
				if (factFrames > 0)
					return factFrames / rate;
				return byteRate > 0 ? dataSize / unsigned(byteRate) : 0;
			}
			p = Std.int(body + chunkSize + (chunkSize % 2));
			if (body + chunkSize > start.length)
				break;
		}
		return 0;
	}

	static function ogg(start:Bytes, end:Null<Bytes>):Float {
		if (end == null || start.length < 28 || start.get(4) != 0)
			return 0;
		var segments = start.get(26);
		var packet = 27 + segments;
		if (packet + 8 > start.length)
			return 0;
		var serial = start.getInt32(14);
		var rate = 0, skip = 0;
		if (start.get(packet) == 1 && matches(start, packet + 1, "vorbis") && packet + 16 <= start.length)
			rate = start.getInt32(packet + 12);
		else if (matches(start, packet, "OpusHead") && packet + 12 <= start.length) {
			rate = 48000;
			skip = start.getUInt16(packet + 10);
		} else if (start.get(packet) == 0x7F && matches(start, packet + 1, "FLAC") && packet + 30 <= start.length)
			rate = (start.get(packet + 27) << 12) | (start.get(packet + 28) << 4) | (start.get(packet + 29) >> 4);
		else if (matches(start, packet, "Speex   ") && packet + 40 <= start.length)
			rate = start.getInt32(packet + 36);
		if (rate <= 0)
			return 0;
		var p = end.length - 27;
		while (p >= 0) {
			if (end.get(p) == "O".code && matches(end, p, "OggS") && end.get(p + 4) == 0 && end.getInt32(p + 14) == serial) {
				var length = page(end, p);
				var low = end.getInt32(p + 6), high = end.getInt32(p + 10);
				if (length > 0 && !(low == -1 && high == -1)) {
					var granule = high * 4294967296.0 + unsigned(low);
					return Math.max(0, granule - skip) / rate;
				}
			}
			p--;
		}
		return 0;
	}

	// The length of the Ogg page at p when it is whole and its CRC is right; 0 otherwise.
	static function page(bytes:Bytes, p:Int):Int {
		var segments = bytes.get(p + 26);
		if (p + 27 + segments > bytes.length)
			return 0;
		var length = 27 + segments;
		for (i in 0...segments)
			length += bytes.get(p + 27 + i);
		if (p + length > bytes.length)
			return 0;
		if (OGG_CRC == null) {
			OGG_CRC = [];
			for (i in 0...256) {
				var r = i << 24;
				for (_ in 0...8)
					r = (r & 0x80000000) != 0 ? (r << 1) ^ 0x04C11DB7 : r << 1;
				OGG_CRC.push(r);
			}
		}
		var crc = 0;
		for (i in 0...length) {
			var b = i >= 22 && i < 26 ? 0 : bytes.get(p + i);
			crc = (crc << 8) ^ OGG_CRC[((crc >>> 24) ^ b) & 0xFF];
		}
		return crc == bytes.getInt32(p + 22) ? length : 0;
	}

	static var OGG_CRC:Array<Int>;

	static function flac(start:Bytes, p:Int):Float {
		var info = p + 8;
		if (info + 18 > start.length || (start.get(p + 4) & 0x7F) != 0)
			return 0;
		var rate = (start.get(info + 10) << 12) | (start.get(info + 11) << 4) | (start.get(info + 12) >> 4);
		var frames = (start.get(info + 13) & 0x0F) * 4294967296.0 + unsigned(bigEndian32(start, info + 14));
		return rate > 0 ? frames / rate : 0;
	}

	static function mp3(start:Bytes, p:Int, tagged:Bool, end:Null<Bytes>, size:Int):Float {
		// The first frame: at the start or right after the tags, or for a tagged file the first after them that the next follows.
		var frame = -1;
		var last = tagged ? start.length - 4 : p;
		var i = p;
		while (i <= last && i + 4 <= start.length) {
			var length = frameLength(start, i);
			if (length > 0 && (i + length + 4 > start.length || frameLength(start, i + length) > 0)) {
				frame = i;
				break;
			}
			i++;
		}
		if (frame < 0)
			return 0;
		var b1 = start.get(frame + 1),
			b2 = start.get(frame + 2),
			b3 = start.get(frame + 3);
		var version = (b1 >> 3) & 3, layer = (b1 >> 1) & 3;
		var mpeg1 = version == 3;
		var rate = SAMPLE_RATES[b2 >> 2 & 3] >> (mpeg1 ? 0 : version == 2 ? 1 : 2);
		var samplesPerFrame = layer == 3 ? 384 : (layer == 1 && !mpeg1 ? 576 : 1152);
		var mono = b3 >> 6 == 3;
		if (layer == 1) {
			var xing = frame + 4 + (mpeg1 ? (mono ? 17 : 32) : (mono ? 9 : 17));
			if (xing + 12 <= start.length) {
				if ((matches(start, xing, "Xing") || matches(start, xing, "Info")) && (bigEndian32(start, xing + 4) & 1) != 0)
					return unsigned(bigEndian32(start, xing + 8)) * samplesPerFrame / rate;
			}
		}
		var vbri = frame + 36;
		if (vbri + 18 <= start.length && matches(start, vbri, "VBRI"))
			return unsigned(bigEndian32(start, vbri + 14)) * samplesPerFrame / rate;
		var audio = size - frame;
		if (end != null && end.length >= 128 && matches(end, end.length - 128, "TAG"))
			audio -= 128;
		return audio * 8 / (bitrate(b1, b2) * 1000);
	}

	// The length in bytes of the MPEG audio frame whose header is at p, or 0 when there is no valid header there.
	static function frameLength(bytes:Bytes, p:Int):Int {
		if (p + 4 > bytes.length || bytes.get(p) != 0xFF)
			return 0;
		var b1 = bytes.get(p + 1), b2 = bytes.get(p + 2);
		var version = (b1 >> 3) & 3, layer = (b1 >> 1) & 3;
		if ((b1 & 0xE0) != 0xE0 || version == 1 || layer == 0 || b2 >> 4 == 0 || b2 >> 4 == 15 || (b2 >> 2 & 3) == 3)
			return 0;
		var mpeg1 = version == 3;
		var rate = SAMPLE_RATES[b2 >> 2 & 3] >> (mpeg1 ? 0 : version == 2 ? 1 : 2);
		var padding = (b2 >> 1) & 1;
		var bits = bitrate(b1, b2) * 1000;
		if (layer == 3)
			return (Std.int(12 * bits / rate) + padding) * 4;
		var samplesPerFrame = layer == 1 && !mpeg1 ? 576 : 1152;
		return Std.int(samplesPerFrame / 8 * bits / rate) + padding;
	}

	// The frame's bitrate in kilobits a second, from its header's second and third bytes.
	static function bitrate(b1:Int, b2:Int):Int {
		var mpeg1 = (b1 >> 3 & 3) == 3, layer = (b1 >> 1) & 3;
		var table = mpeg1 ? (layer == 3 ? 0 : layer == 2 ? 1 : 2) : (layer == 3 ? 3 : 4);
		return BITRATES[table * 15 + (b2 >> 4)];
	}

	// MPEG-1 layers I, II and III, then MPEG-2 and 2.5 layer I, then layers II and III: each bitrate index's kilobits a second.
	static final BITRATES = [
		0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448,
		0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384,
		0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320,
		0, 32, 48, 56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256,
		0,  8, 16, 24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160
	];

	// MPEG-1's rates; MPEG-2 halves them, MPEG-2.5 quarters them.
	static final SAMPLE_RATES = [44100, 48000, 32000];

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

	static inline function bigEndian32(bytes:Bytes, p:Int):Int
		return (bytes.get(p) << 24) | (bytes.get(p + 1) << 16) | (bytes.get(p + 2) << 8) | bytes.get(p + 3);
}
