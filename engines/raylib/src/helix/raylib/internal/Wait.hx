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
	function of the program's that does, becomes an async function, and each call of it is awaited. A function declared in one becomes
	an async function too, when it is only ever called by its name. A function calling one whose body isn't typed yet has both bodies,
	the one run chosen as the page starts (`resolve`). A call of `super`'s function, and a read or a write of `super`'s property,
	goes through a function of the class's own (`forward`). Natively a waiting call blocks, and nothing is rewritten. On every target, a
	waiting call in a function used as a value doesn't compile. */
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

	static inline final NO = 0;
	static inline final YES = 1;
	static inline final UNKNOWN = 2;

	// The class a page's undecided functions read whether they wait from, one value each.
	static inline final FLAGS = "HelixRaylibWaits";

	// What starts the name of a function of a class calling `super`'s function of the name after it.
	static inline final SUPER = "__super_";

	// The functions decided once every body is typed (`resolve`), and their calls refused then should the function called wait.
	static final undecided:Array<State> = [];
	static final late:Array<{by:State, call:Call}> = [];
	static final refused:Map<String, Bool> = [];
	static final refusing:Array<{message:String, pos:Position}> = [];
	static var flags = 0;
	static var hooked = false;
	static var resolved = false;

	// The program's classes, each named by its module and its name: those `build` was added to.
	static final built:Map<String, Bool> = [];

	/** Adds `build` to the program's classes: every module in a class path that isn't Haxe's own or a library's (package helix). Run
		by the library's `extraParams.hxml`. */
	public static function install():Void {
		var std = sys.FileSystem.absolutePath(haxe.io.Path.directory(Context.resolvePath("StdTypes.hx")));
		var added:Map<String, Bool> = [];
		for (path in Context.getClassPath()) {
			var directory = path == "" ? "." : path;
			if (!sys.FileSystem.exists(directory)
				|| !sys.FileSystem.isDirectory(directory)
				|| StringTools.startsWith(sys.FileSystem.absolutePath(directory), std))
				continue;
			for (entry in sys.FileSystem.readDirectory(directory)) {
				var name = StringTools.endsWith(entry, ".hx") ? entry.substr(0, entry.length - 3) : entry;
				if (name == "helix"
					|| name == "haxe"
					|| name == "import"
					|| added.exists(name)
					|| !~/^[A-Za-z_][A-Za-z0-9_]*$/.match(name))
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
		if (!hooked) {
			hooked = true;
			Context.onAfterTyping(resolve);
		}
		var fields = Context.getBuildFields();
		var parent = local.get().superClass == null ? null : local.get().superClass.t.get();
		var forwards:Map<String, Null<Field>> = [];
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
					// An async function can't use `super`: a function of the class calls each of its functions for it.
					if (Context.defined("js") && parent != null && field.name != "new" && field.access.indexOf(AStatic) < 0)
						body = forwarded(body, parent, forwards);
					var wrapped = macro @:pos(body.pos) helix.raylib.internal.Wait.body($body, $v{key}, $v{field.name == "new"}, false);
					if (isMain && field.name == "main") {
						var root = Context.definedValue("helix-raylib-native-root");
						if (root == null)
							root = "../web";
						wrapped = macro @:pos(body.pos) {
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
		for (forward in forwards)
			if (forward != null)
				fields.push(forward);
		return fields;
	}

	// A body with each use of `super` made a call of a function of the class (`forwards`, by name): a call of `super`'s function
	// calls one calling it, and a read or a write of `super`'s property one calling its accessor.
	static function forwarded(e:Expr, parent:ClassType, forwards:Map<String, Null<Field>>):Expr {
		function on(x:Expr):Expr
			return forwarded(x, parent, forwards);
		return switch e.expr {
			case ECall({expr: EField({expr: EConst(CIdent("super"))}, name), pos: pos}, args):
				var by = forwarder(name, parent, forwards, pos);
				// A name `super` doesn't have is left for the compiler to report.
				if (by == null)
					return e;
				{expr: ECall(macro @:pos(pos) this.$by, [for (a in args) on(a)]), pos: e.pos};
			case EBinop(op = OpAssign | OpAssignOp(_), {expr: EField({expr: EConst(CIdent("super"))}, name)}, value):
				var set = accessor("set", name, parent, forwards, e.pos);
				var get = op == OpAssign ? null : accessor("get", name, parent, forwards, e.pos);
				if (set == null || (op != OpAssign && get == null))
					return e;
				var v = switch op {
					case OpAssignOp(by): {expr: EBinop(by, macro @:pos(e.pos) this.$get(), on(value)), pos: e.pos};
					case _: on(value);
				}
				macro @:pos(e.pos) this.$set($v);
			case EUnop(op = OpIncrement | OpDecrement, postFix, {expr: EField({expr: EConst(CIdent("super"))}, name)}):
				var get = accessor("get", name, parent, forwards, e.pos);
				var set = accessor("set", name, parent, forwards, e.pos);
				if (get == null || set == null)
					return e;
				var step = op == OpIncrement ? macro 1 : macro - 1;
				postFix ? macro @:pos(e.pos) {
					var before = this.$get();
					this.$set(before + $step);
					before;
				} : macro @:pos(e.pos) this.$set(this.$get() + $step);
			case EField({expr: EConst(CIdent("super"))}, name):
				var get = accessor("get", name, parent, forwards, e.pos);
				get == null ? e : macro @:pos(e.pos) this.$get();
			// A string's `${...}` is an expression only once the string is read as one.
			case EConst(CString(s, SingleQuotes)) if (s.indexOf("$") >= 0):
				on(haxe.macro.MacroStringTools.formatString(s, e.pos));
			case _:
				haxe.macro.ExprTools.map(e, on);
		}
	}

	// The name of the function of the class calling `super`'s function of a name, made once a name (`forwards`), or null when `super`
	// has none.
	static function forwarder(name:String, parent:ClassType, forwards:Map<String, Null<Field>>, pos:Position):Null<String> {
		if (!forwards.exists(name))
			forwards.set(name, forward(name, parent, pos));
		return forwards.get(name) == null ? null : SUPER + name;
	}

	// The name of the function of the class calling the accessor (`get` or `set`) of `super`'s property, or null when `super` has no
	// property of the name with one.
	static function accessor(side:String, name:String, parent:ClassType, forwards:Map<String, Null<Field>>, pos:Position):Null<String> {
		var field = inherited(name, parent);
		var access = field == null ? null : switch field.kind {
			case FVar(read, write): side == "get" ? read : write;
			case _: null;
		}
		return access != null && access.match(AccCall) ? forwarder(side + "_" + name, parent, forwards, pos) : null;
	}

	// The field of a name a class has or inherits, or null.
	static function inherited(name:String, parent:ClassType):Null<ClassField> {
		var c:Null<ClassType> = parent;
		while (c != null) {
			for (f in c.fields.get())
				if (f.name == name)
					return f;
			c = c.superClass == null ? null : c.superClass.t.get();
		}
		return null;
	}

	// A function of the class calling `super`'s function of a name with its own arguments, or null when `super` has none of the name.
	static function forward(name:String, parent:ClassType, pos:Position):Null<Field> {
		var found = inherited(name, parent);
		if (found == null)
			return null;
		return switch Context.follow(found.type) {
			case TFun(args, _):
				var names = [for (i in 0...args.length) macro $i{"a" + i}];
				var key = Std.string(pos);
				returns.set(key, null);
				{
					name: SUPER + name,
					access: [APrivate],
					meta: [{name: ":noCompletion", pos: pos}],
					pos: pos,
					kind: FFun({
						args: [for (i in 0...args.length) {name: "a" + i, opt: args[i].opt, type: null}],
						ret: null,
						expr: macro @:pos(pos) helix.raylib.internal.Wait.body(return super.$name($a{names}), $v{key}, false, true)
					})
				};
			case _: null;
		}
	}

	// Whether a variable's initial value is checked: one that could hold a call.
	static function checked(field:Field, e:Null<Expr>):Bool {
		return e != null
			&& !e.expr.match(EConst(_))
			&& field.access.indexOf(AInline) < 0
			&& !Context.getLocalClass().get().kind.match(KAbstractImpl(_));
	}

	static function value(e:Expr, t:Null<ComplexType>):Expr {
		return macro @:pos(e.pos) helix.raylib.internal.Wait.body(${t == null ? e : macro @:pos(e.pos) ($e : $t)}, $v{Std.string(e.pos)}, true, false);
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

	/** Returns an expansion with every part a macro wrote placed at the program's call being expanded, so a page's source map names the
		program's line for each. The parts the program wrote, its arguments, stay where they are.

		@param expansion  The expansion.
		@return  The expansion, placed. */
	public static function placed(expansion:Expr):Expr {
		var pos = Context.currentPos();
		var file = Context.getPosInfos(pos).file;
		function place(e:Expr):Expr {
			return {expr: e.map(place).expr, pos: Context.getPosInfos(e.pos).file == file ? e.pos : pos};
		}
		return place(expansion);
	}

	/** Returns `EndDrawing`'s expansion: natively the frame's end, which waits out the frame; in a page the frame shown, the wait for
		the browser's next frame, then the frame counted and the next one's input read.

		@param refusal  The message refusing the call in a function used as a value.
		@return  The expansion. */
	public static function frame(refusal:String):Expr {
		if (!Context.defined("js"))
			return placed(call(refusal, macro helix.raylib.internal.Runtime.endFrame()));
		var wait = call(refusal, macro helix.raylib.internal.Runtime.frameWait());
		return placed(macro {
			helix.raylib.internal.Runtime.showFrame();
			helix.raylib.internal.Await.promised($wait);
			helix.raylib.internal.Runtime.countFrame();
		});
	}

	/** Returns a load's expansion, whose value is the answer: natively a call that returns once the answer came; in a page a wait for
		the answer.

		@param refusal  The message refusing the call in a function used as a value.
		@param ask  A function asking, given what to call with the answer.
		@return  The expansion. */
	public static function answer(refusal:String, ask:Expr):Expr {
		var wait = call(refusal, macro helix.raylib.internal.Runtime.answered($ask));
		return placed(Context.defined("js") ? macro helix.raylib.internal.Await.promised($wait) : wait);
	}

	/** Returns the expansion of a waiting call a section writes with an `answer` parameter after raylib's own (`@:waits`): the
		section's function asked, and its answer waited for.

		@param refusal  The message refusing the call in a function used as a value.
		@param asked  The section's function.
		@param args  The call's arguments, raylib's.
		@param isVoid  Whether the call has no value, its section's `answer` taking none.
		@return  The expansion. */
	public static function section(refusal:String, asked:Expr, args:Array<Expr>, isVoid:Bool):Expr {
		// Binding the arguments evaluates them before the wait, outside the function asking.
		var ask = macro @:privateAccess $asked.bind($a{args});
		if (!isVoid)
			return answer(refusal, ask);
		var wait = call(refusal, macro helix.raylib.internal.Runtime.finished($ask));
		return placed(Context.defined("js") ? macro helix.raylib.internal.Await.finished($wait) : wait);
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

	// Whether a function waits: its body holds a waiting call, or calls a function that does. UNKNOWN when that rests on a function
	// whose body is still being typed: one that called its way here.
	static function reach(key:String, field:ClassField, visited:Map<String, Bool>):Int {
		var state = states.get(key);
		if (state == null) {
			// Types the function's body now, which runs its own `body`.
			field.expr();
			state = states.get(key);
			if (state == null)
				return NO;
		}
		if (state.decided)
			return state.waits ? YES : NO;
		if (visited.exists(key))
			return NO;
		visited.set(key, true);
		if (state.calls == null)
			return UNKNOWN;
		if (state.direct)
			return YES;
		var result = NO;
		for (c in state.calls)
			if (c.kind == Called)
				switch reach(c.key, c.field, visited) {
					case YES:
						return YES;
					case UNKNOWN:
						result = UNKNOWN;
					case _:
				}
		return result;
	}

	// Keeps a refusal, reported once every body is typed (`resolve`): reported while a body is typed, it would end the typing of
	// each function calling its way there, and with it their own refusals.
	static function refuse(message:String, pos:Position):Void {
		var key = '$pos $message';
		if (refused.exists(key))
			return;
		refused.set(key, true);
		refusing.push({message: message, pos: pos});
	}

	// Refuses a call of a function that waits where a call can't wait.
	static function refuseCall(c:Call, constructor:Bool):Void {
		var name = c.field.name;
		switch c.kind {
			case Called if (constructor):
				refuse('$name(): Not supported in a constructor or a variable\'s initial value.', c.pos);
			case Called:
			case InLambda:
				refuse('$name(): Not supported in a function used as a value.', c.pos);
			case AsValue:
				refuse('$name: Not supported as a value.', c.pos);
			case Unmatched:
				refuse('$name(): Not supported here.', c.pos);
		}
	}

	// Refuses a waiting method that an interface declares, or that overrides one that doesn't wait: a call through the interface or
	// the class above wouldn't wait for it.
	static function refuseInherited(state:State):Void {
		var name = state.method;
		var c = state.owner;
		if (c == null || Lambda.exists(c.statics.get(), f -> f.name == name))
			return;
		function declared(interfaces:Array<{t:Ref<ClassType>, params:Array<Type>}>):Void {
			for (i in interfaces) {
				var type = i.t.get();
				if (Lambda.exists(type.fields.get(), f -> f.name == name))
					refuse('$name(): Not supported in interface ${type.name}.', state.pos);
				declared(type.interfaces);
			}
		}
		declared(c.interfaces);
		var above = c.superClass;
		while (above != null) {
			var type = above.t.get();
			declared(type.interfaces);
			for (f in type.fields.get())
				if (f.name == name && reach(Std.string(f.pos), f, []) != YES)
					refuse('$name(): Not supported as an override of ${type.name}.$name.', state.pos);
			above = type.superClass;
		}
	}

	// Decides the functions left undecided, each resting on one whose body was still being typed, once every body is typed: refuses
	// what each then can't hold and, in a page, defines the class whose values choose each one's body.
	static function resolve(_:Array<ModuleType>):Void {
		if (resolved)
			return;
		resolved = true;
		for (state in undecided) {
			var waits = false;
			if (!state.constructor)
				for (c in state.calls)
					if (c.kind == Called && c.key != state.key && reach(c.key, c.field, [state.key => true]) == YES)
						waits = true;
			state.waits = waits;
		}
		for (state in undecided)
			state.decided = true;
		for (l in late)
			if (l.call.key == l.by.key ? l.by.waits : reach(l.call.key, l.call.field, []) == YES)
				refuseCall(l.call, l.by.constructor);
		for (state in undecided)
			if (state.waits)
				refuseInherited(state);
		for (r in refusing)
			Context.reportError(r.message, r.pos);
		var flagged = [for (state in undecided) if (state.flag >= 0) state];
		if (flagged.length == 0 || refusing.length > 0)
			return;
		Context.defineType({
			pack: [],
			name: FLAGS,
			pos: Context.currentPos(),
			meta: [
				{name: ":keep", pos: Context.currentPos()},
				{name: ":noCompletion", pos: Context.currentPos()}
			],
			kind: TDClass(),
			fields: [
				for (state in flagged)
					{
						name: 'f${state.flag}',
						access: [APublic, AStatic],
						kind: FVar(macro :Bool, macro $v{state.waits}),
						pos: Context.currentPos()
					}
			]
		});
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
		@param forwards  Whether the body only calls `super`'s function and returns its value, the promise when it waits.
		@return  The body. */
	public static macro function body(e:Expr, key:String, constructor:Bool, forwards:Bool):Expr {
		var state = new State(key, constructor);
		states.set(key, state);
		var local = Context.getLocalClass();
		state.owner = local == null ? null : local.get();
		state.method = Context.getLocalMethod();
		state.pos = Context.currentPos();
		// A function's body is typed as a statement, as Haxe types one: a value after it keeps the body from being the block's value.
		// A body with an error is left as it is, for the compiler to report every error in it.
		var typed = try {
			if (returns.exists(key))
				switch Context.typeExpr(macro @:pos(e.pos) {
					$e;
					0;
				}).expr {
					case TBlock([statement, _]): statement;
					case _: throw "a block of two";
				}
			else
				Context.typeExpr(e);
		} catch (_:haxe.Exception) {
			return e;
		}
		// The calls written in the body as a name's: `step()`.
		var named:Map<String, Bool> = [];
		function names(x:Expr):Void {
			switch x.expr {
				case ECall({expr: EConst(CIdent(name))}, _):
					named.set(name + place(x.pos), true);
				case EConst(CString(text, SingleQuotes)) if (text.indexOf("$") >= 0):
					// A call in a string's `${}`.
					names(haxe.macro.MacroStringTools.formatString(text, x.pos));
				case _:
			}
			haxe.macro.ExprTools.iter(x, names);
		}
		names(e);
		// The functions declared in the body that can wait: each only ever called by its name, in the body, in itself or in another of
		// them.
		var locals:Map<Int, Local> = [];
		function scan(t:TypedExpr, within:Array<Int>):Void {
			function declared(v:TVar, f:TFunc, pos:Position):Void {
				locals.set(v.id, {
					name: v.name,
					pos: pos,
					isVoid: isVoid(f.t),
					ret: try Context.toComplexType(f.t) catch (_:haxe.Exception) null,
					called: true,
					waits: false,
					sites: []
				});
				scan(f.expr, within.concat([v.id]));
			}
			switch t.expr {
				case TVar(v, {expr: TFunction(f), pos: pos}):
					declared(v, f, pos);
				case TBlock(el):
					// A function calling itself is typed as a variable, then the function assigned to it.
					var i = 0;
					while (i < el.length) {
						switch [el[i].expr, i + 1 < el.length ? el[i + 1].expr : null] {
							case [
								TVar(v, {expr: TConst(TNull)}),
								TBinop(OpAssign, {expr: TLocal(to)}, {expr: TFunction(f), pos: pos})
							] if (to.id == v.id):
								declared(v, f, pos);
								i++;
							case _:
								scan(el[i], within);
						}
						i++;
					}
				case TFunction(f):
					scan(f.expr, within.concat([-1]));
				case TCall({expr: TLocal(v)}, args) if (locals.exists(v.id) && named.exists(v.name + place(t.pos))):
					var local = locals.get(v.id);
					if (within.indexOf(-1) >= 0)
						local.called = false;
					local.sites.push({pos: t.pos, isVoid: isVoid(t.t), within: within});
					for (a in args)
						scan(a, within);
				case TLocal(v) if (locals.exists(v.id)):
					locals.get(v.id).called = false;
				case _:
					t.iter(scan.bind(_, within));
			}
		}
		scan(typed, []);
		var settled = false;
		while (!settled) {
			settled = true;
			for (local in locals)
				if (local.called && Lambda.exists(local.sites, site -> Lambda.exists(site.within, id -> !locals.get(id).called))) {
					local.called = false;
					settled = false;
				}
		}
		var calls:Array<Call> = [];
		// The function declared in the body each call is in, by its variable, or -1.
		var callsIn:Array<Int> = [];
		var direct = false;
		var current = -1;
		function walk(t:TypedExpr, lambda:Bool):Void {
			switch t.expr {
				case TCall({expr: TField(_, FStatic(_, cf))}, args) if (cf.get().meta.has(META)):
					var refusal = refusals.get(Std.string(t.pos));
					if (refusal == null)
						refusal = cf.get().name;
					if (lambda)
						refuse(refusal, t.pos);
					else if (constructor)
						refuse(refusal.split(":")[0] + ": Not supported in a constructor or a variable's initial value.", t.pos);
					else {
						direct = true;
						if (current >= 0)
							locals.get(current).waits = true;
					}
					for (a in args)
						walk(a, lambda);
				case TVar(v, {expr: TFunction(f)}) | TBinop(OpAssign, {expr: TLocal(v)}, {expr: TFunction(f)})
					if (locals.exists(v.id) && locals.get(v.id).called):
					var outer = current;
					current = v.id;
					walk(f.expr, lambda);
					current = outer;
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
							callsIn.push(current);
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
							callsIn.push(current);
					}
					walk(target, lambda);
				case _:
					t.iter(walk.bind(_, lambda));
			}
		}
		walk(typed, false);
		state.calls = calls;
		state.direct = direct;
		// The calls of functions that wait, and of those not known yet: one whose body is still being typed, which called its way here.
		var waiting:Array<Call> = [];
		var unknown:Array<Call> = [];
		for (c in calls)
			if (c.key != key)
				switch reach(c.key, c.field, [key => true]) {
					case YES:
						refuseCall(c, constructor);
						if (c.kind == Called && !constructor)
							waiting.push(c);
					case UNKNOWN:
						unknown.push(c);
					case _:
				}
		state.waits = direct || waiting.length > 0;
		state.decided = state.waits || unknown.length == 0;
		if (!state.decided)
			undecided.push(state);
		// A call of a function not known yet is refused once it is, should it wait (`resolve`).
		for (c in unknown)
			if (c.kind != Called || constructor)
				late.push({by: state, call: c});
		// A function calling itself in a function used as a value, or naming itself as a value.
		for (c in calls)
			if (c.key == key && c.kind != Called) {
				if (state.waits)
					refuseCall(c, constructor);
				else if (!state.decided)
					late.push({by: state, call: c});
			}
		if (state.waits)
			refuseInherited(state);
		if (forwards || (!state.decided && constructor))
			return Context.storeTypedExpr(typed);
		if ((state.decided && !state.waits) || !Context.defined("js"))
			return Context.storeTypedExpr(typed);
		// Awaited: the calls of functions that wait, of this one, and of those not known yet, whose value is awaited as well as a
		// promise is.
		var awaits = waiting.concat([for (c in unknown) if (c.kind == Called) c]).concat([for (c in calls) if (c.key == key && c.kind == Called) c]);
		var used = [for (_ in awaits) false];
		// A function declared in the body waits when it holds a waiting call, an awaited one, or a call of another that waits.
		for (c in awaits) {
			var declared = callsIn[calls.indexOf(c)];
			if (declared >= 0)
				locals.get(declared).waits = true;
		}
		settled = false;
		while (!settled) {
			settled = true;
			for (local in locals)
				if (local.called && local.waits)
					for (site in local.sites) {
						var declared = site.within.length == 0 ? null : locals.get(site.within[site.within.length - 1]);
						if (declared != null && !declared.waits) {
							declared.waits = true;
							settled = false;
						}
					}
		}
		var asyncs = [for (local in locals) if (local.called && local.waits) local];
		var sites = [
			for (local in asyncs)
				for (site in local.sites)
					{
						pos: site.pos,
						isVoid: site.isVoid,
						name: local.name,
						used: false
					}
		];
		function rewrite(x:Expr):Expr {
			switch x.expr {
				case EConst(CString(text, SingleQuotes)):
					// A call in a string's `${}` is an expression once the string is one.
					var p = Context.getPosInfos(x.pos);
					for (a in awaits.map(a -> a.pos).concat(sites.map(site -> site.pos))) {
						var at = Context.getPosInfos(a);
						if (at.file == p.file && at.min >= p.min && at.max <= p.max)
							return rewrite(haxe.macro.MacroStringTools.formatString(text, x.pos));
					}
				case _:
			}
			var inner = x.map(rewrite);
			switch inner.expr {
				// A function declared in the body that waits is an async function, as the body is.
				case EFunction(kind, f):
					for (local in asyncs)
						if (place(local.pos) == place(x.pos)) {
							var ret = f.ret == null ? local.ret : f.ret;
							return {
								expr: EFunction(kind, {
									args: f.args,
									ret: ret,
									params: f.params,
									expr: async(f.expr, ret, local.isVoid)
								}),
								pos: x.pos
							};
						}
				case _:
			}
			switch x.expr {
				case ECall(_, _):
					// A call can be typed more than once at its place (a loop over `0...n`), each one awaited here.
					var isVoid:Null<Bool> = null;
					for (site in sites)
						if (place(site.pos) == place(x.pos)) {
							site.used = true;
							isVoid = site.isVoid;
						}
					for (i in 0...awaits.length)
						if (place(awaits[i].pos) == place(x.pos)) {
							used[i] = true;
							isVoid = awaits[i].isVoid;
						}
					if (isVoid != null)
						return isVoid ? macro @:pos(x.pos) js.Syntax.code("(await {0})",
							untyped $inner) : macro @:pos(x.pos) helix.raylib.internal.Await.value($inner);
				case _:
			}
			return inner;
		}
		var inner = rewrite(e);
		for (i in 0...awaits.length)
			if (!used[i]) {
				var missed:Call = {
					key: awaits[i].key,
					field: awaits[i].field,
					pos: awaits[i].pos,
					kind: Unmatched,
					isVoid: false
				};
				if (i < waiting.length)
					refuseCall(missed, false);
				else
					late.push({by: state, call: missed});
			}
		for (site in sites)
			if (!site.used)
				refuse('${site.name}(): Not supported here.', site.pos);
		var ret = returns.get(key);
		var isVoid = switch ret {
			case null: !returnsValue(e);
			case TPath({name: "Void", pack: []}): true;
			case _: false;
		}
		var async = async(inner, ret, isVoid);
		if (state.decided)
			return async;
		// Not known yet: both bodies, the one run chosen as the page starts by a value `resolve` defines.
		state.flag = flags++;
		var flag = '$FLAGS.f${state.flag}';
		return macro @:pos(e.pos) {
			if (js.Syntax.code($v{flag}))
				$async;
			$e;
		};
	}
}

#if macro
// A position as text: its file and characters.
private function place(pos:Position):String {
	var p = Context.getPosInfos(pos);
	return '@${p.file}:${p.min}-${p.max}';
}

// A function's body run as an async function's, the function returning its promise.
private function async(body:Expr, ret:Null<ComplexType>, isVoid:Bool):Expr {
	var f:Expr = {expr: EFunction(FAnonymous, {args: [], ret: ret, expr: body}), pos: body.pos};
	return isVoid ? macro @:pos(body.pos) js.Syntax.code("return (async {0})()", $f) : macro @:pos(body.pos) return cast js.Syntax.code("(async {0})()", $f);
}

private class State {
	public final key:String;
	public final constructor:Bool;
	public var owner:Null<ClassType> = null;
	public var method = "";
	public var pos:Null<Position> = null;
	public var calls:Null<Array<Call>> = null;
	public var direct = false;
	public var decided = false;
	public var waits = false;
	// In a page, which of the flags class's values chooses its body, or -1.
	public var flag = -1;

	public function new(key:String, constructor:Bool) {
		this.key = key;
		this.constructor = constructor;
	}
}

private enum CallKind {
	Called;
	InLambda;
	AsValue;
	Unmatched;
}

private typedef Local = {
	name:String,
	// The function's position.
	pos:Position,
	// Whether it returns no value, and its return type when that can be written.
	isVoid:Bool,
	ret:Null<ComplexType>,
	// Whether every use of it is a call by its name, in the body or in another such function.
	called:Bool,
	waits:Bool,
	// Its calls, each with the functions declared in the body it is in, outermost first, -1 for one used as a value.
	sites:Array<{pos:Position, isVoid:Bool, within:Array<Int>}>
}

private typedef Call = {
	key:String,
	field:ClassField,
	pos:Position,
	kind:CallKind,
	isVoid:Bool
}
#end
