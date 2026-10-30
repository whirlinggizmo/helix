package helix.ray.internal;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;

/** Lets a program keep raylib's own shape, `while (!WindowShouldClose()) { ... }`, on every target.

	A page can't block, so the loop's body becomes a function called once a frame, and what follows the loop runs when it stops. The
	program's `main` runs once its saves are read, when it uses them (`Runtime.boot`). Natively the program finds its files at
	`-D helix-ray-native-root=<directory>` (default `../web`), relative to its own; a program reads them through the `...Async` loads. */
class Loop {
	/** Adds `build` to the program's main class, and `Unimplemented`'s to `Raylib`. Run by the library's `extraParams.hxml`. */
	public static function install():Void {
		var main = Compiler.getConfiguration().mainClass;
		if (main == null)
			return;
		var name = main.pack.concat([main.name]).join(".");
		Compiler.addMetadata("@:build(helix.ray.internal.Loop.build())", name);
		Unimplemented.install();
	}

	/** Rewrites the main class: the loop in whichever static function holds it, and `main` to run once the saves are read. */
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		for (field in fields)
			switch field.kind {
				case FFun(f) if (f.expr != null):
					f.expr = rewriteLoop(f.expr);
				case _:
			}
		var root = Context.definedValue("helix-ray-native-root");
		if (root == null)
			root = "../web";
		// The saves are read before main when the program names a function that reads or writes them, so a saved file answers at once.
		var sources = Path.directory(Context.getPosInfos(Context.getLocalClass().get().pos).file);
		var text = sourceText(sources == "" ? "." : sources);
		var preloads = [];
		if (~/\b(SaveFileText|LoadFileText|LoadFileTextAsync|FileExists|SaveFileData|LoadFileDataAsync)\b/.match(text))
			preloads.push(macro helix.ray.internal.Runtime.preloadSaves());
		for (field in fields)
			if (field.name == "main")
				switch field.kind {
					case FFun(f) if (f.expr != null):
						var body = f.expr;
						f.expr = macro {
							helix.ray.internal.Runtime.root = $v{root};
							helix.ray.internal.Runtime.boot([$a{preloads}], () -> $body);
						};
					case _:
				}
		return fields;
	}

	// The program's sources, under the main class's directory, as one text.
	static function sourceText(dir:String):String {
		var out = new StringBuf();
		for (entry in FileSystem.readDirectory(dir)) {
			var path = Path.join([dir, entry]);
			if (FileSystem.isDirectory(path))
				out.add(sourceText(path));
			else if (StringTools.endsWith(entry, ".hx"))
				out.add(sys.io.File.getContent(path));
		}
		return out.toString();
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
