package helix.raylib.internal;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

/** Lets a program keep raylib's own shape, `while (!WindowShouldClose()) { ... }`, on every target: any `while` or `do`-`while` that
	calls `WindowShouldClose()` in its condition or its body, whatever else its condition holds.

	A page can't block, so the loop becomes a function called once a frame, its condition checked each frame as the loop would check
	it, and what follows the loop runs when it stops. A call of `WindowShouldClose()` in any other loop doesn't compile. The
	program's `main` runs once the system is made (`Runtime.boot`). Natively the program finds its files at
	`-D helix-raylib-native-root=<directory>` (default `../web`), relative to its own; a program reads them through the `...Async` loads. */
class Loop {
	/** Adds `build` to the program's main class. Run by the library's `extraParams.hxml`. */
	public static function install():Void {
		var main = Compiler.getConfiguration().mainClass;
		if (main == null)
			return;
		var name = main.pack.concat([main.name]).join(".");
		Compiler.addMetadata("@:build(helix.raylib.internal.Loop.build())", name);
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
		var root = Context.definedValue("helix-raylib-native-root");
		if (root == null)
			root = "../web";
		for (field in fields)
			if (field.name == "main")
				switch field.kind {
					case FFun(f) if (f.expr != null):
						var body = f.expr;
						f.expr = macro {
							helix.raylib.internal.Runtime.root = $v{root};
							helix.raylib.internal.Runtime.boot(() -> $body);
						};
					case _:
				}
		return fields;
	}

	// Finds the program's loop among a block's statements, a `while` or `do`-`while` that calls `WindowShouldClose()` in its condition or
	// in its body (outside a loop or function of its own), and hands it as a frame, with the statements after it, to Runtime.run. Any
	// other call of WindowShouldClose inside a loop is refused: a page couldn't run that loop.
	static function rewriteLoop(e:Expr):Expr {
		switch e.expr {
			case EBlock(statements):
				for (i in 0...statements.length)
					switch statements[i].expr {
						case EWhile(condition, body, normal) if (calls(condition) || calls(body)):
							refuseInner(body);
							var before = statements.slice(0, i);
							var after = statements.slice(i + 1);
							before.push(macro helix.raylib.internal.Runtime.run($e{frame(condition, body, normal)}, () -> $b{after}));
							refuseAfter(after);
							return {expr: EBlock(before), pos: e.pos};
						case _:
							refuseAfter([statements[i]]);
					}
				return e;
			case _:
				refuseAfter([e]);
				return e;
		}
	}

	// The loop as one frame: a `while` checks its condition first, ending the loop when it's false; a `do`-`while` runs its body first
	// and checks after, unless the body broke out.
	static function frame(condition:Expr, body:Expr, normal:Bool):Expr {
		var once = frameBody(body);
		var stop = macro helix.raylib.internal.Runtime.shouldClose = true;
		return normal ? macro() -> {
			if (!($condition)) {
				$stop;
				return;
			}
			$once;
		} : macro() -> {
			(() -> $once)();
			if (!helix.raylib.internal.Runtime.shouldClose && !($condition))
				$stop;
			};
	}

	// Whether an expression calls WindowShouldClose, outside a loop or function of its own.
	static function calls(e:Expr):Bool {
		var found = false;
		function search(e:Expr):Void {
			switch e.expr {
				case ECall({expr: EField(_, "WindowShouldClose") | EConst(CIdent("WindowShouldClose"))}, []):
					found = true;
				case EWhile(_, _, _) | EFor(_, _) | EFunction(_, _):
				case _:
					haxe.macro.ExprTools.iter(e, search);
			}
		}
		search(e);
		return found;
	}

	// Refuses a call of WindowShouldClose in a loop inside the program's loop, or in a loop of the code around it: neither is a loop a
	// page can run once a frame.
	static function refuseInner(body:Expr):Void {
		function search(e:Expr):Void {
			switch e.expr {
				case EWhile(_, _, _) | EFor(_, _):
					refuseAfter([e]);
				case EFunction(_, _):
				case _:
					haxe.macro.ExprTools.iter(e, search);
			}
		}
		search(body);
	}

	static function refuseAfter(statements:Array<Expr>):Void {
		function search(e:Expr):Void {
			switch e.expr {
				case EWhile(condition, body, _) if (calls(condition) || calls(body)):
					Context.error("helix-raylib: the program's loop, the `while` or `do`-`while` that calls WindowShouldClose(), must be a statement of "
						+ "a function's own block in the main class, not inside another loop or block; a page runs it once a frame",
						e.pos);
				case EFor(_, body) if (calls(body)):
					Context.error("helix-raylib: the program's loop is a `while` or `do`-`while` that calls WindowShouldClose(), not a `for`", e.pos);
				case EFunction(_, _):
				case _:
					haxe.macro.ExprTools.iter(e, search);
			}
		}
		for (statement in statements)
			search(statement);
	}

	// The loop's body as a frame: `continue` ends the frame, and `break` ends the loop, outside any loop of its own.
	static function frameBody(body:Expr):Expr {
		function map(e:Expr):Expr {
			return switch e.expr {
				case EContinue: macro return;
				case EBreak: macro {
						helix.raylib.internal.Runtime.shouldClose = true;
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
