package helix.log;

/** Provides the log: messages for whoever is developing the program, each with how much it matters and, optionally, a tag saying what
	it's about.

	A line says where it was written from, as trace does (`Game.hx:42: [physics] ball at 10, 4`). In the browser it goes to the console
	(console.debug, info, warn and error, so the console's own filter works); natively, debug and info lines go to the standard output and
	warnings and errors to the standard error, colored by level unless the `NO_COLOR` environment variable is set.

	What's written is what's at or above `Log.level`, or a tag's own level when it has one. `Log.debug` is gone from a release build, so it
	can be left in freely. `trace` goes through the log as Info once `install` is called.
	```haxe
	Log.install();
	Log.info("level 3 loaded");
	Log.warn("no save yet", "saves");
	Log.setTagLevel("physics", Warning);
	```
 */
class Log {
	/** Gets or sets the least a message must matter to be written, unless its tag has a level of its own.

		It starts as Debug in a debug build and Info in a release. Off writes nothing. */
	public static var level:LogLevel = #if debug Debug #else Info #end;

	/** Gets whether `trace` goes through the log: true from `install` until `uninstall`. */
	public static var installed(get, never):Bool;

	static var tagLevels:Map<String, LogLevel> = [];
	static var listeners:Array<(LogLevel, String) -> Void> = [];
	// trace as it was before install, and the function install put in its place.
	static var plainTrace:Null<(Dynamic, ?haxe.PosInfos) -> Void>;
	static var ownTrace:Null<(Dynamic, ?haxe.PosInfos) -> Void>;
	#if sys
	static var color = Sys.getEnv("NO_COLOR") == null || Sys.getEnv("NO_COLOR") == "";
	#end

	/** Writes a message as Debug: detail for finding a fault.

		A release build leaves the call out.
		@param message  The message: anything, written as a string.
		@param tag  Optional. What it's about. */
	public static inline function debug(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void {
		#if debug
		write(Debug, message, tag, pos);
		#end
	}

	/** Writes a message as Info: what happened, worth knowing.

		@param message  The message: anything, written as a string.
		@param tag  Optional. What it's about. */
	public static function info(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
		write(Info, message, tag, pos);

	/** Writes a message as Warning: something went wrong and the program carried on.

		@param message  The message: anything, written as a string.
		@param tag  Optional. What it's about. */
	public static function warn(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
		write(Warning, message, tag, pos);

	/** Writes a message as Error: something failed that the program may not recover from.

		@param message  The message: anything, written as a string.
		@param tag  Optional. What it's about. */
	public static function error(message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void
		write(Error, message, tag, pos);

	/** Writes a message at a level, when `isWritten` lets it through.

		Each listener receives the line, then the console or the process's output.
		@param level  How much it matters.
		@param message  The message: anything, written as a string.
		@param tag  Optional. What it's about. */
	public static function write(level:LogLevel, message:Dynamic, ?tag:String, ?pos:haxe.PosInfos):Void {
		if (!isWritten(level, tag))
			return;
		var line = format(message, tag, pos);
		for (listener in listeners.copy())
			listener(level, line);
		#if js
		switch level {
			case Debug:
				js.Browser.console.debug(line);
			case Info:
				js.Browser.console.info(line);
			case Warning:
				js.Browser.console.warn(line);
			case _:
				js.Browser.console.error(line);
		}
		#elseif sys
		switch level {
			case Debug:
				Sys.println(colored(line, "36"));
			case Info:
				Sys.println(line);
			case Warning:
				Sys.stderr().writeString(colored('warning: $line', "33") + "\n");
			case _:
				Sys.stderr().writeString(colored('error: $line', "31") + "\n");
		}
		#else
		(plainTrace != null ? plainTrace : haxe.Log.trace)(line, null);
		#end
	}

	/** Returns whether a message would be written, to skip building a costly one that wouldn't be.

		@param level  How much it would matter.
		@param tag  Optional. What it would be about.
		@return  True when the level is at or above the tag's own level, or `Log.level` for a tag without one. */
	public static function isWritten(level:LogLevel, ?tag:String):Bool {
		var least = tag != null && tagLevels.exists(tag) ? tagLevels[tag] : Log.level;
		return level != Off && least != Off && (level : Int) >= (least : Int);
	}

	/** Sets a tag's own level, in place of `Log.level` for its messages.

		@param tag  The tag.
		@param level  The least its messages must matter to be written: Off silences it, and null gives it `Log.level` again. */
	public static function setTagLevel(tag:String, level:Null<LogLevel>):Void {
		if (level == null)
			tagLevels.remove(tag);
		else
			tagLevels[tag] = level;
	}

	/** Adds a listener that receives each line written, for an in-program console, an overlay or a test.

		Adding the same listener again does nothing.
		@param listener  Receives the line's level and the line as written. */
	public static function listen(listener:(LogLevel, String) -> Void):Void
		if (listeners.indexOf(listener) < 0)
			listeners.push(listener);

	/** Removes a listener that `listen` added.

		@param listener  The listener. */
	public static function unlisten(listener:(LogLevel, String) -> Void):Void
		listeners.remove(listener);

	/** Routes `trace` through the log as Info, its extra values after the first.

		Calling it again while installed does nothing. */
	public static function install():Void {
		if (ownTrace != null)
			return;
		plainTrace = haxe.Log.trace;
		ownTrace = (value, ?infos) -> {
			var text = Std.string(value);
			if (infos != null && infos.customParams != null)
				for (more in infos.customParams)
					text += ", " + Std.string(more);
			write(Info, text, null, infos);
		};
		haxe.Log.trace = ownTrace;
	}

	/** Gives `trace` back what it was before `install`.

		If something else replaced `trace` after `install`, that replacement is kept, and the log stops being installed all the same. */
	public static function uninstall():Void {
		if (ownTrace == null)
			return;
		if (Reflect.compareMethods(haxe.Log.trace, ownTrace))
			haxe.Log.trace = plainTrace;
		ownTrace = null;
		plainTrace = null;
	}

	static function get_installed():Bool
		return ownTrace != null;

	// "File.hx:42: [tag] message", as trace writes its place; natively a file under the working directory is named from it.
	static function format(message:Dynamic, tag:Null<String>, pos:Null<haxe.PosInfos>):String {
		var text = tag != null ? '[$tag] ' + Std.string(message) : Std.string(message);
		return pos != null ? '${place(pos.fileName)}:${pos.lineNumber}: $text' : text;
	}

	static function place(file:String):String {
		#if sys
		var here = haxe.io.Path.addTrailingSlash(haxe.io.Path.normalize(Sys.getCwd()));
		var normal = haxe.io.Path.normalize(file);
		if (haxe.io.Path.isAbsolute(normal) && StringTools.startsWith(normal, here))
			return normal.substr(here.length);
		#end
		return file;
	}

	#if sys
	// The line in an ANSI color, unless NO_COLOR says not to.
	static function colored(line:String, code:String):String
		return color ? '\x1b[${code}m$line\x1b[0m' : line;
	#end
}
