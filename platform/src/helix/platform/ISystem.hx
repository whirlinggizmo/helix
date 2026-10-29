package helix.platform;

/** Defines the facts about where the program runs: the device, the options it was started with, the time, where its own files are, and
	where the OS keeps a program's files. */
interface ISystem {
	/** Gets what the program runs on, as the platform says. */
	var device(get, never):Device;

	/** Returns an option the program was started with.

		@param name  The option's name.
		@return  Natively the environment variable HELIX_ and name in capitals; in a page the URL's query parameter name; null when not set. */
	function getOption(name:String):Null<String>;

	/** Returns the time on a monotonic clock, for measuring how long something took, such as a frame.

		It never goes back or jumps when the system's clock is set; a pause in the program (a debugger, a hidden page) is time that passed.
		In a page `performance.now`, natively SDL's.
		@return  Seconds from an unspecified zero. */
	function getTime():Float;

	/** Returns the directory of the files that ship with the program, such as its assets.

		Natively the executable's directory; in a macOS app bundle, its `Contents/Resources`. A read-only `IFileSystem` over it reads them. In a
		page they're on the server, fetched with `IHttp`.
		@return  The directory, or null in a page. */
	function getProgramDirectory():Null<String>;

	/** Returns where the OS keeps a program's files that must last, such as its saves.

		Natively the user's data directory (`$XDG_DATA_HOME` or `~/.local/share` on Linux, `~/Library/Application Support` on macOS,
		`%APPDATA%` on Windows), then the company and the product. The directory may not exist yet.
		@param company  The company's name, a plain directory name.
		@param product  The product's name, a plain directory name.
		@return  The directory, or null in a page, where the browser keeps a program's files, or when the OS's directory can't be found. */
	function getDataDirectory(company:String, product:String):Null<String>;

	/** Returns where the OS keeps a program's files that can be made or fetched again, such as downloaded assets.

		Natively the user's cache directory (`$XDG_CACHE_HOME` or `~/.cache` on Linux, `~/Library/Caches` on macOS), then the company and the
		product; on Windows `%LOCALAPPDATA%`, the company, the product and `cache`. The directory may not exist yet.
		@param company  The company's name, a plain directory name.
		@param product  The product's name, a plain directory name.
		@return  The directory, or null in a page, where the browser keeps a program's files, or when the OS's directory can't be found. */
	function getCacheDirectory(company:String, product:String):Null<String>;
}
