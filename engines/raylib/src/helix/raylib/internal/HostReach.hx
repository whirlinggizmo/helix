package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import sys.FileSystem;

using StringTools;
#end

/** Warns, as the program builds, where the program's own code reaches the page for something `Raylib` answers
	on every target: the page's storage (`SaveFileTextAsync`, `LoadSavedFileTextAsync`) and its fullscreen (`IsWindowFullscreen`,
	`ToggleFullscreen`), when the program is built with
	`-D helix-raylib-host-warnings`: off by default, as a person reads the README and may reach the host on purpose, and on for an agent
	writing raylib from memory (a trial). Each warning reads as a refusal does ("js.html.Element.requestFullscreen: Works only in a
	browser. See ToggleFullscreen()."). Each site warns once for each call, and libraries' code isn't looked at. Read from the
	compiler's typed code, after typing: the fields reached, and the text of a `js.Syntax.code` call. Run by the library's
	`extraParams.hxml`. */
@:noCompletion
class HostReach {
	#if macro
	static inline final SAVE = "SaveFileTextAsync(fileName:String, text:String, ?done:Void->Void, ?failed:String->Void) and LoadSavedFileTextAsync(fileName:String, loaded:String->Void, ?failed:String->Void)";
	static inline final IS_FULLSCREEN = "IsWindowFullscreen()";
	static inline final FULLSCREEN = "ToggleFullscreen()";

	/** What a warning naming a call adds, after the call. */
	static final NOTES:Map<String, String> = [
		SAVE => "The save file persists between runs, including both native and web builds."
	];

	/** The fields that reach the host, by their owner's path and their name, and what answers each. */
	static final FIELDS:Map<String, String> = [
		"js.Browser.getLocalStorage" => SAVE,
		"js.Browser.getSessionStorage" => SAVE,
		"js.html.Window.localStorage" => SAVE,
		"js.html.Window.sessionStorage" => SAVE,
		"js.html.Window.indexedDB" => SAVE,
		"js.html.Document.fullscreenElement" => IS_FULLSCREEN,
		"js.html.Element.requestFullscreen" => FULLSCREEN,
		"js.html.Document.exitFullscreen" => FULLSCREEN
	];

	/** Text that reaches the host in a `js.Syntax.code` string, and what answers each. */
	static final SCRIPT:Array<{pattern:EReg, call:String}> = [
		{pattern: ~/\b(localStorage|sessionStorage|indexedDB)\b/, call: SAVE},
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
						for (call in [for (s2 in SCRIPT) if (s2.pattern.match(s)) s2.call])
							warn("js.Syntax.code", call, e.pos);
						for (i in 1...args.length)
							walk(args[i], site);
						return;
					case _:
				}
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
			case _:
		}
		TypedExprTools.iter(e, inner -> walk(inner, site));
	}

	// Warns at a site in the program's own code, as a refusal reads: what was reached, the one target it works on, and the call to use
	// instead. One inlined from a library's isn't the program's.
	static function warn(reached:String, call:String, pos:Position):Void {
		if (!own(pos))
			return;
		var note = NOTES.exists(call) ? " " + NOTES.get(call) : "";
		Context.warning('$reached: Works only in a browser. See $call.$note', pos);
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
