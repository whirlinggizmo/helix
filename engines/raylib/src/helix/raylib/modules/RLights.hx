package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.internal.Defaults;
import helix.raylib.extras.Lights.*;
#end

/** Holds raylib's examples' lights (`examples/shaders/rlights.h`, raylib 5.5) and helix-raylib's lit and PBR shaders built on them.
	Each is written here, and `helix.raylib.extras.Lights` forwards to each (`tools/gen_raylib.py`). */
@:noCompletion
@:allow(helix.raylib)
class RLights {
	#if !macro
	// The lights made, as rlights counts them: each takes the next of a lit shader's lights, MAX_LIGHTS at most.
	static var lightsCount:Null<Int>;
	// One texel of a flat normal, which a PBR shader's normalMap reads for a material without one; made with the first PBR shader.
	static var flatNormal:Null<Texture2D>;

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

	/** Returns helix-raylib's PBR shader: a glTF's materials drawn as authored, metallic-roughness under rlights' lights, built in.
		raylib's examples' lighting shader has no roughness or metallic input, so every material shines alike under it; this one reads
		each material's maps and values as `LoadModel` reads a glTF's. Its locations are set as raylib's basic PBR example sets them:
		`locs[SHADER_LOC_VECTOR_VIEW]` is `viewPos`, which the program sets to the camera's position each frame, and
		`locs[SHADER_LOC_MAP_ALBEDO]`, `SHADER_LOC_MAP_METALNESS`, `SHADER_LOC_MAP_ROUGHNESS`, `SHADER_LOC_MAP_NORMAL`,
		`SHADER_LOC_MAP_OCCLUSION` and `SHADER_LOC_MAP_EMISSION` are its samplers `albedoMap`, `metalnessMap`, `roughnessMap`,
		`normalMap`, `occlusionMap` and `emissiveMap`, each set to its map's unit, so `DrawMesh` binds the material's map with a texture
		there; a map without one reads white, the normal map a flat normal. A mesh without tangents whose material has a normal map
		gets them with its first draw (`GenMeshTangents`), as glTF asks of a file without them. Each draw writes the material's values:
		`maps[MATERIAL_MAP_ALBEDO].color` times the tint as `colDiffuse`, `maps[MATERIAL_MAP_METALNESS].value` as `metallicValue`,
		`maps[MATERIAL_MAP_ROUGHNESS].value` as `roughnessValue` and `maps[MATERIAL_MAP_EMISSION].color` as `emissiveColor`, the colors
		taken as linear, as a glTF's factors are, where an image's texels are decoded from sRGB. A material from `LoadMaterialDefault`
		is a smooth non-metal, both values 0, until set. A material marked `unlit` (glTF's `KHR_materials_unlit`) is drawn through the
		shader's unlit twin, its base color as authored and no light. Lights are added with `CreateLight` and
		`GetShaderLocation(shader, "ambient")` finds the ambient color, as for the lit shader, a light's color what a white surface
		facing it shows. A model posed by `UpdateModelAnimation` under it is skinned on the GPU. Its stages are
		`helix/raylib/shaders/pbr.vs` and `pbr.fs`, over `<helix/raylib/shaders/pbr.glsl>`, which a program's own shader can include.

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
		var shader = @:privateAccess RModels.makeShader(Defaults.pbrShader());
		// Its skinned twin, drawn for a mesh UpdateModelAnimation posed.
		shader.program.skinned = Defaults.pbrSkinnedShader();
		// Its unlit twin, drawn for a material marked unlit, and that one's skinned twin.
		shader.program.unlit = Defaults.pbrUnlitShader();
		shader.program.unlitSkinned = Defaults.pbrUnlitSkinnedShader();
		shader.program.material = true;
		RModels.materialWriter = writeMaterial;
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

	// Writes a material's values for a draw through the PBR shader or a twin (Program.writeMaterial), and first gives a mesh without
	// tangents whose material has a normal map its tangents (GenMeshTangents), as glTF asks of a file without them.
	static function writeMaterial(p:helix.raylib.internal.Program, mesh:Mesh, material:Material):Void {
		if (mesh.tangents == null
			&& mesh.texcoords != null
			&& mesh.normals != null
			&& material.maps[MATERIAL_MAP_NORMAL].texture.id > 0)
			RModels.GenMeshTangents(mesh);
		p.writeMaterial(material);
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
