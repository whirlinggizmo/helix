package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.TypedExprTools;
#end

/** Refuses a `cast` from an object to a class in the program's own code, on every target: `cast {button: GAMEPAD_BUTTON_MIDDLE_RIGHT}`
	where a `VirtualButtonOptions` is expected. A page reads the object's fields by name, so it works there, and natively the object is
	read as the class and crashes. Read from the compiler's typed code, after typing. Run by the library's `extraParams.hxml`. */
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
			case TCast(inner, null) if (ProgramCode.own(e.pos)):
				switch [TypeTools.follow(inner.t), TypeTools.follow(e.t)] {
					case [TAnonymous(_), TInst(_.get() => c, _)] if (!c.kind.match(KTypeParameter(_))):
						var name = c.name;
						var instead = c.meta.has(":structInit") ? 'Write the object in braces where a $name is expected, without cast.' : c.constructor != null ? 'Make one with new $name().' : 'Use a $name the library gives.';
						Context.reportError('cast: Not supported from an object to $name, a class. $instead', e.pos);
					case _:
				}
			case _:
		}
		TypedExprTools.iter(e, walk);
	}
	#end
}
