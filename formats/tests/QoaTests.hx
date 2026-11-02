import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import helix.formats.qoa.QoaFile;

/** Checks QoaFile with the library alone: made-up files (their LMS state and slices bytes of a fixed LCG, so the predictions overflow
	and the samples clamp) read as raylib 5.5's qoa.h reads them, by their frames and the CRC-32 of their samples (taken from qoa.h
	compiled with gcc on the same files): one channel and one frame, two channels over two frames, three channels with a last slice
	part full, a file cut in its second frame and in its first, a second frame of another rate; and what throws. */
class QoaTests {
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

	// A file of frames frames of channels at rate, from seed; its second frame at wrongRate when that is not 0.
	static function make(seed:Int, channels:Int, rate:Int, frames:Int, wrongRate = 0):Bytes {
		state = seed;
		var b = new BytesBuffer();
		for (c in "qoaf".split(""))
			b.addByte(c.charCodeAt(0));
		for (shift in [24, 16, 8, 0])
			b.addByte((frames >> shift) & 0xFF);
		var done = 0, f = 0;
		while (done < frames) {
			var n = frames - done > 5120 ? 5120 : frames - done,
				slices = Std.int((n + 19) / 20);
			var size = 8 + 16 * channels + 8 * slices * channels,
				r = f == 1 && wrongRate != 0 ? wrongRate : rate;
			for (v in [channels, r >> 16, r >> 8, r, n >> 8, n, size >> 8, size])
				b.addByte(v & 0xFF);
			for (_ in 0...16 * channels + 8 * slices * channels)
				b.addByte(next());
			done += n;
			f++;
		}
		return b.getBytes();
	}

	static function thrown(call:Void->Void):Bool {
		try
			call()
		catch (e:String)
			return true;
		return false;
	}

	// The file reads as qoa.h reads it: its frames, rate and channels, and its samples by their CRC-32.
	static function same(what:String, file:Bytes, frames:Int, rate:Int, channels:Int, crc32:Int):Void {
		var qoa = QoaFile.read(file);
		check(qoa.frameCount == frames && qoa.sampleRate == rate && qoa.channelCount == channels,
			'$what: ${qoa.frameCount} frames at ${qoa.sampleRate} Hz in ${qoa.channelCount} channels, not $frames at $rate in $channels');
		check(qoa.samples.length == frames * channels * 2, '$what: ${qoa.samples.length} bytes of samples');
		check(haxe.crypto.Crc32.make(qoa.samples) == crc32, '$what: its samples aren\'t qoa.h\'s, CRC 0x${StringTools.hex(crc32, 8)}');
	}

	static function main():Void {
		same("one channel, one frame", make(1, 1, 8000, 100), 100, 8000, 1, 0xA3A06D2B);
		var stereo = make(2, 2, 44100, 5420);
		same("two channels, two frames", stereo, 5420, 44100, 2, 0x2AEA1849);
		same("cut in its second frame", stereo.sub(0, stereo.length - 100), 5120, 44100, 2, 0xEE75B43D);
		same("cut in its first frame", stereo.sub(0, stereo.length - 1000), 0, 44100, 2, 0x00000000);
		same("three channels, a last slice part full", make(3, 3, 22050, 61), 61, 22050, 3, 0x034A1BAE);
		same("a second frame of another rate", make(4, 2, 44100, 5420, 48000), 5120, 44100, 2, 0xA848C496);

		check(thrown(() -> QoaFile.read(Bytes.alloc(15))), "a file under 16 bytes throws");
		var wrong = stereo.sub(0, 64);
		wrong.set(0, "Q".code);
		check(thrown(() -> QoaFile.read(wrong)), "a wrong magic throws");
		var streamed = stereo.sub(0, 64);
		for (i in 4...8)
			streamed.set(i, 0);
		check(thrown(() -> QoaFile.read(streamed)), "a streamed file (no frame count) throws");
		var silent = stereo.sub(0, 64);
		silent.set(8, 0);
		check(thrown(() -> QoaFile.read(silent)), "a first frame of no channels throws");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
