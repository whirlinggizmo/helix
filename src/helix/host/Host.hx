package helix.host;

/** The program on its platform: whether it runs, whether anything is still loading, its run options and settings, and quitting. The program's
	one, a static class: canQuit and quit forward to instance, written by helix.macro.Facade from IHost's with their doc comments; the loop,
	the window (Window) and the clock (Time) are reached elsewhere. */
@:build(helix.macro.Facade.build(helix.host.IHost, ["run", "window", "time"]))
@:allow(helix.host.Runner)
class Host {
	/** The host forwarded to: the runner's from its start to its cleanup, null outside them. Kept across a hot reload (@:hot): set once by the
		runner, nothing would set it again. */
	@:hot public static var instance(default, null):IHost;

	/** The game's settings from config.json beside the program (Config; DECISIONS 131), or null without one. Kept across a hot reload (@:hot), as instance is. */
	@:hot public static var config(default, null):Null<Config>;

	// The runner, for busy; kept across a hot reload (@:hot), as instance is.
	@:hot static var runner:Runner;

	/** Whether the runner is running the program: false in a test, which makes what it needs itself. */
	public static var running(get, never):Bool;

	static function get_running():Bool
		return runner != null;

	/** Whether anything is still loading: an asset, an image or sound being decoded, an environment being prepared. A loading screen waits
		for it to be false (with the app's own loads in view); so does a tool taking the frame's picture once it's in. */
	public static var busy(get, never):Bool;

	static function get_busy():Bool
		return runner != null && runner.busy;

	/** A run option, or fallback when it isn't given: in a browser the URL query parameter name, natively the environment variable HELIX_
		and name in capitals; else the config's value at name (its profile over its default, dotted into nested objects), as text. */
	public static function getOption(name:String, fallback:String):String {
		var value = instance.getOption(name);
		if (value == null && config != null)
			value = config.getString(name);
		return value == null ? fallback : value;
	}

	/** getOption as a bool: 1, true, yes and on are true, 0, false, no and off are false; fallback for anything else. */
	public static function getOptionBool(name:String, fallback:Bool):Bool
		return Config.toBool(getOption(name, null), fallback);

	/** getOption as a number; fallback for anything that isn't one. */
	public static function getOptionFloat(name:String, fallback:Float):Float
		return Config.toFloat(getOption(name, null), fallback);

	/** getOption as a whole number; fallback for anything that isn't one. */
	public static function getOptionInt(name:String, fallback:Int):Int
		return Config.toInt(getOption(name, null), fallback);
}
