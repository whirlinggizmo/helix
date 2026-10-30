package helix.ray.internal;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

/** Lets a program keep raylib's own shape, `while (!WindowShouldClose()) { ... }`, on every target.

	A page can't block, so the loop's body becomes a function called once a frame, and what follows the loop runs when it stops. The
	program's `main` runs once the system is made (`Runtime.boot`). Natively the program finds its files at
	`-D helix-ray-native-root=<directory>` (default `../web`), relative to its own; a program reads them through the `...Async` loads. */
class Loop {
	/** Adds `build` to the program's main class. Run by the library's `extraParams.hxml`. */
	public static function install():Void {
		var main = Compiler.getConfiguration().mainClass;
		if (main == null)
			return;
		var name = main.pack.concat([main.name]).join(".");
		Compiler.addMetadata("@:build(helix.ray.internal.Loop.build())", name);
	}

	/** Rewrites the main class: the loop in whichever static function holds it, and `main` to run once the system is made. */
	public static function build():Array<Field> {
		var fields = Context.getBuildFields();
		for (field in fields)
			switch field.kind {
				case FFun(f) if (f.expr != null):
					f.expr = rewriteLoop(f.expr);
				case _:
			}
		var root = Context.definedValue("helix-ray-native-root");
		if (root == null)
			root = "../web";
		for (field in fields)
			if (field.name == "main")
				switch field.kind {
					case FFun(f) if (f.expr != null):
						var body = f.expr;
						f.expr = macro {
							helix.ray.internal.Runtime.root = $v{root};
							helix.ray.internal.Runtime.boot(() -> $body);
						};
					case _:
				}
		return fields;
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
