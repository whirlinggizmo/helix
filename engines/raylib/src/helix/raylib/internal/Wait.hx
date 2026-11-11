package helix.raylib.internal;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypedExprTools;
using haxe.macro.ExprTools;
#end

/** Lets a program call what a page has to wait for (`EndDrawing`, `LoadTexture`) as raylib's programs do, in any function.

	A waiting call is marked where it expands (`call`). In a page, each function of the program whose body holds one, or calls a
	function of the program's that does, becomes an async function, and each call of it is awaited. Natively a waiting call blocks, and
	nothing is rewritten. On every target, a waiting call in a function used as a value doesn't compile. */
@:noCompletion
class Wait {
	#if macro
	// The metadata of a function that waits (Runtime's): a call of one marks a waiting call's expansion.
	static inline final META = ":helix.raylib.waits";

	// Each waiting call's message refusing it in a function used as a value, by the call's position.
	static final refusals:Map<String, String> = [];

	// Each function of the program's, by its field's position: what its body calls, and whether it waits.
	static final states:Map<String, State> = [];

	// Each function's declared return type, by its field's position, for the async function wrapping its body.
	static final returns:Map<String, Null<ComplexType>> = [];

	// The program's classes, each named by its module and its name: those `build` was added to.
	static final built:Map<String, Bool> = [];

	/** Adds `build` to the program's classes: every module in a class path that isn't Haxe's own or a library's (package helix). Run
		by the library's `extraParams.hxml`. */
	public static function install():Void {
		var std = sys.FileSystem.absolutePath(haxe.io.Path.directory(Context.resolvePath("StdTypes.hx")));
		var added:Map<String, Bool> = [];
		for (path in Context.getClassPath()) {
			var directory = path == "" ? "." : path;
			if (!sys.FileSystem.exists(directory) || !sys.FileSystem.isDirectory(directory)
				|| StringTools.startsWith(sys.FileSystem.absolutePath(directory), std))
				continue;
			for (entry in sys.FileSystem.readDirectory(directory)) {
				var name = StringTools.endsWith(entry, ".hx") ? entry.substr(0, entry.length - 3) : entry;
				if (name == "helix" || name == "haxe" || name == "import" || added.exists(name) || !~/^[A-Za-z_][A-Za-z0-9_]*$/.match(name))
					continue;
				added.set(name, true);
				Compiler.addGlobalMetadata(name, "@:build(helix.raylib.internal.Wait.build())", true, true, false);
			}
		}
	}

	static function id(c:ClassType):String {
		return c.module + "." + c.name;
	}

	// Whether a class is the program's.
	static function program(c:ClassType):Bool {
		return built.exists(id(c));
	}

	/** Wraps each function body of a class of the program's in `body`, and `main` to run once the system is made. */
	public static function build():Null<Array<Field>> {
		var local = Context.getLocalClass();
		if (local == null || local.get().isExtern || local.get().isInterface)
			return null;
		built.set(id(local.get()), true);
		var fields = Context.getBuildFields();
		var main = Compiler.getConfiguration().mainClass;
		var isMain = main != null && main.pack.concat([main.name]).join(".") == local.toString();
		for (field in fields)
			switch field.kind {
				case FFun(f) if (f.expr != null && field.access.indexOf(AMacro) < 0):
					var key = Std.string(field.pos);
					returns.set(key, f.ret);
					// An inline function's body would be copied into its callers, async function and all.
					if (Context.defined("js") && field.access.indexOf(AExtern) < 0)
						field.access.remove(AInline);
					var body = f.expr;
					var wrapped = macro @:pos(body.pos) helix.raylib.internal.Wait.body($body, $v{key}, $v{field.name == "new"});
					if (isMain && field.name == "main") {
						var root = Context.definedValue("helix-raylib-native-root");
						if (root == null)
							root = "../web";
						wrapped = macro {
							helix.raylib.internal.Runtime.root = $v{root};
							helix.raylib.internal.Runtime.boot(function() $wrapped);
						};
					}
					f.expr = wrapped;
				case FVar(t, e) if (checked(field, e)):
					field.kind = FVar(t, value(e, t));
				case FProp(get, set, t, e) if (checked(field, e)):
					field.kind = FProp(get, set, t, value(e, t));
				case _:
			}
		return fields;
	}

