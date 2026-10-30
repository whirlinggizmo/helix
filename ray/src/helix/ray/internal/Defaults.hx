package helix.ray.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Holds raylib's default shader, compiled as the program builds. */
@:noCompletion
class Defaults {
	/** Returns raylib's default shader. */
	public static macro function shader():ExprOf<ProgramSource> {
		return ShaderMacro.program("raylib default vertex shader", null, "raylib default fragment shader", null, Context.currentPos());
	}
}
