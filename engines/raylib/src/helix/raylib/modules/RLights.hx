package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.internal.Defaults;
import helix.raylib.extras.Lights.*;
#end

/** Holds raylib's examples' lights (`examples/shaders/rlights.h`, raylib 5.5) and helix-raylib's lit shader built on them. Each is
	written here, and `helix.raylib.extras.Lights` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RLights {
	#if !macro
	// The lights made, as rlights counts them: each takes the next of a lit shader's lights, MAX_LIGHTS at most.
	static var lightsCount:Null<Int>;

	/** Returns helix-raylib's lit shader: raylib's examples' `lighting.vs` and `lighting.fs`, built in, so a program needs no shader
		files. Its locations are set as raylib's lighting example sets them: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, which the
		program sets to the camera's position each frame; `GetShaderLocation(shader, "ambient")` finds the ambient color. Lights are
		added with `CreateLight`. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. Its stages are
		`helix/raylib/shaders/lit.vs` and `lit.fs`, over `<helix/raylib/shaders/lights.glsl>`, which a program's own shader can include.

		```haxe
		var shader = LoadLightingShader();
		var ambientLoc = GetShaderLocation(shader, "ambient");
		SetShaderValue(shader, ambientLoc, [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
		model.materials[0].shader = shader;
		var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
		```
		@return  The shader, the program's until `UnloadShader`. */
	static function LoadLightingShader():Shader {
		var shader = @:privateAccess RModels.makeShader(Defaults.litShader());
		// Its skinned twin, drawn for a mesh UpdateModelAnimation posed.
		shader.program.skinned = Defaults.litSkinnedShader();
		return shader;
	}

	/** Makes a light and sets it in a lit shader, as rlights' `CreateLight`: the next of the shader's `lights`, its locations found by
		name (`lights[0].enabled` and the rest). Past `MAX_LIGHTS` lights it makes a light that is off and sets nothing. The count is the
		program's, as rlights' is, not the shader's.

		@param type  `LIGHT_DIRECTIONAL` or `LIGHT_POINT`.
		@param position  Where it is.
		@param target  Where it points, for a directional light.
		@param color  Its color.
		@param shader  The lit shader.
		@return  The light. */
	static function CreateLight(type:Int, position:Vector3, target:Vector3, color:Color, shader:Shader):Light {
		var light = new Light();
		var count = lightsCount == null ? 0 : lightsCount;
		if (count < MAX_LIGHTS) {
			light.enabled = true;
			light.type = type;
			light.position = position;
			light.target = target;
			light.color = color;
			light.enabledLoc = GetShaderLocation(shader, 'lights[$count].enabled');
			light.typeLoc = GetShaderLocation(shader, 'lights[$count].type');
			light.positionLoc = GetShaderLocation(shader, 'lights[$count].position');
			light.targetLoc = GetShaderLocation(shader, 'lights[$count].target');
			light.colorLoc = GetShaderLocation(shader, 'lights[$count].color');
			UpdateLightValues(shader, light);
			lightsCount = count + 1;
		}
		return light;
	}

	/** Sets a light's values in a lit shader, as rlights' `UpdateLightValues`: whether it is on, its type, position, target and color,
		for the draws after it.

		@param shader  The lit shader.
		@param light  The light. */
	static function UpdateLightValues(shader:Shader, light:Light):Void {
		SetShaderValue(shader, light.enabledLoc, light.enabled ? 1 : 0, SHADER_UNIFORM_INT);
		SetShaderValue(shader, light.typeLoc, light.type, SHADER_UNIFORM_INT);
		SetShaderValue(shader, light.positionLoc, [light.position.x, light.position.y, light.position.z], SHADER_UNIFORM_VEC3);
		SetShaderValue(shader, light.targetLoc, [light.target.x, light.target.y, light.target.z], SHADER_UNIFORM_VEC3);
		SetShaderValue(shader, light.colorLoc, [
			light.color.r / 255,
			light.color.g / 255,
			light.color.b / 255,
			light.color.a / 255
		], SHADER_UNIFORM_VEC4);
	}
	#end
}
