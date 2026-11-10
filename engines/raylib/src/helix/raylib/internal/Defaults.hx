package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Holds helix-raylib's model shaders, compiled as the program builds from its files in `helix/raylib/shaders/`: raylib's default,
	its skinned twin, and the sprite shader. */
@:noCompletion
class Defaults {
	/** Returns raylib's default shader. */
	public static macro function shader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.program("raylib default vertex shader", null, "raylib default fragment shader", null, Context.currentPos());
	}

	/** Returns helix-raylib's sprite shader: raylib's default fragment stage over a vertex stage drawing a run of quads of one texture as
		instances of one quad (`Frame`'s sprite runs), each a record of its corners, texture rectangle and color. */
	public static macro function spriteShader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.sprites(Context.currentPos());
	}

	/** Returns raylib's default shader skinned: its vertex stage moving each vertex by its bones from the frame's bone palette, its
		fragment stage the default's. `Skinning` draws a posed mesh through it in place of the default shader, so a program that never
		poses a model (`UpdateModelAnimation`) links none of it. */
	public static macro function skinnedShader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.program("raylib default vertex shader, skinned", ShaderMacro.builtIn("unlit_skinned.vs", Context.currentPos()),
			"raylib default fragment shader", null, Context.currentPos());
	}
}
