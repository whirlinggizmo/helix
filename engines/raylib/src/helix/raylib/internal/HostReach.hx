package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import sys.FileSystem;

using StringTools;
#end

/** Warns, as the program builds, where the program's own code reaches the page or the host for something `Extras` answers on every
	target: the URL's query or an environment variable (`GetRunOption`), the device's touch screen or pointer (`IsTouchScreenAvailable`,
	`IsFinePointerAvailable`), the screen's orientation (`SetScreenOrientationAsync`), the safe area's insets (`GetWindowSafeArea`) and
	the device's tilt (`EnableTiltAsync`). Each site warns once, naming the call; libraries' code isn't looked at. Read from the
	compiler's typed code, after typing: the fields and types reached, and the text of a string or a `js.Syntax.code` call. Run by the
	library's `extraParams.hxml`. */
@:noCompletion
class HostReach {
	#if macro
	/** What `import helix.raylib.Extras.*;` gives, as each warning ends. */
	static inline final IMPORT = "in helix.raylib.Extras (import helix.raylib.Extras.*;)";

	/** The fields that reach the host, by their owner's path and their name, and what answers each. */
	static final FIELDS:Map<String, String> = [
		"js.Browser.location" => "GetRunOption(name:String)",
		"js.html.Window.location" => "GetRunOption(name:String)",
		"js.html.Document.location" => "GetRunOption(name:String)",
		"js.html.URL.searchParams" => "GetRunOption(name:String)",
		"Sys.getEnv" => "GetRunOption(name:String)",
		"js.html.Window.matchMedia" => "IsTouchScreenAvailable() or IsFinePointerAvailable()",
		"js.html.Navigator.maxTouchPoints" => "IsTouchScreenAvailable()",
		"js.html.Screen.orientation" => "SetScreenOrientationAsync(orientation:Int, ?done:Void->Void, ?failed:String->Void)",
		"js.html.Window.ondeviceorientation" => "EnableTiltAsync(?done:Void->Void, ?failed:String->Void)"
	];

	/** The classes whose construction reaches the host, and what answers each. */
	static final CLASSES:Map<String, String> = [
		"js.html.URLSearchParams" => "GetRunOption(name:String)",
		"js.html.DeviceOrientationEvent" => "EnableTiltAsync(?done:Void->Void, ?failed:String->Void)"
	];

	/** Text that reaches the host in any string, lowercased, and what answers each. */
	static final TEXT = [
		"env(safe-area-inset" => "GetWindowSafeArea()",
		"deviceorientation" => "EnableTiltAsync(?done:Void->Void, ?failed:String->Void)"
	];

	/** Text that reaches the host in a `js.Syntax.code` string, and what answers each. */
	static final SCRIPT:Array<{pattern:EReg, call:String}> = [
		{pattern: ~/\blocation\b|URLSearchParams/, call: "GetRunOption(name:String)"},
		{pattern: ~/\bmatchMedia\b/, call: "IsTouchScreenAvailable() or IsFinePointerAvailable()"},
		{pattern: ~/\bmaxTouchPoints\b/, call: "IsTouchScreenAvailable()"},
		{pattern: ~/screen\.orientation/, call: "SetScreenOrientationAsync(orientation:Int, ?done:Void->Void, ?failed:String->Void)"}
	];

	static var done = false;
	static var libraries:Array<String>;
	static final files = new Map<String, Bool>();

	/** Looks at the program's code once it is typed. */
	public static function register():Void {
		Context.onAfterTyping(types -> {
			if (done)
				return;
			done = true;
			libraries = libraryPaths();
			for (type in types)
				switch type {
					case TClassDecl(_.get() => c):
						look(c);
					case TAbstract(_.get() => a) if (a.impl != null):
						look(a.impl.get());
					case _:
				}
		});
	}

	// Looks at a class of the program's: each field's code, its constructor's and its static initialization's.
	static function look(c:ClassType):Void {
		if (c.isExtern || !own(c.pos))
			return;
		var fields = c.statics.get().concat(c.fields.get());
		if (c.constructor != null)
			fields.push(c.constructor.get());
		for (f in fields) {
			var e = f.expr();
			if (e != null)
				walk(e, e.pos);
		}
		if (c.init != null)
			walk(c.init, c.init.pos);
	}

