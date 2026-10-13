package helix.audio;

import haxe.io.Bytes;

class Pcm {
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