	// Whether a variable's initial value is checked: one that could hold a call.
	static function checked(field:Field, e:Null<Expr>):Bool {
		return e != null && !e.expr.match(EConst(_)) && field.access.indexOf(AInline) < 0 && !Context.getLocalClass().get().kind.match(KAbstractImpl(_));
	}

	static function value(e:Expr, t:Null<ComplexType>):Expr {
		return macro @:pos(e.pos) helix.raylib.internal.Wait.body(${t == null ? e : macro @:pos(e.pos) ($e : $t)}, $v{Std.string(e.pos)}, true);
	}

	/** Returns a call of a function that waits (Runtime's, marked with the metadata), placed at the program's call being expanded, so
		that call is known as a waiting call.

		@param refusal  The message refusing the program's call in a function used as a value.
		@param waiting  The call of the function that waits.
		@return  The call, placed. */
	public static function call(refusal:String, waiting:Expr):Expr {
		refusals.set(Std.string(Context.currentPos()), refusal);
		return {expr: waiting.expr, pos: Context.currentPos()};
	}

	/** Returns `EndDrawing`'s expansion: natively the frame's end, which waits out the frame; in a page the frame shown, the wait for
		the browser's next frame, then the frame counted and the next one's input read.

		@param refusal  The message refusing the call in a function used as a value.
		@return  The expansion. */
	public static function frame(refusal:String):Expr {
		if (!Context.defined("js"))
			return call(refusal, macro helix.raylib.internal.Runtime.endFrame());
		var wait = call(refusal, macro helix.raylib.internal.Runtime.frameWait());
		return macro {
			helix.raylib.internal.Runtime.showFrame();
			helix.raylib.internal.Await.promised($wait);
			helix.raylib.internal.Runtime.countFrame();
		};
	}

	/** Returns a load's expansion, whose value is the answer: natively a call that returns once the answer came; in a page a wait for
		the answer.

		@param refusal  The message refusing the call in a function used as a value.
		@param ask  A function asking, given what to call with the answer.
		@return  The expansion. */
	public static function answer(refusal:String, ask:Expr):Expr {
		var wait = call(refusal, macro helix.raylib.internal.Runtime.answered($ask));
		return Context.defined("js") ? macro helix.raylib.internal.Await.promised($wait) : wait;
	}

	// A function of the program's that an access names, or null.
	static function method(access:FieldAccess):Null<{key:String, field:ClassField}> {
		var found = switch access {
			case FStatic(c, cf) | FInstance(c, _, cf) | FClosure({c: c}, cf): {c: c.get(), field: cf.get()};
			case _: null;
		}
		if (found == null || !found.field.kind.match(FMethod(_)) || !program(found.c))
			return null;
		return {key: Std.string(found.field.pos), field: found.field};
	}

	// Whether a function waits: its body holds a waiting call, or calls a function that does. A function still being decided (it called
	// its way here) is searched through what its body calls, so functions calling each other decide alike.
	static function reaches(key:String, field:ClassField, visited:Map<String, Bool>, asked:State, pos:Position):Bool {
		var state = states.get(key);
		if (state == null) {
			// Types the function's body now, which runs its own `body`.
			field.expr();
			state = states.get(key);
			if (state == null)
				return false;
		}
		if (state.decided)
			return state.waits;
		if (visited.exists(key))
			return false;
		visited.set(key, true);
		if (state.calls == null) {
			// Its body is still being typed (it has no return type, and typing a call of it brought the compiler here): taken as not
			// waiting, and refused should it turn out to.
			state.assumed.push({by: asked, pos: pos});
			return false;
		}
		if (state.direct)
			return true;
		for (c in state.calls)
			if (reaches(c.key, c.field, visited, asked, pos))
				return true;
		return false;
	}

