package helix.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

/** The build macros behind the program's services as static classes (Window, Input, Graphics and the others; docs/CONVENTIONS.md): from a
	service's interface, or a class's public instance members, a static forwarder for each method and a static property for each variable or
	property, each with the member's doc comment, and the runner's bind, so the statics are never written twice by hand.

	The static class declares the instance it forwards to itself, `@:hot public static var instance(default, null):T`, with its doc comment:
	the global build hotreload-hx gives every class runs before a class's own, so a field this macro added would never be seen as `@:hot`, and
	natively it would start over, null, at a reload.

	A class's members are read as written (record), not as typed: a class's methods are typed lazily, and forcing their types from another
	class's build types their bodies too early, which the compiler doesn't survive. An interface's members are typed eagerly and read as
	typed. */
class Facade {
	// How the forwarders of the class being built reach its service: instance, or service() for an optional part.
	static var reach:Expr;

	// What record kept of each class marked with it, by its path: its public instance members as written, their types resolved.
	static var recorded = new Map<String, Array<Member>>();

	/** The fields of the static class being built, with a forwarder for each public member of the type `of` names (an interface, or a class
		marked `@:build(helix.macro.Facade.record())`, its superclasses' and extended interfaces' members too) but for the names in exclude
		(what is the runner's, such as poll and shutdown) and those the class declares itself (which it writes by hand), and `bind(value)`,
		which sets instance and which only the runner calls: with its service at its init and null at its cleanup. With install (a static
		function of the service's class returning it), the service is an optional part (helix.host.Part): the forwarders reach it through
		service(), which calls install the first time, so a program that never uses it carries none of it, and its class's install and
		shutdown call bind. Fails, saying why, for a type that is neither, a class with no instance, or a member it can't forward (one with
		type parameters, or without a declared type). */
	public static function build(of:Expr, ?exclude:Array<String>, ?install:Expr):Array<Field> {
		var fields = Context.getBuildFields();
		var pos = Context.currentPos();
		var path = of.toString();
		var type = Context.getType(path);
		var source = switch type {
			case TInst(c, _): c.get();
			default: Context.error('Facade: $path is not a class or an interface', of.pos);
		}
		var declared = new Map<String, Bool>();
		for (field in fields)
			declared.set(field.name, true);
		if (!declared.exists("instance"))
			Context.error('Facade: declare `@:hot public static var instance(default, null):$path;`, the service forwarded to', pos);
		var made:Array<Field> = [];
		if (!declared.exists("bind"))
			made.push({
				name: "bind",
				doc: "Sets the service forwarded to: the runner's, at its init, and null at its cleanup.",
				meta: [
					{name: ":allow", params: [macro helix.host.Runner], pos: pos},
					{name: ":allow", params: [of], pos: pos}
				],
				access: [AStatic],
				kind: FFun({
					args: [
						{name: "value", type: TPath({pack: [], name: "Null", params: [TPType(type.toComplexType())]})}
					],
					ret: macro :Void,
					expr: macro instance = value
				}),
				pos: pos,
			});
		// A build macro's missing argument comes as the expression null.
		if (install != null && install.expr.match(EConst(CIdent("null"))))
			install = null;
		if (install != null)
			made.push({
				name: "service",
				doc: "The service, installed by its first use.",
				meta: [{name: ":noCompletion", pos: pos}],
				access: [AStatic],
				kind: FFun({
					args: [],
					ret: type.toComplexType(),
					expr: macro {
						if (instance == null)
							instance = $install();
						return instance;
					}
				}),
				pos: pos,
			});
		reach = install == null ? macro instance : macro service();
		var skip = exclude == null ? [] : exclude;
		for (member in members(source, of.pos)) {
			if (declared.exists(member.name) || skip.contains(member.name))
				continue;
			declared.set(member.name, true);
			if (member.args != null)
				made.push(method(member, pos));
			else
				for (f in property(member, pos))
					made.push(f);
		}
		return fields.concat(made);
	}

