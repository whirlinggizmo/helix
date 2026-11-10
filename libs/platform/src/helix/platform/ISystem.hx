package helix.platform;

/** Defines the facts about where the program runs.

	They are the program's company and product, the device, the options the program was started with, the time, where the program's own
	files are, and where the OS keeps a program's files. */
interface ISystem {
	/** Gets the company that makes the program: the `helix-company` define, which every program sets. */
	var company(default, null):String;

	/** Gets the program's name: the `helix-product` define, which every program sets. It names the program
		wherever one is shown, such as a window's title or a log. */
	var product(default, null):String;

	/** Gets what the program runs on, as far as the platform reports it. */
	var device(get, never):Device;

	/** Returns an option the program was started with.

		Natively the option is the command line's `--name=value`, or a bare `--name` for an empty value. When the command line doesn't
		have it, it is the environment variable named HELIX_ followed by the name in capitals. In a page it is the URL's query parameter
		of that name.
		@param name  The option's name.
		@return  The option's value, or null when it is not set. */
	function getOption(name:String):Null<String>;

	/** Returns the bytes of memory the program holds now, as far as the platform tells: natively the process's resident memory (what the
		OS has in RAM for it, code and data alike); in a page the script's heap where the browser reports it (Chromium), and 0 where it
		doesn't. A reading for a stats line, not an accounting: what it counts differs by platform, so compare readings on one.

		@return  The bytes, or 0 when the platform can't tell. */
	function getMemoryBytes():Float;

	/** Returns the time on a monotonic clock, for measuring how long something took, such as a frame.

		It never goes back or jumps when the system's clock is set. A pause in the program, such as at a debugger or in a hidden page,
		counts as time that passed. In a page the clock is `performance.now`, and natively it is SDL's.
		@return  Seconds from an unspecified zero. */
	function getTime():Float;

	/** Returns where the files that ship with the program are, such as its assets.

		Natively it is the executable's directory, or `Contents/Resources` in a macOS app bundle, and a read-only `IFileSystem` reads it. In
		a page it is "./", the page's own directory on its server, as a URL relative to the page that `IHttp` fetches from.
		@return  The directory natively, or the URL in a page. */
	function getProgramDirectory():String;

	/** Returns where the OS keeps a program's files that must last, such as its saves.

		Natively it is the user's data directory, then the company and the product (the `helix-company` and `helix-product` defines). The user's data directory is `$XDG_DATA_HOME` or
		`~/.local/share` on Linux, `~/Library/Application Support` on macOS, and `%APPDATA%` on Windows. The directory may not exist yet.

		In a page it is the name of the database where the browser keeps the program's files, "company/product/data".
		@return  The directory natively, or the database's name in a page.
		@throws String  Natively, when the environment variable the directory comes from is set to a path that isn't absolute, or is unset
			and the OS has no such directory. */
	function getDataDirectory():String;

	/** Returns where the OS keeps a program's files that can be made or fetched again, such as downloaded assets.

		Natively it is the user's cache directory, then the company and the product (the `helix-company` and `helix-product` defines). The user's cache directory is `$XDG_CACHE_HOME` or
		`~/.cache` on Linux, and `~/Library/Caches` on macOS. On Windows it is `%LOCALAPPDATA%`, then the company, the product and `cache`.
		The directory may not exist yet.

		In a page it is the name of the database where the browser keeps the program's files, "company/product/cache".
		@return  The directory natively, or the database's name in a page.
		@throws String  Natively, when the environment variable the directory comes from is set to a path that isn't absolute, or is unset
			and the OS has no such directory. */
	function getCacheDirectory():String;

	/** Opens a URL in the system's browser. In a page it opens in a new tab, which the browser allows only soon after a key press, click
		or tap; without one, it opens at the player's next.

		@param url  The URL: http, https or mailto.
		@return  False, opening nothing, for a URL of another scheme. */
	function openUrl(url:String):Bool;
}
