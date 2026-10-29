package helix.platform.adapters.system.sdl3;

import haxe.io.Path;
import helix.platform.Device;
import helix.platform.ISystem;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;

/** Provides `ISystem` on SDL3, natively: the platform SDL names, options from HELIX_ environment variables, SDL's monotonic clock, the
	program's directory as SDL finds it, and the OS's directories by each OS's rules.

	A mouse is assumed and no touch screen reported. The directories follow the rules SDL's `SDL_GetPrefPath` does for data, without its
	making the directory, and the same OS conventions for the cache, which SDL has no call for. An `XDG_` variable that isn't an absolute
	path is ignored, as the XDG specification says. */
class Sdl3SystemAdapter implements ISystem {
	/** Creates the system's facts. */
	public function new() {}

	public var device(get, never):Device;

	function get_device():Device {
		var os = switch (Sdl3Bridge.platform() : String) {
			case "Windows": "windows";
			case "macOS": "macos";
			case "Linux": "linux";
			case _: "";
		};
		return new Device(false, os, false, true);
	}

	public function getOption(name:String):Null<String> {
		var value = Sdl3Bridge.getenv("HELIX_" + name.toUpperCase());
		return value == null ? null : (value : String);
	}

	public function getTime():Float
		return Sdl3Bridge.time();

	public function getProgramDirectory():Null<String> {
		// SDL's, ending in a separator; the executable's own if SDL can't tell.
		var base = Sdl3Bridge.basePath();
		return base != null && (base : String) != "" ? Path.removeTrailingSlashes(base) : Path.directory(Sys.programPath());
	}

	public function getDataDirectory(company:String, product:String):Null<String> {
		var system = Sys.systemName();
		if (system == "Windows")
			return under(Sys.getEnv("APPDATA"), [company, product]);
		if (system == "Mac")
			return under(Sys.getEnv("HOME"), ["Library/Application Support", company, product]);
		return under(xdg("XDG_DATA_HOME", ".local/share"), [company, product]);
	}

	public function getCacheDirectory(company:String, product:String):Null<String> {
		var system = Sys.systemName();
		if (system == "Windows")
			// LOCALAPPDATA\<company>\<product> is the program's own, not only its cache.
			return under(Sys.getEnv("LOCALAPPDATA"), [company, product, "cache"]);
		if (system == "Mac")
			return under(Sys.getEnv("HOME"), ["Library/Caches", company, product]);
		return under(xdg("XDG_CACHE_HOME", ".cache"), [company, product]);
	}

	// An XDG base directory: the variable when it's an absolute path, else fallback under the home directory; null without either.
	static function xdg(variable:String, fallback:String):Null<String> {
		var value = Sys.getEnv(variable);
		return value != null && StringTools.startsWith(value, "/") ? value : under(Sys.getEnv("HOME"), [fallback]);
	}

	// base joined with parts, or null when base is unset or empty.
	static function under(base:Null<String>, parts:Array<String>):Null<String>
		return base == null || base == "" ? null : Path.join([base].concat(parts));
}