	// Looks at an expression and those in it; site is where the nearest of them in the program's own code is, where a shortcut the
	// standard library inlines (js.Browser.location) is reported.
	static function walk(e:TypedExpr, site:Position):Void {
		if (own(e.pos))
			site = e.pos;
		switch e.expr {
			case TCall({expr: TField(_, FStatic(_.get() => {pack: ["js"], name: "Syntax"}, _.get() => {name: "code"}))}, args) if (args.length > 0):
				switch args[0].expr {
					case TConst(TString(s)):
						var calls = [for (s2 in SCRIPT) if (s2.pattern.match(s)) s2.call];
						for (text => call in TEXT)
							if (s.toLowerCase().indexOf(text) >= 0 && calls.indexOf(call) < 0)
								calls.push(call);
						if (calls.length > 0)
							warn('js.Syntax.code reaches the page for what ${calls.join(" and ")} answers on every target', e.pos);
						for (i in 1...args.length)
							walk(args[i], site);
						return;
					case _:
				}
			case TField(_, FDynamic("location")):
				// js.Browser.location, inlined as the global object's location, or any value of no type's.
				warn('location reaches the page for what ${FIELDS.get("js.Browser.location")} answers on every target', site);
			case TField(_, access):
				var name = switch access {
					case FStatic(c, f): path(c.get()) + "." + f.get().name;
					case FInstance(c, _, f): path(c.get()) + "." + f.get().name;
					case FClosure(c, f) if (c != null): path(c.c.get()) + "." + f.get().name;
					case _: null;
				}
				var call = name == null ? null : FIELDS.get(name);
				if (call != null)
					warn('$name reaches the host for what $call answers on every target', e.pos);
			case TNew(c, _, _):
				var name = path(c.get());
				var call = CLASSES.get(name);
				if (call != null)
					warn('new $name reaches the page for what $call answers on every target', e.pos);
			case TConst(TString(s)):
				var lower = s.toLowerCase();
				for (text => call in TEXT)
					if (lower.indexOf(text) >= 0) {
						warn('"$text" reaches the page for what $call answers on every target', e.pos);
						break;
					}
			case _:
		}
		TypedExprTools.iter(e, inner -> walk(inner, site));
	}

	// Warns at a site in the program's own code; one inlined from a library's isn't the program's.
	static function warn(message:String, pos:Position):Void {
		if (own(pos))
			Context.warning('$message, $IMPORT', pos);
	}

	static function path(c:ClassType):String
		return c.pack.concat([c.name]).join(".");

	// Whether a position is in the program's own code: in a file under none of the libraries' class paths.
	static function own(pos:Position):Bool {
		var file = Context.getPosInfos(pos).file;
		var known = files.get(file);
		if (known == null) {
			var full = try FileSystem.fullPath(file) catch (_:Dynamic) null;
			known = full != null && FileSystem.exists(full) && !Lambda.exists(libraries, l -> full.startsWith(l));
			files.set(file, known);
		}
		return known;
	}

	// The class paths that are libraries' (a haxelib library's, with its haxelib.json there or a directory up) or the standard
	// library's (StdTypes.hx there, or one or two directories up, as std/js/_std is), each a full path ending in a separator.
	static function libraryPaths():Array<String> {
		var out = [];
		for (cp in Context.getClassPath()) {
			var full = try FileSystem.fullPath(cp == "" ? "." : cp) catch (_:Dynamic) null;
			if (full == null || !FileSystem.isDirectory(full))
				continue;
			full = haxe.io.Path.addTrailingSlash(haxe.io.Path.normalize(full));
			var up = full + "../", upTwo = full + "../../";
			if (FileSystem.exists(full + "haxelib.json")
				|| FileSystem.exists(up + "haxelib.json")
				|| FileSystem.exists(full + "StdTypes.hx")
				|| FileSystem.exists(up + "StdTypes.hx")
				|| FileSystem.exists(upTwo + "StdTypes.hx"))
				out.push(full);
		}
		return out;
	}
	#end
}