	// Refuses a waiting method that an interface declares, or that overrides one that doesn't wait: a call through the interface or
	// the class above wouldn't wait for it.
	static function refuseInherited(key:String, state:State):Void {
		var name = Context.getLocalMethod();
		var c = Context.getLocalClass().get();
		if (Lambda.exists(c.statics.get(), f -> f.name == name))
			return;
		function declared(interfaces:Array<{t:Ref<ClassType>, params:Array<Type>}>):Void {
			for (i in interfaces) {
				var type = i.t.get();
				if (Lambda.exists(type.fields.get(), f -> f.name == name))
					Context.error('$name waits (it reaches EndDrawing() or a load): not in a function ${type.name} declares', Context.currentPos());
				declared(type.interfaces);
			}
		}
		declared(c.interfaces);
		var above = c.superClass;
		while (above != null) {
			var type = above.t.get();
			declared(type.interfaces);
			for (f in type.fields.get())
				if (f.name == name && !reaches(Std.string(f.pos), f, [key => true], state, Context.currentPos()))
					Context.error('$name waits (it reaches EndDrawing() or a load): not in an override of a function that doesn\'t', Context.currentPos());
			above = type.superClass;
		}
	}

	static function isVoid(t:Type):Bool {
		return switch Context.follow(t) {
			case TAbstract(a, _): a.toString() == "Void";
			case _: false;
		}
	}

	// Whether a function's body returns a value, outside any function of its own.
	static function returnsValue(e:Expr):Bool {
		var found = false;
		function search(e:Expr):Void {
			switch e.expr {
				case EReturn(value) if (value != null):
					found = true;
				case EFunction(_, _):
				case _:
					e.iter(search);
			}
		}
		search(e);
		return found;
	}
	#end

