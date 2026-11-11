/** Haxe's `Sys` in a page: the program's options, the console and the clock, so a program that reads them natively reads them here.
	Haxe has no `Sys` in a page. With `-D helix-raylib-portable-sys` this file is on the class path for JS (`SysCalls`), and natively
	`Sys` is Haxe's own. The calls that can't be answered here (`sleep`, `command`, `exit` and the rest) don't compile on any target with
	the define, each naming itself. */
class Sys {
	static var line = "";

	/** Writes a value to the console, a line at a time.

		@param v  The value. */
	public static function print(v:Dynamic):Void {
		line += Std.string(v);
		var end = line.lastIndexOf("\n");
		if (end >= 0) {
			for (text in line.substr(0, end).split("\n"))
				js.Syntax.code("console.log({0})", text);
			line = line.substr(end + 1);
		}
	}

	/** Writes a value and a newline to the console.

		@param v  The value. */
	public static function println(v:Dynamic):Void {
		print(Std.string(v) + "\n");
	}

	/** Returns the program's options, the URL's query as a command line: each `name=value` as `--name=value` and a bare `name` as
		`--name`, in order, decoded.

		@return  The options, empty without a query. */
	public static function args():Array<String> {
		var search:String = js.Syntax.code("(typeof location === 'undefined' ? '' : location.search)");
		var options = [];
		if (search.length > 1)
			for (part in search.substr(1).split("&"))
				if (part != "") {
					var equals = part.indexOf("=");
					options.push(equals < 0 ? "--" + StringTools.urlDecode(part) : "--" + StringTools.urlDecode(part.substr(0, equals)) + "="
						+ StringTools.urlDecode(part.substr(equals + 1)));
				}
		return options;
	}

	/** Returns an environment variable's value, which is never set here.

		@param s  The variable's name.
		@return  Null. */
	public static function getEnv(s:String):Null<String> {
		return null;
	}

	/** Returns the environment variables, of which there are none here.

		@return  An empty map. */
	public static function environment():Map<String, String> {
		return new Map();
	}

	/** Sets the locale for time formatting, which can't be changed here.

		@param loc  The locale.
		@return  False. */
	public static function setTimeLocale(loc:String):Bool {
		return false;
	}

	/** Returns the time, in seconds since 1970.

		@return  The time. */
	public static function time():Float {
		return js.Syntax.code("Date.now()") / 1000;
	}

	/** Returns the time the program has run, in seconds.

		@return  The time. */
	public static function cpuTime():Float {
		return js.Syntax.code("performance.now()") / 1000;
	}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@param s  The variable's name.
		@param v  Its value. */
	public static function putEnv(s:String, v:Null<String>):Void {}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@param seconds  How long. */
	public static function sleep(seconds:Float):Void {}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@return  Nothing. */
	public static function getCwd():String {
		return null;
	}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@param s  The directory. */
	public static function setCwd(s:String):Void {}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@return  Nothing. */
	public static function systemName():String {
		return null;
	}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@param cmd  The command.
		@param args  Its arguments.
		@return  Nothing. */
	public static function command(cmd:String, ?args:Array<String>):Int {
		return 0;
	}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@param code  The exit code. */
	public static function exit(code:Int):Void {}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@return  Nothing. */
	public static function executablePath():String {
		return null;
	}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@return  Nothing. */
	public static function programPath():String {
		return null;
	}

	/** Doesn't compile, as `helix.raylib.internal.SysCalls` reports.

		@param echo  Whether the character is echoed.
		@return  Nothing. */
	public static function getChar(echo:Bool):Int {
		return 0;
	}
}
