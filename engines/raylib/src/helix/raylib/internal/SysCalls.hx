package helix.raylib.internal;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;

/** With `-D helix-raylib-portable-sys`, gives a page a `Sys` and holds a program to what a page can answer: the `Sys` calls a page has
	no answer for, Haxe's file calls (`sys.io.File`, `sys.FileSystem`) and `sys.io.Process` are refused on every target, each refusal
	naming the raylib call to use, so a program that builds natively builds for the page. A page's `Sys` is the library's
	`_std/Sys.js.hx` (the program's options from the URL's query, the console and the clock), put on the class path for JS, where Haxe
	has none. For JS the `sys` package is allowed, so a program naming it gets the refusal; any other part of it is refused there too.
	Without the define a build is Haxe's as shipped. Run by the library's `extraParams.hxml`. */
class SysCalls {
	/** Adds a page's `Sys` and the refusals to a build with `-D helix-raylib-portable-sys`. */
	public static function register():Void {
		if (!Context.defined("helix-raylib-portable-sys"))
			return;
		if (Context.defined("js")) {
			// The library's _std/, beside its src/.
			var here = haxe.io.Path.directory(Context.resolvePath("helix/raylib/internal/SysCalls.hx"));
			Compiler.addClassPath(haxe.io.Path.normalize(here + "/../../../../_std"));
			Compiler.allowPackage("sys");
		}
		Context.onAfterTyping(refuse);
	}

	// Each refused Sys call, with what to do instead.
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

	static inline final LOAD_TEXT = "Use LoadFileText(fileName:String):Null<String> instead.";
	static inline final LOAD_DATA = "Use LoadFileData(fileName:String):Null<haxe.io.Bytes> instead.";
	static inline final SAVE_TEXT = "Use SaveFileText(fileName:String, text:String):Bool instead.";
	static inline final SAVE_DATA = "Use SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int):Bool instead.";
	static inline final SAVE_OVER = "A file can't be removed or renamed. Save over it with SaveFileText(fileName:String, text:String):Bool or SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int):Bool.";

	// Each refused sys.io.File call, with what to do instead.
	static final FILE = [
		"getContent" => LOAD_TEXT,
		"getBytes" => LOAD_DATA,
		"read" => LOAD_DATA,
		"saveContent" => SAVE_TEXT,
		"saveBytes" => SAVE_DATA,
		"write" => SAVE_DATA,
		"update" => SAVE_DATA,
		"append" =>
		"A file is written whole. Load it with LoadFileData(fileName:String):Null<haxe.io.Bytes>, add to it, and save it with SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int):Bool.",
		"copy" =>
		"Load the file with LoadFileData(fileName:String):Null<haxe.io.Bytes> and save the copy with SaveFileData(fileName:String, data:haxe.io.Bytes, dataSize:Int):Bool."
	];

	// Each refused sys.FileSystem call, with what to do instead.
	static final FILE_SYSTEM = [
		"exists" => "Use FileExists(fileName:String):Bool instead.",
		"isDirectory" => "Use DirectoryExists(dirPath:String):Bool instead.",
		"readDirectory" => "Use LoadDirectoryFiles(dirPath:String):FilePathList instead.",
		"createDirectory" => "Directories are made by raylib. See MakeDirectory(dirPath:String):Int.",
		"stat" => "Use GetFileLength(fileName:String):Int and GetFileModTime(fileName:String):Int instead.",
		"fullPath" => "Files are named relative to the program.",
		"absolutePath" => "Files are named relative to the program.",
		"deleteFile" => SAVE_OVER,
		"deleteDirectory" => SAVE_OVER,
		"rename" => SAVE_OVER
	];

	// Refuses a refused call in the program's classes; the libraries' own (package helix, Haxe's standard library) are left alone.
	static function refuse(types:Array<ModuleType>):Void {
		var js = Context.defined("js");
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
								search(body, js);
						}
				case _:
			}
	}

	static final LIBRARY_PACKAGES = [
		"helix", "haxe", "sys", "js", "cpp", "eval", "hl", "neko", "python", "lua", "php", "jvm", "java", "cs", "flash"
	];

	static function search(e:TypedExpr, js:Bool):Void {
		switch e.expr {
			case TField(_, FStatic(c, field)) if (c.get().name == "Sys" && c.get().pack.length == 0 && REFUSED.exists(field.get().name)):
				var name = field.get().name;
				Context.reportError('Sys.$name: Not supported. ${REFUSED[name]}', e.pos);
			case TField(_, FStatic(c, field)) if (path(c.get()) == "sys.io.File" && FILE.exists(field.get().name)):
				Context.reportError('sys.io.File.${field.get().name}: ${FILE[field.get().name]}', e.pos);
			case TField(_, FStatic(c, field)) if (path(c.get()) == "sys.FileSystem" && FILE_SYSTEM.exists(field.get().name)):
				Context.reportError('sys.FileSystem.${field.get().name}: ${FILE_SYSTEM[field.get().name]}', e.pos);
			case TNew(c, _, _) if (path(c.get()) == "sys.io.Process"):
				Context.reportError('sys.io.Process: Not supported. ${REFUSED["command"]}', e.pos);
			// For JS the rest of the sys package, which Haxe refused there before it was allowed.
			case TField(_, FStatic(c, _)) | TNew(c, _, _) if (js && c.get().pack[0] == "sys"):
				Context.reportError('${path(c.get())}: Not supported.', e.pos);
			case TTypeExpr(TClassDecl(c)) if (js && c.get().pack[0] == "sys"):
				Context.reportError('${path(c.get())}: Not supported.', e.pos);
			case _:
				haxe.macro.TypedExprTools.iter(e, search.bind(_, js));
		}
	}

	// A class's dotted path.
	static function path(c:ClassType):String
		return c.pack.concat([c.name]).join(".");
}
#end