	/** A function's body: checked for waiting calls and, in a page, made an async function when it waits, its waiting calls awaited.

		@param e  The body.
		@param key  The function's field's position.
		@param constructor  Whether the body is a constructor's or a variable's initial value, which can't wait.
		@return  The body. */
	public static macro function body(e:Expr, key:String, constructor:Bool):Expr {
		var state = new State();
		states.set(key, state);
		// A function's body is typed as a statement, as Haxe types one: a value after it keeps the body from being the block's value.
		var typed = if (returns.exists(key)) switch Context.typeExpr(macro @:pos(e.pos) {
			$e;
			0;
		}).expr {
			case TBlock([statement, _]): statement;
			case _: throw "a block of two";
		} else Context.typeExpr(e);
		var calls:Array<Call> = [];
		var direct = false;
		function walk(t:TypedExpr, lambda:Bool):Void {
			switch t.expr {
				case TCall({expr: TField(_, FStatic(_, cf))}, args) if (cf.get().meta.has(META)):
					var refusal = refusals.get(Std.string(t.pos));
					if (refusal == null)
						refusal = cf.get().name;
					if (lambda)
						Context.error(refusal, t.pos);
					if (constructor)
						Context.error(refusal.split(":")[0] + ": not in a constructor or a variable's initial value", t.pos);
					direct = true;
					for (a in args)
						walk(a, lambda);
				case TFunction(f):
					walk(f.expr, true);
				case TCall({expr: TField(target, access)}, args):
					switch method(access) {
						case null:
						case m:
							calls.push({
								key: m.key,
								field: m.field,
								pos: t.pos,
								kind: lambda ? InLambda : Called,
								isVoid: isVoid(t.t)
							});
					}
					walk(target, lambda);
					for (a in args)
						walk(a, lambda);
				case TField(target, access):
					switch method(access) {
						case null:
						case m:
							calls.push({
								key: m.key,
								field: m.field,
								pos: t.pos,
								kind: AsValue,
								isVoid: false
							});
					}
					walk(target, lambda);
				case _:
					t.iter(walk.bind(_, lambda));
			}
		}
		walk(typed, false);
		state.calls = calls;
		state.direct = direct;
		function awaited():Array<Call> {
			var found = [];
			for (c in calls)
				if (reaches(c.key, c.field, [key => true], state, c.pos)) {
					switch c.kind {
						case Called if (!constructor):
							found.push(c);
						case Called:
							Context.error('${c.field.name}() waits (it reaches EndDrawing() or a load): not in a constructor or a variable\'s initial value', c.pos);
						case InLambda:
							Context.error('${c.field.name}() waits (it reaches EndDrawing() or a load): call it from a function of a class, not from a function used as a value',
								c.pos);
						case AsValue:
							Context.error('${c.field.name} waits (it reaches EndDrawing() or a load): call it, don\'t use it as a value', c.pos);
					}
				}
			return found;
		}
		var awaits = awaited();
		state.waits = direct || awaits.length > 0;
		state.decided = true;
		// A function calling itself, or one that called its way here, waits when this one does.
		if (state.waits)
			awaits = awaited();
		if (state.waits)
			for (a in state.assumed)
				if (!a.by.waits)
					Context.error("A function calling this one was decided before this one's return type was: write this function's return type",
						Context.currentPos());
		if (state.waits)
			refuseInherited(key, state);
		if (!state.waits || !Context.defined("js"))
			return Context.storeTypedExpr(typed);
		var used = [for (_ in awaits) false];
		function rewrite(x:Expr):Expr {
			switch x.expr {
				case EConst(CString(text, SingleQuotes)):
					// A call in a string's `${}` is an expression once the string is one.
					var p = Context.getPosInfos(x.pos);
					for (a in awaits) {
						var at = Context.getPosInfos(a.pos);
						if (at.file == p.file && at.min >= p.min && at.max <= p.max)
							return rewrite(haxe.macro.MacroStringTools.formatString(text, x.pos));
					}
				case _:
			}
			var inner = x.map(rewrite);
			switch x.expr {
				case ECall(_, _):
					var p = Context.getPosInfos(x.pos);
					for (i in 0...awaits.length) {
						var at = Context.getPosInfos(awaits[i].pos);
						if (at.min == p.min && at.max == p.max && at.file == p.file) {
							used[i] = true;
							return awaits[i].isVoid ? macro @:pos(x.pos) js.Syntax.code("(await {0})", untyped $inner) : macro @:pos(x.pos) helix.raylib.internal.Await.value($inner);
						}
					}
				case _:
			}
			return inner;
		}
		var inner = rewrite(e);
		for (i in 0...awaits.length)
			if (!used[i])
				Context.error('${awaits[i].field.name} waits (it reaches EndDrawing() or a load): call it by its name, as a statement or a value',
					awaits[i].pos);
		var ret = returns.get(key);
		var isVoid = switch ret {
			case null: !returnsValue(e);
			case TPath({name: "Void", pack: []}): true;
			case _: false;
		}
		var f:Expr = {expr: EFunction(FAnonymous, {args: [], ret: ret, expr: inner}), pos: e.pos};
		return isVoid ? macro js.Syntax.code("return (async {0})()", $f) : macro return cast js.Syntax.code("(async {0})()", $f);
	}
}

#if macro
private class State {
	public var calls:Null<Array<Call>> = null;
	public var direct = false;
	public var decided = false;
	public var waits = false;
	public final assumed:Array<{by:State, pos:Position}> = [];

	public function new() {}
}

private enum CallKind {
	Called;
	InLambda;
	AsValue;
}

private typedef Call = {
	key:String,
	field:ClassField,
	pos:Position,
	kind:CallKind,
	isVoid:Bool
}
#end
