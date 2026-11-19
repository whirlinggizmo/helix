package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr.Position;
import haxe.macro.Type;
import sys.FileSystem;

using StringTools;
#end

/** Finds the program's own code among the compiler's typed code, for the checks that look at it after typing (`HostReach`,
	`ObjectCasts`). Libraries' code and the standard library's aren't the program's. */
@:noCompletion
class ProgramCode {
	#if macro
	static var libraries:Array<String>;
	static final files = new Map<String, Bool>();

	/** Returns the code of each class of the program's among `types`: each field's, its constructor's and its static initialization's.
		An extern class has none.

		@param types  The types `Context.onAfterTyping` provides. */
	public static function bodies(types:Array<ModuleType>):Array<TypedExpr> {
		var out = [];
		for (type in types) {
			var c = switch type {
				case TClassDecl(_.get() => c): c;
				case TAbstract(_.get() => a) if (a.impl != null): a.impl.get();
				case _: null;
			}
			if (c == null || c.isExtern || !own(c.pos))
				continue;
			var fields = c.statics.get().concat(c.fields.get());
			if (c.constructor != null)
				fields.push(c.constructor.get());
			for (f in fields) {
				var e = f.expr();
				if (e != null)
					out.push(e);
			}
			if (c.init != null)
				out.push(c.init);
		}
		return out;
	}

	/** Returns whether a position is in the program's own code: in a file under none of the libraries' class paths.

		@param pos  The position. */
	public static function own(pos:Position):Bool {
		if (libraries == null)
			libraries = libraryPaths();
		var file = Context.getPosInfos(pos).file;
		var known = files.get(file);
		if (known == null) {
			var full = try FileSystem.fullPath(file) catch (_:Dynamic) null;
			known = full != null && FileSystem.exists(full) && !Lambda.exists(libraries, l -> full.startsWith(l));
			files.set(file, known);
		}
		return known;
	}

	// The class paths that are libraries' (a haxelib library's: its haxelib.json there, or a directory up naming it as its classPath, so
	// a library's tests beside it are a program's) or the standard library's (StdTypes.hx there, or one or two directories up, as
	// std/js/_std is), each a full path ending in a separator.
	static function libraryPaths():Array<String> {
		var out = [];
		for (cp in Context.getClassPath()) {
			var full = try FileSystem.fullPath(cp == "" ? "." : cp) catch (_:Dynamic) null;
			if (full == null || !FileSystem.isDirectory(full))
				continue;
			full = haxe.io.Path.addTrailingSlash(haxe.io.Path.normalize(full));
			var up = full + "../", upTwo = full + "../../";
			if (FileSystem.exists(full + "haxelib.json")
				|| classPathOf(up) == full
				|| FileSystem.exists(full + "StdTypes.hx")
				|| FileSystem.exists(up + "StdTypes.hx")
				|| FileSystem.exists(upTwo + "StdTypes.hx"))
				out.push(full);
		}
		return out;
	}

	// The class path a haxelib.json in a directory names, as a full path ending in a separator, or null without one.
	static function classPathOf(directory:String):Null<String> {
		var json = directory + "haxelib.json";
		if (!FileSystem.exists(json))
			return null;
		var declared:Null<String> = try haxe.Json.parse(sys.io.File.getContent(json)).classPath catch (_:Dynamic) null;
		var full = try FileSystem.fullPath(directory + (declared == null ? "" : declared)) catch (_:Dynamic) null;
		return full == null ? null : haxe.io.Path.addTrailingSlash(haxe.io.Path.normalize(full));
	}
	#end
}