	/** Keeps the public instance members of the class it builds, as written, for a static class's build over it to forward; changes nothing.
		Each argument's and result's type is resolved here, in the class's own module, so the forwarders name them in full. */
	public static function record():Array<Field> {
		var fields = Context.getBuildFields();
		var local = Context.getLocalClass().get();
		var members:Array<Member> = [];
		for (field in fields) {
			if (!field.access.contains(APublic) || field.access.contains(AStatic) || field.name == "new")
				continue;
			switch field.kind {
				case FFun(f):
					if (f.params != null && f.params.length > 0)
						Context.error('Facade: ${field.name} has type parameters, which a forwarder doesn\'t carry', field.pos);
					if (f.ret == null)
						Context.error('Facade: declare ${field.name}\'s return type, for its forwarder', field.pos);
					members.push({
						name: field.name,
						doc: field.doc,
						args: [
							for (a in f.args)
								{
									name: a.name,
									opt: a.opt == true,
									value: a.value,
									t: a.type != null ? Context.resolveType(a.type, field.pos) : typeOfConstant(a.value, field.name, field.pos)
								}
						],
						ret: Context.resolveType(f.ret, field.pos),
					});
				case FVar(t, _) | FProp(_, _, t, _):
					if (t == null)
						Context.error('Facade: declare ${field.name}\'s type, for its forwarder', field.pos);
					var read = true, write = !field.access.contains(AFinal);
					switch field.kind {
						case FProp(get, set, _, _):
							read = get != "never";
							write = set == "default" || set == "set";
						default:
					}
					members.push({
						name: field.name,
						doc: field.doc,
						t: Context.resolveType(t, field.pos),
						read: read,
						write: write
					});
			}
		}
		recorded.set(local.pack.concat([local.name]).join("."), members);
		return null;
	}

	// The public instance members of c and of what it extends (its superclasses, or the interfaces an interface extends), a member declared
	// again lower down counted once, its first.
	static function members(c:ClassType, pos:Position):Array<Member> {
		var found:Array<Member> = [];
		var seen = new Map<String, Bool>();
		function add(m:Member):Void
			if (!seen.exists(m.name)) {
				seen.set(m.name, true);
				found.push(m);
			}
		function walk(c:ClassType):Void {
			var name = c.pack.concat([c.name]).join(".");
			if (c.isInterface) {
				// A property's accessors (get_x, set_x) are the interface's fields too: the static property forwards through them.
				for (field in c.fields.get())
					if (!StringTools.startsWith(field.name, "get_") && !StringTools.startsWith(field.name, "set_"))
						add(typed(field));
				for (i in c.interfaces)
					walk(i.t.get());
			} else {
				var kept = recorded.get(name);
				if (kept == null)
					Context.error('Facade: mark $name with @:build(helix.macro.Facade.record()), so its members can be read as written', pos);
				for (m in kept)
					add(m);
				if (c.superClass != null)
					walk(c.superClass.t.get());
			}
		}
		walk(c);
		return found;
	}

	// An interface's member as typed, its arguments' defaults from the :value metadata Haxe records them in.
	static function typed(field:ClassField):Member {
		if (field.params.length > 0)
			Context.error('Facade: ${field.name} has type parameters, which a forwarder doesn\'t carry', field.pos);
		return switch field.kind {
			case FMethod(_):
				var defaults = new Map<String, Expr>();
				var value = field.meta.extract(":value");
				if (value.length > 0 && value[0].params != null && value[0].params.length > 0)
					switch value[0].params[0].expr {
						case EObjectDecl(values):
							for (v in values)
								defaults.set(v.field, v.expr);
						default:
					}
				switch Context.follow(field.type) {
					case TFun(args, ret):
						{
							name: field.name,
							doc: field.doc,
							args: [
								for (a in args)
									{
										name: a.name,
										opt: a.opt,
										value: defaults.get(a.name),
										t: a.t
									}
							],
							ret: ret
						};
					default:
						Context.error('Facade: ${field.name} is a method without a function type', field.pos);
				}
			case FVar(read, write):
				{
					name: field.name,
					doc: field.doc,
					t: field.type,
					read: read.match(AccNormal | AccCall | AccInline),
					write: write.match(AccNormal | AccCall)
				};
		}
	}

