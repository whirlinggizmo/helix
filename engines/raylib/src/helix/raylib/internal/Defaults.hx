package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Holds raylib's default shader, and its skinned twin, compiled as the program builds. */
@:noCompletion
class Defaults {
	/** Returns raylib's default shader. */
	public static macro function shader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.program("raylib default vertex shader", null, "raylib default fragment shader", null, Context.currentPos());
	}

	/** Returns raylib's default shader skinned: its vertex stage moving each vertex by its bones from the frame's bone palette, its
		fragment stage the default's. `Skinning` draws a posed mesh through it in place of the default shader, so a program that never
		poses a model (`UpdateModelAnimation`) links none of it. */
	public static macro function skinnedShader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.program("raylib default vertex shader, skinned", ShaderMacro.builtIn("unlit_skinned.vs", Context.currentPos()),
			"raylib default fragment shader", null, Context.currentPos());
	}
}
