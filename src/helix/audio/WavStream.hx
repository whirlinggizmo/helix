package helix.audio;

/** Canonical 44-byte mono PCM16/44100 WAV header. Payload is decoded in bounded chunks. */
class WavStream {
	/** Checks the 44 header bytes of a canonical WAV file of size bytes and returns its PCM16 data length in bytes. Throws for any other layout. */
	public static function header(bytes:haxe.io.Bytes, size:Int):Int {
		if (bytes.length != 44 || size < 46 || bytes.getString(0, 4) != "RIFF" || bytes.getInt32(4) != size - 8 || bytes.getString(8, 4) != "WAVE"
			|| bytes.getString(12, 4) != "fmt " || bytes.getInt32(16) != 16 || bytes.getUInt16(20) != 1 || bytes.getUInt16(22) != 1
			|| bytes.getInt32(24) != 44100 || bytes.getInt32(28) != 88200 || bytes.getUInt16(32) != 2 || bytes.getUInt16(34) != 16
			|| bytes.getString(36, 4) != "data" || bytes.getInt32(40) != size - 44 || (size - 44) % 2 != 0)
			throw "Native stream requires canonical mono PCM16/44100 WAV";
		return size - 44;
	}

	/** Converts a chunk of PCM16 bytes to mono 32-bit float PCM, -1 to 1. Throws for an odd byte count. */
	public static function decode(bytes:haxe.io.Bytes):haxe.io.Bytes {
		if (bytes.length % 2 != 0)
			throw "Truncated PCM frame";
		var out = haxe.io.Bytes.alloc(bytes.length * 2);
		for (i in 0...Std.int(bytes.length / 2)) {
			var value = bytes.getUInt16(i * 2);
			if (value >= 32768)
				value -= 65536;
			out.setFloat(i * 4, value / 32768.);
		}
		return out;
	}
}
