package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import sys.FileSystem;

using StringTools;
#end

/** Warns, as the program builds, where the program's own code reaches the page or the host for something `Extras` or `Raylib` answers
	on every target: the URL's query or an environment variable (`GetRunOption`), the device's touch screen or pointer
	(`IsTouchScreenAvailable`, `IsFinePointerAvailable`), the screen's orientation (`SetScreenOrientationAsync`), the safe area's insets
	(`GetWindowSafeArea`), the device's tilt (`EnableTiltAsync`), the page's storage (`SaveFileTextAsync`, `LoadFileTextAsync`) and its
	fullscreen (`IsFullscreenAvailable`, `IsWindowFullscreen`, `ToggleFullscreenAsync`), when the program is built with
	`-D helix-raylib-host-warnings`: off by default, as a person reads the README and may reach the host on purpose, and on for an agent
	writing raylib from memory (a trial). Each warning reads as a refusal does ("js.html.Window.matchMedia: Works only in a browser. See
	IsTouchScreenAvailable() or IsFinePointerAvailable() in helix.raylib.Extras (import helix.raylib.Extras.*;)."). Each site warns
	once for each call, and libraries' code isn't looked at. Read from the compiler's typed code, after typing: the fields and types reached, and the text
	of a string or a `js.Syntax.code` call. Run by the library's `extraParams.hxml`. */
@:noCompletion
class HostReach {
	#if macro
	/** What `import helix.raylib.Extras.*;` gives, as each warning naming an `Extras` call ends. */
	static inline final IMPORT = "in helix.raylib.Extras (import helix.raylib.Extras.*;)";

	static inline final RUN_OPTION = "GetRunOption(name:String)";
	static inline final POINTER = "IsTouchScreenAvailable() or IsFinePointerAvailable()";
	static inline final TOUCH_SCREEN = "IsTouchScreenAvailable()";
	static inline final ORIENTATION = "SetScreenOrientationAsync(orientation:Int, ?done:Void->Void, ?failed:String->Void) with ORIENTATION_LANDSCAPE, ORIENTATION_PORTRAIT or ORIENTATION_ANY";
	static inline final TILT = "EnableTiltAsync(?done:Void->Void, ?failed:String->Void)";
	static inline final SAFE_AREA = "GetWindowSafeArea()";
	static inline final SAVE = "SaveFileTextAsync(fileName:String, text:String, ?done:Void->Void, ?failed:String->Void) and LoadFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)";
	static inline final CAN_FULLSCREEN = "IsFullscreenAvailable()";
	static inline final IS_FULLSCREEN = "IsWindowFullscreen()";
	static inline final FULLSCREEN = "ToggleFullscreenAsync(?done:Void->Void, ?failed:String->Void)";

	/** The calls `Raylib` has, which need no import. */
	static final RAYLIB = [IS_FULLSCREEN];

	/** What a warning naming a call adds, after the call. */
	static final NOTES:Map<String, String> = [
		SAVE => "The save file persists between runs, including both native and web builds."
	];

	/** The fields that reach the host, by their owner's path and their name, and what answers each. */
	static final FIELDS:Map<String, String> = [
		"js.Browser.location" => RUN_OPTION,
		"js.html.Window.location" => RUN_OPTION,
		"js.html.Document.location" => RUN_OPTION,
		"js.html.URL.searchParams" => RUN_OPTION,
		"Sys.getEnv" => RUN_OPTION,
		"js.html.Window.matchMedia" => POINTER,
		"js.html.Navigator.maxTouchPoints" => TOUCH_SCREEN,
		"js.html.Screen.orientation" => ORIENTATION,
		"js.html.Window.ondeviceorientation" => TILT,
		"js.Browser.getLocalStorage" => SAVE,
		"js.Browser.getSessionStorage" => SAVE,
		"js.html.Window.localStorage" => SAVE,
		"js.html.Window.sessionStorage" => SAVE,
		"js.html.Window.indexedDB" => SAVE,
		"js.html.Document.fullscreenEnabled" => CAN_FULLSCREEN,
		"js.html.Document.fullscreenElement" => IS_FULLSCREEN,
		"js.html.Element.requestFullscreen" => FULLSCREEN,
		"js.html.Document.exitFullscreen" => FULLSCREEN
	];

	/** The classes whose construction reaches the host, and what answers each. */
	static final CLASSES:Map<String, String> = [
		"js.html.URLSearchParams" => RUN_OPTION,
		"js.html.DeviceOrientationEvent" => TILT
	];

	/** Text that reaches the host in any string, lowercased, and what answers each. */
	static final TEXT = ["env(safe-area-inset" => SAFE_AREA, "deviceorientation" => TILT];

	/** Text that reaches the host in a `js.Syntax.code` string, and what answers each. */
	static final SCRIPT:Array<{pattern:EReg, call:String}> = [
		{pattern: ~/\blocation\b|URLSearchParams/, call: RUN_OPTION},
		{pattern: ~/\bmatchMedia\b/, call: POINTER},
		{pattern: ~/\bmaxTouchPoints\b/, call: TOUCH_SCREEN},
		{pattern: ~/screen\.orientation/, call: ORIENTATION},
		{pattern: ~/\b(localStorage|sessionStorage|indexedDB)\b/, call: SAVE},
		{pattern: ~/\bfullscreenEnabled\b/, call: CAN_FULLSCREEN},
		{pattern: ~/\bfullscreenElement\b/, call: IS_FULLSCREEN},
		{pattern: ~/\b(requestFullscreen|exitFullscreen)\b/, call: FULLSCREEN}
	];

	static var done = false;
	static var libraries:Array<String>;
	static final files = new Map<String, Bool>();

	/** Looks at the program's code once it is typed. */
	public static function register():Void {
		if (!Context.defined("helix-raylib-host-warnings"))
			return;
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
						for (call in calls)
							warn("js.Syntax.code", call, e.pos);
						for (i in 1...args.length)
							walk(args[i], site);
						return;
					case _:
				}
			case TField(_, FDynamic("location")):
				// js.Browser.location, inlined as the global object's location, or any value of no type's.
				warn("location", RUN_OPTION, site);
			case TField(_, access):
				var name = switch access {
					case FStatic(c, f): path(c.get()) + "." + f.get().name;
					case FInstance(c, _, f): path(c.get()) + "." + f.get().name;
					case FClosure(c, f) if (c != null): path(c.c.get()) + "." + f.get().name;
					case _: null;
				}
				var call = name == null ? null : FIELDS.get(name);
				if (call != null)
					warn(name, call, e.pos);
			case TNew(c, _, _):
				var name = path(c.get());
				var call = CLASSES.get(name);
				if (call != null)
					warn('new $name', call, e.pos);
			case TConst(TString(s)):
				var lower = s.toLowerCase();
				for (text => call in TEXT)
					if (lower.indexOf(text) >= 0) {
						warn('"$text"', call, e.pos);
						break;
					}
			case _:
		}
		TypedExprTools.iter(e, inner -> walk(inner, site));
	}

	// Warns at a site in the program's own code, as a refusal reads: what was reached, the one target it works on, and the call to use
	// instead. One inlined from a library's isn't the program's.
	static function warn(reached:String, call:String, pos:Position):Void {
		if (!own(pos))
			return;
		var target = reached.startsWith("Sys.") ? "natively" : "in a browser";
		var where = RAYLIB.indexOf(call) < 0 ? " " + IMPORT : "";
		var note = NOTES.exists(call) ? " " + NOTES.get(call) : "";
		Context.warning('$reached: Works only $target. See $call$where.$note', pos);
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
