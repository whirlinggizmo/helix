package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;

/** Refuses on every target the `Sys` calls a page can't answer, so a program that builds natively builds for the page. A page's `Sys`
	is the library's `Sys.js.hx`, which Haxe takes in place of its own when compiling for JS. Run by the library's `extraParams.hxml`. */
class SysCalls {
	/** Adds the refusal of the calls a page can't answer to every build. */
	public static function register():Void {
		Context.onAfterTyping(refuse);
	}

	// Each refused call, with what to do instead.
	static final REFUSED = [
		"putEnv" => "The environment can't be changed.",
		"sleep" => "Use WaitTime, or count frames in the program's loop.",
		"getCwd" => "Files are named relative to the program.",
		"setCwd" => "Files are named relative to the program.",
		"systemName" => "The program runs the same everywhere.",
		"command" => "Other programs can't be run.",
		"exit" => "End the program's loop, and what follows it runs.",
		"executablePath" => "Files are named relative to the program.",
		"programPath" => "Files are named relative to the program.",
		"getChar" => "Read keys with IsKeyPressed and GetCharPressed.",
		"stdin" => "Read keys with IsKeyPressed and GetCharPressed.",
		"stdout" => "Write with Sys.println or TraceLog.",
		"stderr" => "Write with Sys.println or TraceLog."
	];

	// Refuses a call of a refused Sys function in the program's classes; the libraries' own (package helix, Haxe's standard library) are
	// left alone.
	static function refuse(types:Array<ModuleType>):Void {
		for (type in types)
			switch type {
				case TClassDecl(ref):
					var c = ref.get();
					if (c.isExtern || c.name == "Sys" || (c.pack.length > 0 && LIBRARY_PACKAGES.indexOf(c.pack[0]) >= 0))
						continue;
					for (field in c.statics.get().concat(c.fields.get()).concat(c.constructor == null ? [] : [c.constructor.get()]))
						switch field.expr() {
							case null:
							case body:
								search(body);
						}
				case _:
			}
	}

	static final LIBRARY_PACKAGES = [
		"helix", "haxe", "sys", "js", "cpp", "eval", "hl", "neko", "python", "lua", "php", "jvm", "java", "cs", "flash"
	];

	static function search(e:TypedExpr):Void {
		switch e.expr {
			case TField(_, FStatic(c, field)) if (c.get().name == "Sys" && c.get().pack.length == 0 && REFUSED.exists(field.get().name)):
				var name = field.get().name;
				Context.reportError('Sys.$name: Not supported. ${REFUSED[name]}', e.pos);
			case _:
				haxe.macro.TypedExprTools.iter(e, search);
		}
	}
}
#end
