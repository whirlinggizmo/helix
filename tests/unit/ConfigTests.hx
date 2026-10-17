import haxe.io.Bytes;
import helix.host.Config;

/** A game's settings (helix.host.Config): profiles over a default, the one in force by the file or by name, dotted names into nested
	objects, values as text, and the typed readings of run options and config values. */
class ConfigTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		var text = '{"profile": "development", "default": {"showSplash": true, "music": 1, "name": "Gibson", "renderer": {"background": "#411a43", "width": 1280}, "list": [1, 2]},
			"development": {"showSplash": false, "renderer": {"width": 640}}, "production": {"login": true}}';
		var config = Config.parse(Bytes.ofString(text));
		check(config != null && config.getProfileName() == "development", "The file names its profile");
		check(config.getProfileNames().join(",") == "default,development,production", "The profiles it has");
		check(config.get("showSplash") == false && config.get("music") == 1 && config.get("name") == "Gibson", "The profile's value over the default's");
		check(config.get("login") == null && config.get("renderer.background") == "#411a43" && config.get("renderer.width") == 640,
			"Nothing from another profile; dotted names into nested objects, each level layered");
		check(config.getString("music") == "1"
			&& config.getString("showSplash") == "false"
			&& config.getString("name") == "Gibson"
			&& config.getString("renderer") == null
			&& config.getString("nothing") == null,
			"Values as text; an object or nothing is null");
		var production = Config.parse(Bytes.ofString(text), "production");
		check(production.getProfileName() == "production" && production.get("login") == true && production.get("showSplash") == true,
			"A profile by name, over the default");
		var bare = Config.parse(Bytes.ofString('{"default": {"a": 1}}'));
		check(bare.getProfileName() == "default" && bare.get("a") == 1, "Without a profile named, the default");
		var unknown = Config.parse(Bytes.ofString(text), "staging");
		check(unknown.getProfileName() == "staging" && unknown.get("showSplash") == true, "An unknown profile is the default alone");
		check(Config.parse(Bytes.ofString("not json")) == null && Config.parse(Bytes.ofString("[1, 2]")) == null, "Not an object: null");
		check(Config.toBool("1", false) && Config.toBool(" True ", false) && Config.toBool("yes", false) && Config.toBool("on", false)
			&& !Config.toBool("0", true) && !Config.toBool("false", true) && !Config.toBool("off", true) && Config.toBool("maybe", true)
			&& !Config.toBool(null, false),
			"Bools from 1, true, yes, on and their opposites, else the fallback");
		check(Config.toFloat("1.5", 0) == 1.5 && Config.toFloat("x", 2) == 2 && Config.toFloat(null, 3) == 3 && Config.toInt("12", 0) == 12
			&& Config.toInt("1.5", 7) == 1 && Config.toInt("x", 7) == 7,
			"Numbers from text, else the fallback");
		Sys.println(haxe.Json.stringify({passed: true, checks: checks}));
	}
}
