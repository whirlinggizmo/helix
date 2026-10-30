package helix.ray.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

/** Makes `@:unimplemented("message")` on one of `Raylib`'s functions stop every build that calls it, on every target, with the message
	at each call.

	The function stays declared, with raylib's name and signature, so a program that guessed it is told what to use instead. The
	compiler does the refusing: the meta becomes `@:require` of a define no program sets. Only `Raylib` is built so: a program can't
	reach the sections, whose functions are private to helix-ray, and they import each other's, which a build macro would break. */
class Unimplemented {
	/** Adds `build` to `Raylib`. Run by `Loop.install`. */
	public static function install():Void {
		haxe.macro.Compiler.addMetadata("@:build(helix.ray.internal.Unimplemented.build())", "helix.ray.Raylib");
	}

	/** Gives each function marked `@:unimplemented` the `@:require` that refuses its calls. */
	public static function build():Null<Array<Field>> {
		var fields = Context.getBuildFields();
		var changed = false;
		for (field in fields)
			for (meta in field.meta)
				if (meta.name == ":unimplemented") {
					var flag = {expr: EConst(CIdent("helix_ray_unimplemented")), pos: meta.pos};
					field.meta.push({name: ":require", params: [flag].concat(meta.params), pos: meta.pos});
					changed = true;
					break;
				}
		return changed ? fields : null;
	}
}
#end
