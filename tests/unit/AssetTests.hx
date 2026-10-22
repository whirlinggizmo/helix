import helix.asset.AssetPath;
import helix.audio.Wav;

/** WAV decoding and asset paths. Reads tests/fixtures/tone.wav (tools/gen_fixtures.py). */
@:access(helix)
class AssetTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function rejects(action:Void->Void, message:String):Void {
		var rejected = false;
		try {
			action();
		} catch (error:Dynamic) {
			rejected = true;
		}
		check(rejected, message);
	}

	static function main():Void {
		var wav = sys.io.File.getBytes("tests/fixtures/tone.wav"),
			pcm = Wav.decode(wav);
		check(pcm.length == (wav.length - 44) * 2, "WAV decoding produces float32 PCM");
		var invalid = wav.sub(0, wav.length);
		invalid.setInt32(24, 22050);
		rejects(() -> Wav.decode(invalid), "Unsupported rate rejected");
		rejects(() -> Wav.decode(wav.sub(0, wav.length - 1)), "Truncated WAV rejected");
		check(AssetPath.isValid("sounds/fire.wav")
			&& !AssetPath.isValid("../secret")
			&& !AssetPath.isValid("/tmp/file")
			&& !AssetPath.isValid("https://host/file"),
			"Assets use bounded packaged paths");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
