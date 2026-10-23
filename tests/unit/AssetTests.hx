import helix.asset.AssetPath;

/** Asset paths. */
@:access(helix)
class AssetTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		check(AssetPath.isValid("sounds/fire.wav")
			&& !AssetPath.isValid("../secret")
			&& !AssetPath.isValid("/tmp/file")
			&& !AssetPath.isValid("https://host/file"),
			"Assets use bounded packaged paths");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