	// A default's type, for an argument declared by its default alone (`loop = false`).
	static function typeOfConstant(value:Null<Expr>, name:String, pos:Position):Type {
		var t:ComplexType = value == null ? null : switch value.expr {
			case EConst(CInt(_)): macro :Int;
			case EConst(CFloat(_)): macro :Float;
			case EConst(CString(_)): macro :String;
			case EConst(CIdent("true" | "false")): macro :Bool;
			default: null;
		}
		if (t == null)
			Context.error('Facade: declare the types of $name\'s arguments, for its forwarder', pos);
		return Context.resolveType(t, pos);
	}

	// An argument's default as the forwarder writes it: a constant as it is; a bare name (an enum's or an enum abstract's value) named in
	// full through its type, since the forwarder's module doesn't import what the member's did.
	static function qualify(value:Expr, t:Type):Expr {
		var name = switch value.expr {
			case EConst(CIdent(n)) if (n != "true" && n != "false" && n != "null"): n;
			default: return value;
		}
		var module:String, typeName:String;
		switch Context.follow(t, true) {
			case TEnum(e, _):
				module = e.get().module;
				typeName = e.get().name;
			case TAbstract(a, _):
				module = a.get().module;
				typeName = a.get().name;
			default:
				return value;
		}
		var parts = module.split(".");
		if (parts[parts.length - 1] != typeName)
			parts.push(typeName);
		parts.push(name);
		return macro $p{parts};
	}

	// A static method calling member on instance with its arguments, their defaults kept.
	static function method(member:Member, pos:Position):Field {
		var name = member.name;
		var passed = [for (a in member.args) macro $i{a.name}];
		var call = macro $reach.$name($a{passed});
		var isVoid = switch Context.follow(member.ret) {
			case TAbstract(_.get() => {pack: [], name: "Void"}, _): true;
			default: false;
		}
		return {
			name: name,
			doc: member.doc,
			access: [APublic, AStatic],
			kind: FFun({
				args: [
					for (a in member.args)
						{
							name: a.name,
							opt: a.opt && a.value == null,
							type: a.t.toComplexType(),
							value: a.value == null ? null : qualify(a.value, a.t)
						}
				],
				ret: member.ret.toComplexType(),
				expr: isVoid ? call : macro return $call,
			}),
			pos: pos,
		};
	}

	// A static property reading member on instance and, where member can be assigned, assigning it.
	static function property(member:Member, pos:Position):Array<Field> {
		var name = member.name;
		var t = member.t.toComplexType();
		var made:Array<Field> = [
			{
				name: name,
				doc: member.doc,
				access: [APublic, AStatic],
				kind: FProp(member.read ? "get" : "never", member.write ? "set" : "never", t),
				pos: pos,
			}
		];
		if (member.read)
			made.push({
				name: "get_" + name,
				meta: [{name: ":noCompletion", pos: pos}],
				access: [AStatic],
				kind: FFun({args: [], ret: t, expr: macro return $reach.$name}),
				pos: pos,
			});
		if (member.write)
			made.push({
				name: "set_" + name,
				meta: [{name: ":noCompletion", pos: pos}],
				access: [AStatic],
				kind: FFun({args: [{name: "value", type: t}], ret: t, expr: macro return $reach.$name = value}),
				pos: pos,
			});
		return made;
	}
}

/** A member a static class forwards: a method (args and ret) or a variable or property (t, read and write). */
typedef Member = {
	/** Its name. */
	var name:String;

	/** Its doc comment, copied onto the forwarder. */
	var ?doc:String;

	/** A method's arguments: each one's name, whether it may be left out, its default and its type. */
	var ?args:Array<{
		name:String,
		opt:Bool,
		value:Null<Expr>,
		t:Type
	}>;

	/** A method's result. */
	var ?ret:Type;

	/** A variable's or property's type. */
	var ?t:Type;

	/** Whether a variable or property can be read. */
	var ?read:Bool;

	/** Whether a variable or property can be assigned. */
	var ?write:Bool;
}
#end
