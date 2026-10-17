package helix.host;

import haxe.io.Bytes;

/** A game's settings from config.json among its assets, fetched as the program starts (so a deployed game changes them without a build):
	a "default" object, and named profiles over it ("development", "production", any the game names), each a partial that layers on the
	default; "profile" at the root names the one in force, and the run option config=<name> overrides that. Services.getOption reads the
	profile, by dotted names into nested objects ("renderer.background"), after the run options. The keys and their meanings are the game's:
	whether to show a splash, play music, where assets are. */
class Config {
	var root:Dynamic;
	var profileName:String;
	var profile:Dynamic;
	var defaults:Dynamic;

	function new(root:Dynamic, profileName:String) {
		this.root = root;
		defaults = Reflect.field(root, "default");
		if (defaults == null)
			defaults = {};
		this.profileName = profileName;
		profile = Reflect.field(root, profileName);
		if (profile == null)
			profile = {};
	}

	/** The config in bytes (JSON), with the profile chosen (the root's "profile", else "default") unless profileName names one. Null for bytes
		that aren't a JSON object. */
	public static function parse(bytes:Bytes, ?profileName:String):Null<Config> {
		var root:Dynamic = try haxe.Json.parse(bytes.toString()) catch (_:Dynamic) null;
		if (root == null || !Reflect.isObject(root) || Std.isOfType(root, Array))
			return null;
		var name = profileName != null ? profileName : Std.isOfType(Reflect.field(root, "profile"),
			String) ? (Reflect.field(root, "profile") : String) : "default";
		return new Config(root, name);
	}

	/** The profile in force. */
	public function getProfileName():String
		return profileName;

	/** The profiles the file has, in name order, "default" among them when it does. */
	public function getProfileNames():Array<String> {
		var names = [
			for (f in Reflect.fields(root))
				if (f != "profile" && Reflect.isObject(Reflect.field(root, f)) && !Std.isOfType(Reflect.field(root, f), Array)) f
		];
		names.sort((a, b) -> a < b ? -1 : a > b ? 1 : 0);
		return names;
	}

	/** The value at name (dotted into nested objects) in the profile, else in the default; null for none. A number, a string, a bool, an
		array or an object, as the JSON has it. */
	public function get(name:String):Null<Dynamic> {
		var found = lookup(profile, name);
		return found != null ? found : lookup(defaults, name);
	}

	/** The value at name as text: a string as it is, a number or bool as JSON writes it ("1.5", "true"); null for none or an object. */
	public function getString(name:String):Null<String> {
		var v = get(name);
		if (v == null || Reflect.isObject(v) && !Std.isOfType(v, String))
			return null;
		return Std.isOfType(v, String) ? v : haxe.Json.stringify(v);
	}

	/** text as a bool: 1, true, yes and on are true, 0, false, no and off are false (any case); fallback for anything else or null. */
	public static function toBool(text:Null<String>, fallback:Bool):Bool {
		if (text == null)
			return fallback;
		return switch StringTools.trim(text).toLowerCase() {
			case "1" | "true" | "yes" | "on": true;
			case "0" | "false" | "no" | "off": false;
			case _: fallback;
		}
	}

	/** text as a number; fallback for anything that isn't one, or null. */
	public static function toFloat(text:Null<String>, fallback:Float):Float {
		if (text == null)
			return fallback;
		var v = Std.parseFloat(StringTools.trim(text));
		return Math.isNaN(v) ? fallback : v;
	}

	/** text as a whole number; fallback for anything that isn't one, or null. */
	public static function toInt(text:Null<String>, fallback:Int):Int {
		if (text == null)
			return fallback;
		var v = Std.parseInt(StringTools.trim(text));
		return v == null ? fallback : v;
	}

	static function lookup(object:Dynamic, name:String):Null<Dynamic> {
		var at:Dynamic = object;
		for (part in name.split(".")) {
			if (at == null || !Reflect.isObject(at) || Std.isOfType(at, String))
				return null;
			at = Reflect.field(at, part);
		}
		return at;
	}
}
