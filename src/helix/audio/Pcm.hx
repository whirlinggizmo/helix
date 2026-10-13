package helix.audio;

import haxe.io.Bytes;

/** The PCM format of clips: mono 32-bit float samples. */
class Pcm {
	/** Throws unless samples is non-empty, a whole number of 4-byte floats, and every sample is finite and -1 to 1. */
	public static function validate(samples:Bytes):Void {
		if (samples.length == 0 || samples.length % 4 != 0)
			throw "Invalid PCM";
		for (i in 0...Std.int(samples.length / 4)) {
			var value = samples.getFloat(i * 4);
			if (!Math.isFinite(value) || value < -1 || value > 1)
				throw "Invalid PCM sample";
		}
	}
}
