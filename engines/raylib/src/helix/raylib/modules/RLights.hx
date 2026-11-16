package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.Rlights.*;
#end

/** Holds rlights, the lights raylib 5.5's lighting examples include (`examples/shaders/rlights.h`). Each is written here, and
	`helix.raylib.Rlights` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RLights {
	#if !macro
	/** Makes a light of the scene, as rlights' `CreateLight` makes one of a shader. The light shines on every lit draw, whichever shader
		it was made with: the Lighting extra's `LoadLightingShader` and `LoadPbrShader`, and a shader declaring rlights' `lights`, such as
		raylib's examples' `lighting.fs` or one including `<helix/raylib/shaders/lights.glsl>`. A program makes as many lights as it needs.

		Each draw is lit by the lights reaching it most, as many as its shader's `lights` holds, 8 at most. The light's fields are read at
		each draw, so the light moves or changes by setting them. The Lighting extra sets its intensity, range and cone, and `UnloadLight`
		takes it out of the scene.

		@param type  `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
		@param position  Where it is.
		@param target  Where it points, for a directional light.
		@param color  Its color.
		@param shader  The shader it is made with, as rlights takes one.
		@return  The light. */
	static function CreateLight(type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light {
		var light = new Light();
		light.enabled = true;
		light.type = type;
		light.position = position;
		light.target = target;
		light.color = color;
		helix.raylib.internal.SceneLights.add(light);
		return light;
	}

	/** Kept as rlights' `UpdateLightValues`, for a program written for rlights. A light's fields are read at each draw, so the draws
		after a change show it with or without this call.

		@param shader  The shader.
		@param light  The light. */
	static function UpdateLightValues(shader:Shader, light:Light):Void {}
	#end
}
