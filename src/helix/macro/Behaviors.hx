package helix.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

/** The build macro behind behaviors (helix.behavior.Behavior carries it as `@:autoBuild`, so it runs on each subclass): from the
	class's `@:prop` fields, a `schema()` (the class's name, or `@:behavior("Name")`, its phase, and each prop's name, type, default
	and `@:range`), the override of Behavior's phase getter for a class marked `@:phase(Name)`, a setter and a getter by prop name (a `switch` assigning the field, typed; no reflection), and the class's registration
	in BehaviorRegistry as the program starts.

	The registration is a static `__init__` on a class marked `@:keep`: `__init__` runs when the class is initialized, on JS before
	any deferred static initializer and on hxcpp in an order of its own with them, which is why the registry makes its table lazily;
	`@:keep` holds the class and its `__init__` against dead code elimination, which would otherwise drop a class only a scene file
	names. A class the build never loads (one no code names, in no included package) registers nothing: the compiler doesn't see it.

	The props are read as written, from the build fields: a type declared on the field is resolved here, in the class's own module; an
	initializer's constant gives the type otherwise (a list or a node reference must declare its type). A superclass's props come
	through its own generated `schema()`, setter and getter, which the subclass's call for the names it doesn't have. */
class Behaviors {
	static inline var BASE = "helix.behavior.Behavior";
	static final PHASES = ["Input", "Simulate", "Resolve", "Late"];

	/** The fields of a Behavior subclass: `schema()`, the setter and getter, and the registration (left out of a class marked
		`@:abstract` or whose constructor takes arguments). Fails, naming the field, for a `@:prop` that isn't a `public var` with an
		initializer, whose type isn't one the file can hold, or that is marked a color without being an Int; for a `@:phase` naming no
		Phase constructor; and for a class that declares a name the macro generates. */
	public static function build():Array<Field> {
		var cls = Context.getLocalClass().get();
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		var parent = cls.superClass == null ? null : cls.superClass.t.get();
		if (parent == null)
			return fields;
		var parentPath = path(parent);
		var parentIsBase = parent.pack.concat([parent.name]).join(".") == BASE;
		var ownPath = path(cls);
		var ownType = typePath(cls);
		var own = TPath(ownType);
		for (field in fields)
			if (["schema", "__setProp", "__getProp", "__init__", "get_phase"].contains(field.name))
				Context.error('Behaviors: ${cls.name}.${field.name} is a name the behavior build generates', field.pos);
		var props = [];
		for (field in fields) {
			var meta = find(field.meta, ":prop");
			if (meta != null)
				props.push(prop(cls, field, meta));
		}
		var name = cls.name;
		var named = find(cls.meta.get(), ":behavior");
		if (named != null) {
			if (named.params == null || named.params.length != 1)
				Context.error('Behaviors: @:behavior takes the name to register ${cls.name} under, as a string', named.pos);
			name = switch named.params[0].expr {
				case EConst(CString(s, _)): s;
				default: Context.error('Behaviors: @:behavior takes the name to register ${cls.name} under, as a string', named.pos);
			}
		}
		var phase = readPhase(cls);

		// schema(): the superclass's props, then this class's.
		var entries = [
			for (p in props)
				macro props.push({
					name: $v{p.name},
					type: $p{["helix", "behavior", "BehaviorPropType", p.kind]},
					value: $e{p.value},
					min: $e{p.min == null ? macro null : macro $v{p.min}},
					max: $e{p.max == null ? macro null : macro $v{p.max}}
				})
		];
		var inherited = parentIsBase ? macro [] : macro $p{parentPath}.schema().props;
		var phaseValue = phase != null ? macro $p{["helix", "behavior", "Phase", phase]} : parentIsBase ? macro helix.behavior.Phase.Simulate : macro $p{parentPath}.schema()
			.phase;
		var schema:Field = {
			name: "schema",
			doc: "Its name and props (each one's name, type, default and range), for the registry, a scene file's loader and an inspector: generated from its @:prop fields.",
			access: [APublic, AStatic],
			kind: FFun({
				args: [],
				ret: macro :helix.behavior.BehaviorSchema.BehaviorSchema,
				expr: macro {
					var props:Array<helix.behavior.BehaviorProp> = $inherited;
					$b{entries};
					return {name: $v{name}, props: props, phase: $phaseValue};
				}
			}),
			pos: pos,
		};

		// The setter and getter: a switch on the name, the superclass's for the rest.
		var setCases:Array<Case> = [for (p in props) {values: [macro $v{p.name}], expr: setter(p)}];
		var setDefault = parentIsBase ? macro return false : macro return $p{parentPath}.__setProp(target, name, value);
		var setProp:Field = {
			name: "__setProp",
			meta: [{name: ":noCompletion", pos: pos}],
			access: [AStatic],
			kind: FFun({
				args: [
					{name: "target", type: own},
					{name: "name", type: macro :String},
					{name: "value", type: macro :Dynamic}
				],
				ret: macro :Bool,
				expr: {expr: ESwitch(macro name, setCases, setDefault), pos: pos}
			}),
			pos: pos,
		};
		var getCases:Array<Case> = [
			for (p in props)
				{values: [macro $v{p.name}], expr: getter(p)}
		];
		var getDefault = parentIsBase ? macro return null : macro return $p{parentPath}.__getProp(target, name);
		var getProp:Field = {
			name: "__getProp",
			meta: [{name: ":noCompletion", pos: pos}],
			access: [AStatic],
			kind: FFun({
				args: [{name: "target", type: own}, {name: "name", type: macro :String}],
				ret: macro :Dynamic,
				expr: {expr: ESwitch(macro name, getCases, getDefault), pos: pos}
			}),
			pos: pos,
		};
		var made = [schema, setProp, getProp];

		// The phase getter, for a class that says its phase; one that doesn't inherits its base's.
		if (phase != null)
			made.push({
				name: "get_phase",
				access: [AOverride],
				kind: FFun({
					args: [],
					ret: macro :helix.behavior.Phase,
					expr: macro return $p{["helix", "behavior", "Phase", phase]}
				}),
				pos: pos,
			});

		// The registration, for a class that can be made bare.
		if (!cls.isAbstract && !cls.meta.has(":abstract") && hasBareConstructor(fields)) {
			cls.meta.add(":keep", [], pos);
			made.push({
				name: "__init__",
				access: [AStatic],
				kind: FFun({
					args: [],
					ret: macro :Void,
					expr: macro helix.behavior.BehaviorRegistry.register($v{name}, () -> new $ownType(), schema(), (behavior, name, value) -> {
						var target = Std.downcast(behavior, $p{ownPath});
						return target != null && __setProp(target, name, value);
					}, (behavior, name) -> {
						var target = Std.downcast(behavior, $p{ownPath});
						return target == null ? null : __getProp(target, name);
					})
				}),
				pos: pos,
			});
		}
		return fields.concat(made);
	}

