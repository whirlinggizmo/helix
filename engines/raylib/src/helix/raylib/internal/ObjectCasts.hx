package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.TypedExprTools;
#end

/** Refuses a `cast` from an object to a class or an abstract in the program's own code, on every target: `cast {button:
	GAMEPAD_BUTTON_MIDDLE_RIGHT}` where a `VirtualButtonOptions` is expected, or `cast {r: 230, g: 41, b: 55, a: 255}` where a `Color` is.
	An unchecked cast converts nothing. A page reads the object's fields by name, so a class's worked there, and natively the object is
	read as the class and crashes. An abstract over a value, as `Color` is over `Int`, reads the object as that value on every target.
	Read from the compiler's typed code, after typing. Run by the library's `extraParams.hxml`. */
@:noCompletion
class ObjectCasts {
	#if macro
	static var done = false;

	/** Looks at the program's code once it is typed. */
	public static function register():Void {
		Context.onAfterTyping(types -> {
			if (done)
				return;
			done = true;
			for (e in ProgramCode.bodies(types))
				walk(e);
		});
	}

	static function walk(e:TypedExpr):Void {
		switch e.expr {
			case TCast(inner, null) if (ProgramCode.own(e.pos) && TypeTools.follow(inner.t).match(TAnonymous(_))):
				var instead = refused(TypeTools.follow(e.t));
				if (instead != null)
					Context.reportError('cast: Not supported from an object to ${instead.name}. ${instead.write}', e.pos);
			case _:
		}
		TypedExprTools.iter(e, walk);
	}

	// What a cast from an object to a type is refused with: the type's name, and how to write one. Null for a type an object is, or
	// may be: an anonymous structure, Dynamic, a type parameter, an abstract over one of those, or a core type.
	static function refused(t:Type):Null<{name:String, write:String}> {
		switch t {
			case TAbstract(_.get() => {pack: [], name: "Null"}, [inner]):
				return refused(TypeTools.follow(inner));
			case TInst(_.get() => c, _) if (!c.kind.match(KTypeParameter(_))):
				var write = c.meta.has(":structInit") ? 'Write the object in braces where a ${c.name} is expected, without cast.' : c.constructor != null ? 'Make one with new ${c.name}().' : 'Use a ${c.name} the library gives.';
				return {name: '${c.name}, a class', write: write};
			case TAbstract(_.get() => a, _) if (!a.meta.has(":coreType")):
				switch TypeTools.follow(a.type) {
					case TAnonymous(_) | TDynamic(_) | TMono(_) | TInst(_.get() => {kind: KTypeParameter(_)}, _):
						return null;
					case _:
				}
				var fromObject = Lambda.exists(a.from, from -> TypeTools.follow(from.t).match(TAnonymous(_)));
				var made = a.impl != null && Lambda.exists(a.impl.get().statics.get(), f -> f.name == "_new");
				var write = fromObject ? 'Write the object in braces where a ${a.name} is expected, without cast.' : made ? 'Make one with new ${a.name}().' : 'Use a ${a.name} the library gives.';
				return {name: a.name, write: write};
			case _:
				return null;
		}
	}
	#end
}
