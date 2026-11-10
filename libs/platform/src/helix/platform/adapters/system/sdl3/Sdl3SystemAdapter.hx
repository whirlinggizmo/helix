package helix.platform.adapters.system.sdl3;

import haxe.io.Path;
import helix.platform.Device;
import helix.platform.ISystem;
import helix.platform.adapters.shared.ProgramName;
import helix.platform.adapters.shared.SystemUrl;
import helix.platform.adapters.shared.sdl3.Sdl3Bridge;

/** Provides `ISystem` on SDL3, natively: the platform SDL names, options from HELIX_ environment variables, SDL's monotonic clock, the
	program's directory as SDL finds it, and the OS's directories by each OS's rules.

	A mouse is assumed. The directories follow the rules SDL's `SDL_GetPrefPath` does for data, without its
	making the directory, and the same OS conventions for the cache, which SDL has no call for. Each comes from its environment variable
	when that's set, and from the OS when it isn't (the user database's home directory, Windows' shell folders); an empty one counts as
	unset. A variable set to a path that isn't absolute throws, naming it, where the XDG specification would ignore it: someone set it, and
	quietly writing elsewhere would hide the mistake. */
class Sdl3SystemAdapter implements ISystem {
	public var company(default, null):String;

	public var product(default, null):String;

	/** Creates the system's facts for the program the `helix-company` and `helix-product` defines name. */
	public function new() {
		company = ProgramName.company();
		product = ProgramName.product();
	}

	public var device(get, never):Device;

	function get_device():Device {
		var os = switch (Sdl3Bridge.platform() : String) {
			case "Windows": "windows";
			case "macOS": "macos";
			case "Linux": "linux";
			case _: "";
		};
		// The architecture the program was built for, which is the one it runs as.
		var architecture = #if HXCPP_ARM64 "arm64" #elseif HXCPP_M64 "x86_64" #elseif HXCPP_M32 "x86" #else "" #end;
		return new Device(false, os, architecture, true);
	}

	public function getOption(name:String):Null<String> {
		var flag = "--" + name;
		for (arg in Sys.args()) {
			if (arg == flag)
				return "";
			if (StringTools.startsWith(arg, flag + "="))
				return arg.substr(flag.length + 1);
		}
		var value = Sdl3Bridge.getenv("HELIX_" + name.toUpperCase());
		return value == null ? null : (value : String);
	}

	public function getTime():Float
		return Sdl3Bridge.time();

	public function getMemoryBytes():Float
		return Sdl3Bridge.memoryBytes();

	public function getProgramDirectory():String {
		// SDL's, ending in a separator; the executable's own if SDL can't tell.
		var base = Sdl3Bridge.basePath();
		return base != null && (base : String) != "" ? Path.removeTrailingSlashes(base) : Path.directory(Sys.programPath());
	}

	public function getDataDirectory():String {
		var system = Sys.systemName();
		if (system == "Windows")
			return Path.join([directory("APPDATA", APP_DATA), company, product]);
		if (system == "Mac")
			return Path.join([directory("HOME", HOME), "Library/Application Support", company, product]);
		return Path.join([xdg("XDG_DATA_HOME", ".local/share"), company, product]);
	}

	public function openUrl(url:String):Bool
		return SystemUrl.isOpenable(url) && Sdl3Bridge.openUrl(url) != 0;

	public function getCacheDirectory():String {
		var system = Sys.systemName();
		if (system == "Windows")
			// LOCALAPPDATA\<company>\<product> is the program's own, not only its cache.
			return Path.join([directory("LOCALAPPDATA", LOCAL_APP_DATA), company, product, "cache"]);
		if (system == "Mac")
			return Path.join([directory("HOME", HOME), "Library/Caches", company, product]);
		return Path.join([xdg("XDG_CACHE_HOME", ".cache"), company, product]);
	}

	// The OS's directories the bridge asks for (helix_sdl3_os_directory).
	static inline final HOME = 0;
	static inline final APP_DATA = 1;
	static inline final LOCAL_APP_DATA = 2;

	// An XDG base directory: the variable's, or fallback under the home directory when it's unset.
	static function xdg(variable:String, fallback:String):String {
		var value = set(variable);
		return value != null ? value : Path.join([directory("HOME", HOME), fallback]);
	}

	// A directory from its environment variable, or from the OS when that's unset.
	static function directory(variable:String, which:Int):String {
		var value = set(variable);
		if (value != null)
			return value;
		var found = Sdl3Bridge.osDirectory(which);
		if (found == null || (found : String) == "")
			throw '$variable is unset, and the OS has no directory for it';
		return found;
	}

	// A variable's value when it's set and not empty, which must then be an absolute path; null when it's unset or empty.
	static function set(variable:String):Null<String> {
		var value = Sys.getEnv(variable);
		if (value == null || value == "")
			return null;
		if (!Path.isAbsolute(value))
			throw '$variable is "$value", which isn\'t an absolute path';
		return value;
	}
}