	// The Phase constructor's name `@:phase` gives on the class, or null for none.
	static function readPhase(cls:ClassType):Null<String> {
		var meta = find(cls.meta.get(), ":phase");
		if (meta == null)
			return null;
		var named = meta.params != null && meta.params.length == 1 ? switch meta.params[0].expr {
			case EConst(CIdent(n)): n;
			default: null;
		} : null;
		if (named == null || !PHASES.contains(named))
			Context.error('Behaviors: @:phase on ${cls.name} takes one of ${PHASES.join(", ")}', meta.pos);
		return named;
	}

	static function getter(p:Prop):Expr {
		var name = p.name;
		return macro return target.$name;
	}

	// A class's path as the generated code, typed in the built class's module, names it: a class of that module by its bare name (a
	// private one, as a test's subclasses are, can be named no other way), a module's main class by its path, another class of a module
	// through the module (`pack.Module.Class`). The package is the module's: a private class's own carries the compiler's `_Module`
	// element.
	static function path(c:ClassType):Array<String> {
		if (c.module == Context.getLocalModule())
			return [c.name];
		var pack = c.module.split("."), module = pack.pop();
		return module == c.name ? pack.concat([c.name]) : pack.concat([module, c.name]);
	}

	static function typePath(c:ClassType):TypePath {
		if (c.module == Context.getLocalModule())
			return {pack: [], name: c.name};
		var pack = c.module.split("."), module = pack.pop();
		return module == c.name ? {pack: pack, name: c.name} : {pack: pack, name: module, sub: c.name};
	}

	static function find(meta:Metadata, name:String):Null<MetadataEntry> {
		for (m in meta)
			if (m.name == name)
				return m;
		return null;
	}

	// Whether the class's constructor, as written, takes no arguments (an inherited one is Behavior's, which takes none).
	static function hasBareConstructor(fields:Array<Field>):Bool {
		for (field in fields)
			if (field.name == "new")
				switch field.kind {
					case FFun(f):
						for (a in f.args)
							if (a.opt != true && a.value == null)
								return false;
					default:
				}
		return true;
	}

