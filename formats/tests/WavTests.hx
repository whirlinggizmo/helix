import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import helix.formats.wav.WavEncoding;
import helix.formats.wav.WavFile;

/** Checks WavFile with the library alone: files written byte for byte as raylib 5.5's ExportWave writes them (each file's length and
	CRC-32, from dr_wav compiled with gcc, on the same made-up samples), for 8, 16 and 32-bit (floating-point) waves of 1 and 2
	channels; made-up files read as dr_wav reads them (the frames, and the CRC-32 of the samples as 16-bit integers and as 32-bit floats,
	from dr_wav's drwav_read_pcm_frames_s16 and _f32), for integers of 8 to 64 bits, 32 and 64-bit floating point, A-law and mu-law, of 1
	to 3 channels, plain and extensible, with chunks to skip before and after the samples, padding, and data sizes of 0, 0xFFFFFFFF and
	past the file's end; a few samples by value; and what throws. */
class WavTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static var state = 0;

	// The next byte of a fixed LCG, the C side's.
	static function next():Int {
		var s:haxe.Int32 = state;
		s = s * 1664525 + 1013904223;
		state = s;
		return state >>> 24;
	}

	static function next16():Int {
		var high = next();
		var low = next();
		return (((high << 8) | low) << 16) >> 16;
	}

	// A made-up WAV file, as the C side made it. Flags: 1 extensible; 2 chunks before the data (an odd LIST, a fact, an odd junk); 4
	// a data size of 0xFFFFFFFF; 8 a data size of 0; 16 a data size past the file's end; 32 a chunk after the data.
	static function make(tag:Int, bits:Int, channels:Int, rate:Int, frames:Int, flags:Int):Bytes {
		var bytesPerSample = (bits + 7) >> 3;
		var blockAlign = channels * bytesPerSample;
		var dataSize = frames * blockAlign;
		state = tag * 131 + bits * 17 + channels * 7 + frames + flags * 1009 + rate;
		var b = new BytesBuffer();
		function u16(v:Int) {
			b.addByte(v & 0xFF);
			b.addByte((v >> 8) & 0xFF);
		}
		b.addString("RIFF");
		b.addInt32(0);
		b.addString("WAVE");
		if (flags & 2 != 0) {
			b.addString("LIST");
			b.addInt32(5);
			b.addString("abcde");
			b.addByte(0);
		}
		b.addString("fmt ");
		b.addInt32(flags & 1 != 0 ? 40 : 16);
		u16(flags & 1 != 0 ? 0xFFFE : tag);
		u16(channels);
		b.addInt32(rate);
		b.addInt32(rate * blockAlign);
		u16(blockAlign);
		u16(bits);
		if (flags & 1 != 0) {
			u16(22);
			u16(bits);
			b.addInt32(channels == 2 ? 3 : 4);
			u16(tag);
			for (v in [
				0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71
			])
				b.addByte(v);
		}
		if (flags & 2 != 0) {
			b.addString("fact");
			b.addInt32(4);
			b.addInt32(frames * 3);
			b.addString("junk");
			b.addInt32(3);
			b.addString("xyz");
			b.addByte(0);
		}
		b.addString("data");
		b.addInt32(flags & 4 != 0 ? -1 : flags & 8 != 0 ? 0 : flags & 16 != 0 ? dataSize + 1000 : dataSize);
		for (i in 0...frames * channels) {
			if (tag == 3 && bytesPerSample == 4)
				b.addFloat(next16() / 16384.0);
			else if (tag == 3 && bytesPerSample == 8)
				b.addDouble(next16() / 16384.0);
			else
				for (j in 0...bytesPerSample)
					b.addByte(next());
		}
		if (flags & 32 != 0) {
			if (dataSize & 1 != 0)
				b.addByte(0);
			b.addString("LIST");
			b.addInt32(4);
			b.addString("efgh");
		}
		var bytes = b.getBytes();
		bytes.setInt32(4, bytes.length - 8);
		return bytes;
	}

	static function thrown(call:Void->Void):Bool {
		try
			call()
		catch (e:String)
			return true;
		return false;
	}

	// A made-up file reads as dr_wav reads it: its frames, and its samples as 16-bit integers and 32-bit floats, by CRC-32. A data
	// size of 0 is compared with dr_wav reading the file with its size filled in, and one past the end with the frames dr_wav reads.
	static function same(tag:Int, bits:Int, channels:Int, frames:Int, flags:Int, read:Int, int16:Int, float32:Int):Void {
		var what = 'format $tag, $bits bits, $channels channels, $frames frames, flags $flags';
		var rate = channels == 3 ? 8000 : 44100;
		var wav = WavFile.read(make(tag, bits, channels, rate, frames, flags));
		check(wav.frameCount == read && wav.channelCount == channels && wav.sampleRate == rate, '$what: $read frames, its channels and rate');
		check(wav.sampleSize == ((bits + 7) >> 3) * 8
			&& wav.samples.length == read * channels * (wav.sampleSize >> 3), '$what: its sample size and samples');
		check(haxe.crypto.Crc32.make(wav.toInt16()) == int16, '$what: as 16-bit integers, dr_wav\'s CRC 0x${StringTools.hex(int16, 8)}');
		check(haxe.crypto.Crc32.make(wav.toFloat32()) == float32, '$what: as 32-bit floats, dr_wav\'s CRC 0x${StringTools.hex(float32, 8)}');
	}

	// A wave is written as raylib's ExportWave writes it, by its length and CRC-32, and reads back to itself.
	static function written(size:Int, channels:Int, frames:Int, rate:Int, length:Int, crc32:Int):Void {
		var what = '$size bits, $channels channels, $frames frames at $rate';
		state = size * 31 + channels * 7 + frames + rate;
		var samples = Bytes.alloc(frames * channels * (size >> 3));
		for (i in 0...frames * channels) {
			if (size == 32)
				samples.setFloat(i * 4, next16() / 16384.0);
			else
				for (j in 0...size >> 3)
					samples.set(i * (size >> 3) + j, next());
		}
		var file = WavFile.write(rate, channels, size, frames, samples);
		check(file.length == length && haxe.crypto.Crc32.make(file) == crc32, '$what: ExportWave\'s $length bytes, CRC 0x${StringTools.hex(crc32, 8)}');
		var wav = WavFile.read(file);
		check(wav.sampleRate == rate
			&& wav.channelCount == channels
			&& wav.sampleSize == size
			&& wav.frameCount == frames
			&& wav.encoding == (size == 32 ? FloatingPoint : Pcm),
			'$what: its header read back');
		check(wav.samples.compare(samples) == 0, '$what: its samples read back');
	}

	// A mono file of the given bytes, its format and sample size set.
	static function mono(tag:Int, data:Array<Int>):WavFile {
		var samples = Bytes.alloc(data.length);
		for (i in 0...data.length)
			samples.set(i, data[i]);
		var file = WavFile.write(8000, 1, 8, data.length, samples);
		file.setUInt16(20, tag);
		return WavFile.read(file);
	}

	static function int16s(bytes:Bytes):Array<Int>
		return [for (i in 0...bytes.length >> 1) (bytes.getUInt16(i * 2) << 16) >> 16];

	static function main():Void {
		same(1, 8, 1, 37, 0, 37, 0xfd3b6eab, 0x2574f70d);
		same(1, 8, 2, 37, 1, 37, 0x24984aaf, 0x00d0dd79);
		same(1, 8, 3, 1500, 34, 1500, 0x12ca0f6f, 0x9f8eb38d);
		same(1, 8, 2, 1, 4, 1, 0xe9a80d04, 0x4ffed78e);
		same(1, 16, 1, 37, 0, 37, 0x037cb2ca, 0x38411a0f);
		same(1, 16, 2, 37, 1, 37, 0x64a5a5e5, 0xedf2fc1a);
		same(1, 16, 3, 1500, 34, 1500, 0xbed76e2c, 0xb3d950c8);
		same(1, 16, 2, 1, 4, 1, 0x8dcc1b48, 0xd706a3d0);
		same(1, 24, 1, 37, 0, 37, 0x81af9652, 0xde965e8a);
		same(1, 24, 2, 37, 1, 37, 0x9fc0695c, 0x79461fff);
		same(1, 24, 3, 1500, 34, 1500, 0xfd26d67c, 0x49cb131d);
		same(1, 24, 2, 1, 4, 1, 0x2820a217, 0xdac231b5);
		same(1, 32, 1, 37, 0, 37, 0x13fa558d, 0xeca7baa7);
		same(1, 32, 2, 37, 1, 37, 0x54909dd4, 0x367d7926);
		same(1, 32, 3, 1500, 34, 1500, 0x607175e9, 0xee75dd85);
		same(1, 32, 2, 1, 4, 1, 0x5ac45393, 0x7e724ecf);
		same(1, 12, 1, 37, 0, 37, 0x4ec45b9a, 0xd9650655);
		same(1, 12, 2, 37, 2, 37, 0x388eca06, 0xa02948a0);
		same(1, 12, 3, 1500, 34, 1500, 0xc04bedf3, 0xd2b450f0);
		same(1, 12, 2, 1, 4, 1, 0x105f5109, 0xff08cb0b);
		same(1, 20, 1, 37, 0, 37, 0xbd2aeea5, 0x3a082e3b);
		same(1, 20, 2, 37, 1, 37, 0x167e1374, 0xc3fce6ee);
		same(1, 20, 3, 1500, 34, 1500, 0x11c54180, 0xc6f96cc9);
		same(1, 20, 2, 1, 4, 1, 0x78bf49e1, 0x0ce506e7);
		same(1, 40, 1, 37, 0, 37, 0x413bda93, 0xf468b377);
		same(1, 40, 2, 37, 1, 37, 0x7a7178ba, 0xf087a940);
		same(1, 40, 3, 1500, 34, 1500, 0xb23e9b72, 0xe85d436b);
		same(1, 40, 2, 1, 4, 1, 0xb623a2f7, 0x5c865b84);
		same(1, 64, 1, 37, 0, 37, 0xa2c4e432, 0x9e2fb72b);
		same(1, 64, 2, 37, 1, 37, 0xb960b896, 0x56d0fe3f);
		same(1, 64, 3, 1500, 34, 1500, 0xfc2650bd, 0x749604f1);
		same(1, 64, 2, 1, 4, 1, 0x7f159de6, 0x98516c54);
		same(3, 32, 1, 37, 0, 37, 0x8ebb5e7d, 0x0ab7f691);
		same(3, 32, 2, 37, 1, 37, 0x428b852a, 0xb1d184ea);
		same(3, 32, 3, 1500, 34, 1500, 0x923a2af4, 0x0eb2de7d);
		same(3, 32, 2, 1, 4, 1, 0xd9f94204, 0x16ebc939);
		same(3, 64, 1, 37, 0, 37, 0x9bba3afb, 0x16960801);
		same(3, 64, 2, 37, 1, 37, 0x0f931d40, 0x9f488051);
		same(3, 64, 3, 1500, 34, 1500, 0x87e2ddc3, 0x69f19e53);
		same(3, 64, 2, 1, 4, 1, 0xf372675f, 0x6387803a);
		same(6, 8, 1, 37, 0, 37, 0x619e78d5, 0xa4e535a9);
		same(6, 8, 2, 37, 1, 37, 0xe28425cd, 0xbe95761c);
		same(6, 8, 3, 1500, 34, 1500, 0x7757ee4c, 0x6ec43569);
		same(6, 8, 2, 1, 4, 1, 0x8e34d813, 0xea0bcb92);
		same(7, 8, 1, 37, 0, 37, 0xf45be626, 0x40a6a9ec);
		same(7, 8, 2, 37, 1, 37, 0xa8aceba7, 0xea25255a);
		same(7, 8, 3, 1500, 34, 1500, 0x2e0071ba, 0x2f895493);
		same(7, 8, 2, 1, 4, 1, 0xbcc05e94, 0xffea51a2);
		same(1, 8, 1, 37, 8, 37, 0x6eddc8bb, 0x77e4e05c);
		same(3, 32, 2, 37, 8, 37, 0x8bb4c48a, 0x996ba1a9);
		same(1, 16, 2, 37, 16, 37, 0xec23c099, 0x78233a4c);
		same(1, 24, 1, 1500, 16, 1500, 0xa643b916, 0xdbecc1df);
		same(1, 8, 1, 37, 32, 37, 0x81ba314d, 0x86fa372c);
		same(1, 16, 3, 37, 33, 37, 0x82526e44, 0x883dc91c);
		same(1, 8, 2, 1500, 3, 1500, 0x264e7b53, 0xad002510);

		written(8, 1, 0, 22050, 44, 0x424b3477);
		written(8, 1, 3, 44100, 48, 0xcfd9fbe2);
		written(8, 1, 37, 22050, 82, 0x3261c3fb);
		written(8, 1, 1000, 44100, 1044, 0x36d21a00);
		written(8, 2, 0, 22050, 44, 0x49a9f8a5);
		written(8, 2, 3, 44100, 50, 0xe8205b6e);
		written(8, 2, 37, 22050, 118, 0x3412482e);
		written(8, 2, 1000, 44100, 2044, 0x89413633);
		written(16, 1, 0, 22050, 44, 0x44a894f9);
		written(16, 1, 3, 44100, 50, 0xf245ac75);
		written(16, 1, 37, 22050, 118, 0x4bffbf71);
		written(16, 1, 1000, 44100, 2044, 0xfdef860a);
		written(16, 2, 0, 22050, 44, 0x18e4fa9d);
		written(16, 2, 3, 44100, 56, 0x54825f1a);
		written(16, 2, 37, 22050, 192, 0x53069741);
		written(16, 2, 1000, 44100, 4044, 0x90ea8078);
		written(32, 1, 0, 22050, 44, 0x905419ea);
		written(32, 1, 3, 44100, 56, 0x9f5feda7);
		written(32, 1, 37, 22050, 192, 0x5896584a);
		written(32, 1, 1000, 44100, 4044, 0x36c66db3);
		written(32, 2, 0, 22050, 44, 0x634532e2);
		written(32, 2, 3, 44100, 68, 0xf3f66644);
		written(32, 2, 37, 22050, 340, 0x99d360f5);
		written(32, 2, 1000, 44100, 8044, 0xb5b7b7ff);

		// Samples by value: 8 bits centered on 128; floating point clamped, 0 a step below the middle as dr_wav scales it.
		check(int16s(mono(1, [0, 128, 255]).toInt16()).join(",") == "-32768,0,32512", "8-bit samples as 16-bit integers");
		var floats = Bytes.alloc(20);
		for (i => v in [-2.0, -1.0, 0.0, 0.5, 1.0])
			floats.setFloat(i * 4, v);
		var file = WavFile.write(8000, 1, 32, 5, floats);
		check(int16s(WavFile.read(file).toInt16()).join(",") == "-32768,-32768,-1,16383,32767", "floating point as 16-bit integers");
		var float32 = WavFile.read(file).toFloat32();
		check(float32.getFloat(0) == -2 && float32.getFloat(12) == 0.5, "floating point as 32-bit floats: unclamped");
		var alaw = mono(6, [0x00, 0xD5, 0x55]);
		check(alaw.encoding == ALaw && int16s(alaw.toInt16()).join(",") == "-5504,8,-8", "A-law");
		var mulaw = mono(7, [0x00, 0xFF, 0x7F]);
		check(mulaw.encoding == MuLaw && int16s(mulaw.toInt16()).join(",") == "-32124,0,0", "mu-law");

		// An odd data chunk is padded, and the RIFF size counts the pad.
		var odd = WavFile.write(8000, 1, 8, 3, Bytes.alloc(3));
		check(odd.length == 48 && odd.getInt32(4) == 40 && odd.getInt32(40) == 3 && odd.get(47) == 0, "an odd data chunk padded");

		var good = make(1, 16, 2, 44100, 4, 0);
		check(thrown(() -> WavFile.read(Bytes.alloc(11))), "a file too short throws");
		var rifx = good.sub(0, good.length);
		rifx.set(3, "X".code);
		check(thrown(() -> WavFile.read(rifx)), "RIFX throws");
		check(thrown(() -> WavFile.read(good.sub(0, 36))), "no data chunk throws");
		var adpcm = good.sub(0, good.length);
		adpcm.setUInt16(20, 2);
		check(thrown(() -> WavFile.read(adpcm)), "MS ADPCM throws");
		var noRate = good.sub(0, good.length);
		noRate.setInt32(24, 0);
		check(thrown(() -> WavFile.read(noRate)), "a rate of 0 throws");
		var half = good.sub(0, good.length);
		half.setUInt16(20, 3);
		check(thrown(() -> WavFile.read(half)), "16-bit floating point throws");
		check(thrown(() -> WavFile.write(8000, 1, 12, 1, Bytes.alloc(2))), "writing 12-bit samples throws");
		check(thrown(() -> WavFile.write(0, 1, 16, 1, Bytes.alloc(2))), "writing a rate of 0 throws");
		check(thrown(() -> WavFile.write(8000, 2, 16, 2, Bytes.alloc(7))), "writing fewer samples than given throws");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
