package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Holds helix-raylib's model shaders, compiled as the program builds from its files in `helix/raylib/shaders/`: raylib's default
	(unlit), the lit one, the PBR one, each one's skinned twin, and the sprite shader. */
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

	/** Returns helix-raylib's lit shader, raylib's examples' lighting (`LoadLightingShader`). */
	public static macro function litShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("helix-raylib lit vertex shader", ShaderMacro.builtIn("lit.vs", pos), "helix-raylib lit fragment shader",
			ShaderMacro.builtIn("lit.fs", pos), pos);
	}

	/** Returns the lit shader skinned: its vertex stage moving each vertex and normal by its bones from the frame's bone palette, its
		fragment stage the lit one's. `Skinning` draws a posed mesh through it in place of the lit shader, so only a program that loads
		the lit shader and poses a model links it. */
	public static macro function litSkinnedShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("helix-raylib lit vertex shader, skinned", ShaderMacro.builtIn("lit_skinned.vs", pos), "helix-raylib lit fragment shader",
			ShaderMacro.builtIn("lit.fs", pos), pos);
	}

	/** Returns helix-raylib's PBR shader, a glTF's material drawn as authored under rlights' lights (`LoadPbrShader`). */
	public static macro function pbrShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("helix-raylib PBR vertex shader", ShaderMacro.builtIn("pbr.vs", pos), "helix-raylib PBR fragment shader",
			ShaderMacro.builtIn("pbr.fs", pos), pos);
	}

	/** Returns the PBR shader's unlit twin, for a material marked `unlit`: its vertex stage the PBR one's, its fragment stage the base color
		as authored and no light (`pbr_unlit.fs`). `DrawMesh` draws such a material through it in place of the PBR shader. */
	public static macro function pbrUnlitShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("helix-raylib PBR vertex shader", ShaderMacro.builtIn("pbr.vs", pos), "helix-raylib PBR unlit fragment shader",
			ShaderMacro.builtIn("pbr_unlit.fs", pos), pos);
	}

	/** Returns the PBR shader's unlit twin skinned, for a posed mesh whose material is marked `unlit`. */
	public static macro function pbrUnlitSkinnedShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("helix-raylib PBR vertex shader, skinned", ShaderMacro.builtIn("pbr_skinned.vs", pos),
			"helix-raylib PBR unlit fragment shader", ShaderMacro.builtIn("pbr_unlit.fs", pos), pos);
	}

	/** Returns the PBR shader skinned: its vertex stage moving each vertex, normal and tangent by its bones from the frame's bone palette,
		its fragment stage the PBR one's. `Skinning` draws a posed mesh through it in place of the PBR shader, so only a program that loads
		the PBR shader and poses a model links it. */
	public static macro function pbrSkinnedShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("helix-raylib PBR vertex shader, skinned", ShaderMacro.builtIn("pbr_skinned.vs", pos), "helix-raylib PBR fragment shader",
			ShaderMacro.builtIn("pbr.fs", pos), pos);
	}
}