	// A @:prop field read: its name, its kind, its initializer as its default, and its range.
	static function prop(cls:ClassType, field:Field, meta:MetadataEntry):Prop {
		var where = '${cls.name}.${field.name}';
		if (!field.access.contains(APublic) || field.access.contains(AStatic))
			Context.error('Behaviors: a @:prop is a public var: $where', field.pos);
		var t:Null<ComplexType>, value:Null<Expr>;
		switch field.kind {
			case FVar(ft, e):
				t = ft;
				value = e;
			default:
				Context.error('Behaviors: a @:prop is a public var, not a property or a method: $where', field.pos);
		}
		if (value == null)
			Context.error('Behaviors: a @:prop has an initializer, its default: $where', field.pos);
		var color = false;
		if (meta.params != null && meta.params.length > 0)
			switch meta.params[0].expr {
				case EConst(CString("color", _)):
					color = true;
				default:
					Context.error('Behaviors: @:prop takes nothing, or "color" for an Int holding one: $where', meta.pos);
			}
		var kind = t != null ? kindOfType(t, field.pos) : kindOfValue(value);
		if (kind == null)
			Context.error('Behaviors: a @:prop is an Int, Float, Bool, String, Array<Float>, a color (an Int marked @:prop("color")) or a Node3D, its type declared where its initializer doesn\'t say: $where',
				field.pos);
		if (color) {
			if (kind != "IntProp")
				Context.error('Behaviors: a color prop is an Int (0xAARRGGBB): $where', field.pos);
			kind = "ColorProp";
		}
		var min:Null<Float> = null, max:Null<Float> = null;
		var range = find(field.meta, ":range");
		if (range != null) {
			if (range.params == null || range.params.length != 2)
				Context.error('Behaviors: @:range takes the least and the most, two numbers: $where', range.pos);
			min = number(range.params[0], where);
			max = number(range.params[1], where);
			if (!(min <= max))
				Context.error('Behaviors: @:range\'s least is more than its most: $where', range.pos);
		}
		return {
			name: field.name,
			kind: kind,
			value: value,
			min: min,
			max: max
		};
	}

	// A declared type's kind, resolved in the class's own module; null for one the file can't hold.
	static function kindOfType(t:ComplexType, pos:Position):Null<String> {
		return switch Context.follow(Context.resolveType(t, pos)) {
			case TAbstract(_.get() => a, _) if (a.pack.length == 0):
				switch a.name {
					case "Int": "IntProp";
					case "Float": "FloatProp";
					case "Bool": "BoolProp";
					default: null;
				}
			case TInst(_.get() => c, params):
				if (c.pack.length == 0 && c.name == "String") "StringProp"; else if (c.pack.length == 0 && c.name == "Array" && params.length == 1
					&& isFloat(params[0])) "FloatsProp"; else if (c.pack.join(".") == "helix.render3d"
					&& c.name == "Node3D") "NodeProp"; else null;
			default: null;
		}
	}

	static function isFloat(t:Type):Bool {
		return switch Context.follow(t) {
			case TAbstract(_.get() => a, _): a.pack.length == 0 && a.name == "Float";
			default: false;
		}
	}

	// An initializer's kind, for a field without a declared type: a constant's; a list's or a node's isn't told from it.
	static function kindOfValue(e:Expr):Null<String> {
		return switch e.expr {
			case EConst(CInt(_)): "IntProp";
			case EConst(CFloat(_)): "FloatProp";
			case EConst(CString(_, _)): "StringProp";
			case EConst(CIdent("true" | "false")): "BoolProp";
			case EUnop(OpNeg, false, inner): kindOfValue(inner);
			case EParenthesis(inner): kindOfValue(inner);
			default: null;
		}
	}

	// A @:range bound as a number.
	static function number(e:Expr, where:String):Float {
		return switch e.expr {
			case EConst(CInt(v)): Std.parseInt(v);
			case EConst(CFloat(v)): Std.parseFloat(v);
			case EUnop(OpNeg, false, inner): -number(inner, where);
			case EParenthesis(inner): number(inner, where);
			default: Context.error('Behaviors: @:range takes numbers: $where', e.pos);
		}
	}

	// The setter's arm for a prop: refuses a value of the wrong type, else assigns the field. A list is copied number by number through
	// Dynamic, so a list typed otherwise (a file's) lands as an Array<Float> on every target.
	static function setter(p:Prop):Expr {
		var name = p.name;
		return switch p.kind {
			case "IntProp" | "ColorProp":
				macro {
					if (!Std.isOfType(value, Int))
						return false;
					target.$name = value;
					return true;
				}
			case "FloatProp":
				macro {
					if (!Std.isOfType(value, Float))
						return false;
					target.$name = value;
					return true;
				}
			case "BoolProp":
				macro {
					if (!Std.isOfType(value, Bool))
						return false;
					target.$name = value;
					return true;
				}
			case "StringProp":
				macro {
					if (!Std.isOfType(value, String))
						return false;
					target.$name = value;
					return true;
				}
			case "FloatsProp":
				macro {
					if (!Std.isOfType(value, Array))
						return false;
					var length:Int = value.length;
					var floats:Array<Float> = [];
					for (i in 0...length) {
						var item:Dynamic = value[i];
						if (!Std.isOfType(item, Float))
							return false;
						floats.push(item);
					}
					target.$name = floats;
					return true;
				}
			case "NodeProp":
				macro {
					if (value != null && !Std.isOfType(value, helix.render3d.Node3D))
						return false;
					target.$name = value;
					return true;
				}
			default:
				macro return false;
		}
	}
}

/** A @:prop as the macro read it: its name, its kind (a BehaviorPropType constructor's name), its default and its range. */
typedef Prop = {
	/** The field's name. */
	var name:String;

	/** The BehaviorPropType constructor's name. */
	var kind:String;

	/** The field's initializer, the default. */
	var value:Expr;

	/** @:range's least, or null. */
	var min:Null<Float>;

	/** @:range's most, or null. */
	var max:Null<Float>;
}
#end
