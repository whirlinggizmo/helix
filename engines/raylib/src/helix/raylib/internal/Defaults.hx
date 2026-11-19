package helix.raylib.internal;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/** Holds helix-raylib's model shaders, compiled as the program builds from its files in `helix/raylib/shaders/`: raylib's default
	(unlit), its variant reading a material's values, the lit one, the PBR one, each one's skinned twin, the shadow pass's, the sprite
	shader, and the particle shaders. */
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

	/** Returns helix-raylib's particle shader (the Particles extra's 3D emitters): a vertex stage working each particle out from its age
		(`shaders/particle.vs`), whose attributes are a quad's corner and an instance's number, not raylib's, over a fragment stage tinting
		the texture by the particle's color. */
	public static macro function particleShader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.particles("particle.fs", Context.currentPos());
	}

	/** Returns the particle shader lit (an `Emitter3D`'s `lit`): its fragment stage lighting the particle by the scene's lights at its
		place. */
	public static macro function particleLitShader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.particles("particle_lit.fs", Context.currentPos());
	}

	/** Returns raylib's default shader skinned: its vertex stage moving each vertex by its bones from the frame's bone palette, its
		fragment stage the default's. `Skinning` draws a posed mesh through it in place of the default shader, so a program that never
		poses a model (`UpdateModelAnimation`) links none of it. */
	public static macro function skinnedShader():ExprOf<helix.services.shaders.Shader> {
		return ShaderMacro.program("raylib default vertex shader, skinned", ShaderMacro.builtIn("unlit_skinned.vs", Context.currentPos()),
			"raylib default fragment shader", null, Context.currentPos());
	}

	/** Returns raylib's default shader reading a material's values (the Materials extra's): its fragment stage cutting the material out
		below its alpha cutoff and adding the light it and its model emit. The Materials extra draws through it a material drawn with
		the default shader that is cut out or emits light, so a program not using the extra links none of it. */
	public static macro function materialShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("raylib default vertex shader", null, "helix-raylib material fragment shader",
			ShaderMacro.builtIn("unlit_material.fs", pos), pos);
	}

	/** Returns the material shader skinned: its vertex stage the default's skinned one, its fragment stage the material one's. */
	public static macro function materialSkinnedShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("raylib default vertex shader, skinned", ShaderMacro.builtIn("unlit_skinned.vs", pos),
			"helix-raylib material fragment shader", ShaderMacro.builtIn("unlit_material.fs", pos), pos);
	}

	/** Returns the shadow pass's shader for helix-raylib's own shaders (`Shadows`): raylib's default vertex stage, which places a vertex
		as the lit and PBR ones do, and a fragment stage writing depth alone, cut at the material's alpha cutoff. Only a program casting
		shadows links it. */
	public static macro function shadowShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("raylib default vertex shader", null, "helix-raylib shadow fragment shader", ShaderMacro.builtIn("shadow_cut.fs", pos), pos);
	}

	/** Returns the shadow pass's shader for helix-raylib's own skinned shaders: the default's skinned vertex stage, which skins as the
		lit and PBR ones do, and the shadow fragment stage. */
	public static macro function shadowSkinnedShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("raylib default vertex shader, skinned", ShaderMacro.builtIn("unlit_skinned.vs", pos),
			"helix-raylib shadow fragment shader", ShaderMacro.builtIn("shadow_cut.fs", pos), pos);
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

	/** Returns the PBR shader skinned: its vertex stage moving each vertex, normal and tangent by its bones from the frame's bone palette,
		its fragment stage the PBR one's. `Skinning` draws a posed mesh through it in place of the PBR shader, so only a program that loads
		the PBR shader and poses a model links it. */
	public static macro function pbrSkinnedShader():ExprOf<helix.services.shaders.Shader> {
		var pos = Context.currentPos();
		return ShaderMacro.program("helix-raylib PBR vertex shader, skinned", ShaderMacro.builtIn("pbr_skinned.vs", pos), "helix-raylib PBR fragment shader",
			ShaderMacro.builtIn("pbr.fs", pos), pos);
	}
}
