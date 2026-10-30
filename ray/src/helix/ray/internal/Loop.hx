package helix.ray.internal;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

/** Lets a program keep raylib's own shape, `while (!WindowShouldClose()) { ... }`, on every target.

	A page can't block, so the loop's body becomes a function called once a frame, and what follows the loop runs when it stops. The
	program's `main` runs once its files are loaded (`Runtime.boot`). The files are those under `-D ray-files=<directory>` (default `web`),
	the directory the program's paths are relative to as it builds; natively the program finds them at `-D ray-native-root=<directory>`
	(default `../web`), relative to its own. */
class Loop {
	/** Adds `build` to the program's main class. Run by the library's `extraParams.hxml`. */
	public static function install():Void {
		var main = Compiler.getConfiguration().mainClass;
		if (main == null)
			return;
		var name = main.pack.concat([main.name]).join(".");
		Compiler.addMetadata("@:build(helix.ray.internal.Loop.build())", name);
	}

	/** Rewrites the main class: the loop in whichever static function holds it, and `main` to run once the files are loaded. */
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		for (field in fields)
			switch field.kind {
				case FFun(f) if (f.expr != null):
					f.expr = rewriteLoop(f.expr);
				case _:
			}
		var files = Context.definedValue("ray-files");
		if (files == null)
			files = "web";
		var root = Context.definedValue("ray-native-root");
		if (root == null)
			root = "../web";
		var paths = [];
		if (FileSystem.exists(files))
			list(files, "", paths);
		paths.sort(Reflect.compare);
		// Only what the program uses is read before main, and linked: its files when it has any, the saves when its code names the
		// functions that read or write them.
		var preloads = [];
		if (paths.length > 0)
			preloads.push(macro helix.ray.internal.Runtime.preloadFiles($v{paths}, $v{root}));
		if (namesSaves(Path.directory(Context.getPosInfos(Context.getLocalClass().get().pos).file)))
			preloads.push(macro helix.ray.internal.Runtime.preloadSaves());
		for (field in fields)
			if (field.name == "main")
				switch field.kind {
					case FFun(f) if (f.expr != null):
						var body = f.expr;
						f.expr = macro helix.ray.internal.Runtime.boot([$a{preloads}], () -> $body);
					case _:
				}
		return fields;
	}

	// Whether the program's sources, under the main class's directory, name a function that reads or writes the saves.
	static function namesSaves(dir:String):Bool {
		if (dir == "")
			dir = ".";
		for (entry in FileSystem.readDirectory(dir)) {
			var path = Path.join([dir, entry]);
			if (FileSystem.isDirectory(path)) {
				if (namesSaves(path))
					return true;
			} else if (StringTools.endsWith(entry, ".hx")
				&& ~/\b(SaveFileText|LoadFileText|FileExists)\b/.match(sys.io.File.getContent(path)))
				return true;
		}
		return false;
	}

	// The files under a directory, as paths relative to it, leaving out the page's own.
	static function list(base:String, relative:String, out:Array<String>):Void {
		var dir = relative == "" ? base : Path.join([base, relative]);
		for (entry in FileSystem.readDirectory(dir)) {
			var path = relative == "" ? entry : relative + "/" + entry;
			if (FileSystem.isDirectory(Path.join([base, path])))
				list(base, path, out);
			else if (!~/\.(html|js|map)$/i.match(entry))
				out.push(path);
		}
	}

	// Finds `while (!WindowShouldClose()) body` among a block's statements, and hands the body and the statements after it to Runtime.run.
	static function rewriteLoop(e:Expr):Expr {
		switch e.expr {
			case EBlock(statements):
				for (i in 0...statements.length)
					switch statements[i].expr {
						case EWhile(condition, body, true) if (isShouldClose(condition)):
							var before = statements.slice(0, i);
							var after = statements.slice(i + 1);
							var frame = frameBody(body);
							before.push(macro helix.ray.internal.Runtime.run(() -> $frame, () -> $b{after}));
							return {expr: EBlock(before), pos: e.pos};
						case _:
					}
				return e;
			case _:
				return e;
		}
	}

	static function isShouldClose(condition:Expr):Bool {
		return switch condition.expr {
			case EParenthesis(inner): isShouldClose(inner);
			case EUnop(OpNot, false, {expr: ECall({expr: EField(_, "WindowShouldClose")}, [])}): true;
			case EUnop(OpNot, false, {expr: ECall({expr: EConst(CIdent("WindowShouldClose"))}, [])}): true;
			case _: false;
		}
	}

	// The loop's body as a frame: `continue` ends the frame, and `break` ends the loop, outside any loop of its own.
	static function frameBody(body:Expr):Expr {
		function map(e:Expr):Expr {
			return switch e.expr {
				case EContinue: macro return;
				case EBreak: macro {
						helix.ray.internal.Runtime.shouldClose = true;
						return;
					};
				case EWhile(_, _, _) | EFor(_, _) | EFunction(_, _): e;
				case _: haxe.macro.ExprTools.map(e, map);
			}
		}
		return map(body);
	}
}
#end
