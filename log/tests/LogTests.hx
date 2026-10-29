import helix.log.Log;
import helix.log.LogLevel;

/** Checks the log with the library alone: levels and tags letting messages through, the line's place and tag, listeners, trace going
	through it once installed and back as it was once not, and Log.debug left out of a build that isn't a debug one (as this one). Run by
	helix.py test on the interpreter and Node. */
class LogTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		// What was written, through a listener: its level and line.
		var written = [];
		Log.listen((level, line) -> written.push('$level $line'));
		Log.level = Info;
		Log.info("hello");
		check(written.length == 1
			&& StringTools.endsWith(written[0], "LogTests.hx:21: hello")
			&& StringTools.startsWith(written[0], "Info "),
			"A line says its level, where it was written and what");
		Log.warn("no save", "saves");
		check(StringTools.endsWith(written[1], ": [saves] no save")
			&& StringTools.startsWith(written[1], "Warning "), "A tag before the message");
		Log.debug("detail");
		check(written.length == 2, "Log.debug is left out of a release build");
		Log.level = Warning;
		Log.info("quiet");
		Log.error("loud");
		check(written.length == 3 && StringTools.endsWith(written[2], "loud"), "Below Log.level, nothing; at or above it, written");
		Log.setTagLevel("audio", Error);
		Log.warn("a clip", "audio");
		Log.setTagLevel("ui", Info);
		Log.info("a button", "ui");
		check(written.length == 4 && StringTools.endsWith(written[3], "[ui] a button"), "A tag's own level, above or below Log.level");
		Log.setTagLevel("ui", Off);
		Log.error("silenced", "ui");
		Log.setTagLevel("ui", null);
		Log.error("back", "ui");
		check(written.length == 5 && StringTools.endsWith(written[4], "[ui] back"), "Off silences a tag; null gives it Log.level again");
		check(!Log.isWritten(Info) && Log.isWritten(Error) && !Log.isWritten(Warning, "audio") && !Log.isWritten(Off), "isWritten says so ahead");
		var heard = [];
		var listener = (level:LogLevel, line:String) -> heard.push(level);
		Log.listen(listener);
		Log.error("one");
		Log.unlisten(listener);
		Log.error("two");
		check(heard.length == 1 && heard[0] == Error, "A listener hears each line until it stops listening");
		Log.level = Info;
		check(!Log.installed, "Not installed until install");
		var before = haxe.Log.trace;
		Log.install();
		Log.install();
		trace("traced", 2);
		check(Log.installed
			&& StringTools.startsWith(written[written.length - 1], "Info ")
			&& StringTools.endsWith(written[written.length - 1], ": traced, 2"),
			"Installed, trace goes through Log as Info, its extra values after");
		Log.uninstall();
		check(!Log.installed && Reflect.compareMethods(haxe.Log.trace, before), "Uninstalled, trace is as it was");
		Log.install();
		var other = (v:Dynamic, ?infos:haxe.PosInfos) -> {};
		haxe.Log.trace = other;
		Log.uninstall();
		check(!Log.installed && Reflect.compareMethods(haxe.Log.trace, other), "A trace put in after install is kept by uninstall");
		haxe.Log.trace = before;
		Log.level = Off;
		Log.error("nothing");
		check(StringTools.endsWith(written[written.length - 1], ": traced, 2"), "Log.level Off writes nothing");
		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
