package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.internal.Defaults;
#end

/** Holds helix-raylib's lit and PBR shaders, lit by the scene's lights (rlights' `CreateLight`), and what the Lighting extra sets on a
	light. Each is written here, and `helix.raylib.extras.Lighting` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RLighting {
	#if !macro
	// One texel of a flat normal, which a PBR shader's normalMap reads for a material without one; made with the first PBR shader.
	static var flatNormal:Null<Texture2D>;

	/** Returns raylib's examples' lighting shader (`lighting.vs` and `lighting.fs`), built in. It shines every material alike, one
		Phong highlight whatever the material says. See `LoadPbrShader` for drawing a glTF's materials as authored.

		Set up as raylib's lighting example does: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame;
		`GetShaderLocation(shader, "ambient")` finds the ambient color. The scene's lights light it (see the class).

		```haxe
		var shader = LoadLightingShader();
		SetShaderValue(shader, GetShaderLocation(shader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
		model.materials[0].shader = shader;
		var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), Vector3Zero(), YELLOW, shader);
		```

		@return  The shader, the program's until `UnloadShader`. */
	static function LoadLightingShader():Shader {
		var shader = @:privateAccess RModels.makeShader(Defaults.litShader());
		// Its skinned twin, drawn for a mesh UpdateModelAnimation posed (Skinning).
		shader.program.mirror(new helix.raylib.internal.Program(helix.raylib.internal.Runtime.graphics, Defaults.litSkinnedShader()));
		startIntensities(shader);
		helix.raylib.internal.Surfaces.install();
		return shader;
	}

	/** Returns helix-raylib's PBR shader, built in: a glTF's materials drawn as authored, metallic-roughness under the scene's lights,
		where `LoadLightingShader` shines every material alike.

		Set up as that one: `locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, set to the camera's position each frame; `GetShaderLocation(shader,
		"ambient")` finds the ambient color. A light's color is what a white surface facing it shows at intensity 1. Light brighter than
		white rolls off toward white instead of clipping, and colors in the usual range come out as authored. A material marked `unlit`
		(glTF's `KHR_materials_unlit`) draws its base color and no light.

		Each draw reads the material's maps `MATERIAL_MAP_ALBEDO`, `MATERIAL_MAP_METALNESS`, `MATERIAL_MAP_ROUGHNESS`,
		`MATERIAL_MAP_NORMAL`, `MATERIAL_MAP_OCCLUSION` and `MATERIAL_MAP_EMISSION`. Their samplers are `albedoMap`, `metalnessMap`,
		`roughnessMap`, `normalMap`, `occlusionMap` and `emissiveMap`, found at `locs[SHADER_LOC_MAP_ALBEDO]` and the five after it. A
		missing map reads white, and a missing normal map reads a flat normal.

		Each draw also reads the material's values. `maps[MATERIAL_MAP_ALBEDO].color` times the tint is `colDiffuse`.
		`maps[MATERIAL_MAP_METALNESS].value` is `metallicValue`, and `maps[MATERIAL_MAP_ROUGHNESS].value` is `roughnessValue`. Its
		emission and alpha cutoff are the Materials extra's. Colors are taken as linear, as a glTF's factors are. An image's texels are
		decoded from sRGB. A material from `LoadMaterialDefault` is a smooth non-metal, both values 0, until set.

		A mesh without tangents under a normal map gets them with its first draw (`GenMeshTangents`).

		```haxe
		var pbr = LoadPbrShader();
		SetShaderValue(pbr, GetShaderLocation(pbr, "ambient"), [0.2, 0.2, 0.2, 1.0], SHADER_UNIFORM_VEC4);
		CreateLight(LIGHT_DIRECTIONAL, new Vector3(2, 4, 2), Vector3Zero(), WHITE, pbr);
		for (m in model.materials)
			m.shader = pbr;
		// each frame
		SetShaderValue(pbr, pbr.locs[SHADER_LOC_VECTOR_VIEW], [camera.position.x, camera.position.y, camera.position.z],
			SHADER_UNIFORM_VEC3);
		```

		@return  The shader, the program's until `UnloadShader`. */
	static function LoadPbrShader():Shader {
		var p = new helix.raylib.internal.LitProgram(helix.raylib.internal.Runtime.graphics, Defaults.pbrShader());
		var shader = @:privateAccess new Shader(p.handle, RModels.locations(p), p);
		// Its skinned twin, drawn for a mesh UpdateModelAnimation posed (Skinning).
		p.mirror(new helix.raylib.internal.LitProgram(helix.raylib.internal.Runtime.graphics, Defaults.pbrSkinnedShader()));
		startIntensities(shader);
		helix.raylib.internal.Surfaces.install();
		var samplers = [
			MATERIAL_MAP_ALBEDO => "albedoMap",
			MATERIAL_MAP_METALNESS => "metalnessMap",
			MATERIAL_MAP_ROUGHNESS => "roughnessMap",
			MATERIAL_MAP_NORMAL => "normalMap",
			MATERIAL_MAP_OCCLUSION => "occlusionMap",
			MATERIAL_MAP_EMISSION => "emissiveMap"
		];
		for (map => name in samplers) {
			var location = GetShaderLocation(shader, name);
			shader.locs[SHADER_LOC_MAP_ALBEDO + map] = location;
			// The sampler reads its map's unit, which its twins take over by name.
			SetShaderValue(shader, location, map, SHADER_UNIFORM_INT);
		}
		// A material without a normal map reads a flat one, where a missing map reads white.
		if (flatNormal == null) {
			flatNormal = RTextures.LoadTextureFromImage(RTextures.GenImageColor(1, 1, new Color(128, 128, 255, 255)));
			// Sent again after the GPU's context is restored.
			helix.raylib.internal.Textures.keepPixels(flatNormal.id);
		}
		SetShaderValueTexture(shader, shader.locs[SHADER_LOC_MAP_NORMAL], flatNormal);
		return shader;
	}

	/** Sets how bright a light is: its color times the intensity. 1 until set; 0 gives no light, as `enabled` false does.

		@param light  The light, from `CreateLight`.
		@param intensity  How bright, 0 or more. */
	static function SetLightIntensity(light:Light, intensity:Float):Void {
		@:privateAccess light.intensity = intensity > 0 ? intensity : 0;
	}

	/** Sets how far a point or spot light reaches: it dims with distance, fading to nothing at the range, and lights no draw whose
		bounds lie past it. 0, the default, is no falloff and no limit. A directional light has no range.

		@param light  The light, from `CreateLight`.
		@param range  How far, in world units, 0 or more. */
	static function SetLightRange(light:Light, range:Float):Void {
		@:privateAccess light.range = range > 0 ? range : 0;
	}

	/** Makes a light a spot light (`LIGHT_SPOT`), shining from its position toward its target in a cone: full inside `innerAngle`,
		fading to nothing at `outerAngle`, each measured from the cone's middle. A spot light dims with distance as a point light does.

		@param light  The light, from `CreateLight`.
		@param innerAngle  Where the fade starts, in degrees.
		@param outerAngle  Where it ends, in degrees, at least `innerAngle` and under 90. */
	static function SetLightCone(light:Light, innerAngle:Float, outerAngle:Float):Void {
		var outer = outerAngle < 0 ? 0 : outerAngle > 89.9 ? 89.9 : outerAngle;
		var inner = innerAngle < 0 ? 0 : innerAngle > outer ? outer : innerAngle;
		light.type = helix.raylib.extras.Lighting.LIGHT_SPOT;
		@:privateAccess light.innerCosine = Math.cos(inner * DEG2RAD);
		@:privateAccess light.outerCosine = Math.cos(outer * DEG2RAD);
	}

	/** Takes a light out of the scene. It lights nothing after.

		@param light  The light, from `CreateLight`. */
	static function UnloadLight(light:Light):Void {
		helix.raylib.internal.SceneLights.remove(light);
	}

	// Starts each of a lit shader's lights at intensity 1, as lights.glsl's lights are until set: its MAX_LIGHTS, 8.
	static function startIntensities(shader:Shader):Void {
		for (i in 0...8)
			SetShaderValue(shader, GetShaderLocation(shader, 'lights[$i].intensity'), 1.0, SHADER_UNIFORM_FLOAT);
	}
	#end
}
