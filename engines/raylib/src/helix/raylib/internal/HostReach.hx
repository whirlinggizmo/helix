package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;
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

	/** Looks at the program's code once it is typed. */
	public static function register():Void {
		if (!Context.defined("helix-raylib-host-warnings"))
			return;
		Context.onAfterTyping(types -> {
			if (done)
				return;
			done = true;
			for (e in ProgramCode.bodies(types))
				walk(e, e.pos);
		});
	}

	// Looks at an expression and those in it; site is where the nearest of them in the program's own code is, where a shortcut the
	// standard library inlines (js.Browser.location) is reported.
	static function walk(e:TypedExpr, site:Position):Void {
		if (ProgramCode.own(e.pos))
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
		if (!ProgramCode.own(pos))
			return;
		var note = NOTES.exists(call) ? " " + NOTES.get(call) : "";
		Context.warning('$reached: Works only in a browser. See $call.$note', pos);
	}

	static function path(c:ClassType):String
		return c.pack.concat([c.name]).join(".");
	#end
}
