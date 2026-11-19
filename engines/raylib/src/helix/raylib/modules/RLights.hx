package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.extras.*;
import helix.raylib.extras.Lighting.*;
#end

/** Holds the scene's lights, made as raylib 5.5's lighting examples' `rlights.h` makes them. Each is written here, and
	`helix.raylib.extras.Lighting` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RLights {
	#if !macro
	/** Makes a light of the scene, as `CreateLight` in raylib's lighting examples' `rlights.h` makes one of a shader. The light shines on every lit draw, whichever shader
		it was made with: the Lighting extra's `LoadLightingShader` and `LoadPbrShader`, and a shader declaring rlights' `lights`, such as
		raylib's examples' `lighting.fs` or one including `<helix/raylib/shaders/lights.glsl>`. A program makes as many lights as it needs.

		Each draw is lit by the lights reaching it most, as many as its shader's `lights` holds, 8 at most. The light's fields are read at
		each draw, so the light moves or changes by setting them, the Lighting extra's `intensity`, `range` and spot cone among them.
		`UnloadLight` removes the light from the scene.

		@param type  `LIGHT_DIRECTIONAL`, `LIGHT_POINT`, or the Lighting extra's `LIGHT_SPOT`.
		@param position  Where it is.
		@param target  Where it points, for a directional or spot light.
		@param color  Its color.
		@param shader  The shader it is made with, as rlights accepts one.
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

	/** Kept as `UpdateLightValues` in raylib's lighting examples' `rlights.h`, for a program written for it. A light's fields are read at each draw, so the draws
		after a change show it with or without this call.

		@param shader  The shader.
		@param light  The light. */
	static function UpdateLightValues(shader:Shader, light:Light):Void {}
	#end
}
