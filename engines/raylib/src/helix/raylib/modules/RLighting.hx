package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Light;
import helix.raylib.modules.RCore.*;
import helix.raylib.internal.Defaults;
#end

/** Holds helix-raylib's lit and PBR shaders, lit by the scene's lights (`CreateLight`), the shadow pass, and turning a light's
	shadows on and off. Each is written here, and `helix.raylib.extras.Lighting` forwards to each (`tools/gen_raylib.py`). */
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
		var light = CreateLight(LIGHT_POINT, new Vector3(-2, 1, -2), new Vector3(0, 0, 0), YELLOW, shader);
		```

		@return  The shader, the program's until `UnloadShader`. */
	static function LoadLightingShader():Shader {
		var shader = @:privateAccess RModels.makeShader(Defaults.litShader());
		// Its skinned twin, drawn for a mesh UpdateModelAnimation posed (Skinning).
		shader.program.mirror(new helix.raylib.internal.Program(helix.raylib.internal.Runtime.graphics, Defaults.litSkinnedShader()));
		startIntensities(shader);
		helix.raylib.internal.Surfaces.install();
		helix.raylib.internal.ShadowSlots.bind(shader.program, 0);
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
		CreateLight(LIGHT_DIRECTIONAL, new Vector3(2, 4, 2), new Vector3(0, 0, 0), WHITE, pbr);
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
		helix.raylib.internal.ShadowSlots.bind(shader.program, 0);
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

	/** Takes a light out of the scene. It lights nothing after, and its shadows are freed.

		@param light  The light, from `CreateLight`. */
	static function UnloadLight(light:Light):Void {
		helix.raylib.internal.SceneLights.remove(light);
		// Its place among the lights casting shadows is let go of by the next shadow pass (Shadows).
		@:privateAccess light.shadowCasting = false;
		@:privateAccess light.shadowIndex = 0;
	}

	/** Turns a light's shadows on. A light casts none until then. The light's `shadows` say how its shadows are made.

		4 lights cast shadows at most. Enabling a fifth's is refused, with a warning, and the fifth casts none. `DisableLightShadows` and
		`UnloadLight` free a light's place for another.

		@param light  The light, from `CreateLight`.
		@return  False when refused, as 4 other lights cast shadows. */
	static function EnableLightShadows(light:Light):Bool {
		return helix.raylib.internal.Shadows.addCaster(light);
	}

	/** Turns a light's shadows off, freeing its place among the 4 lights that may cast them. Its `shadows` are kept.

		@param light  The light, from `CreateLight`. */
	static function DisableLightShadows(light:Light):Void {
		@:privateAccess light.shadowCasting = false;
		@:privateAccess light.shadowIndex = 0;
	}

	/** Returns whether a light casts shadows (`EnableLightShadows`).

		@param light  The light, from `CreateLight`.
		@return  true when it casts shadows. */
	static function IsLightCastingShadows(light:Light):Bool {
		return @:privateAccess light.shadowCasting;
	}

	/** Starts the frame's shadow pass, until `EndShadowMode`: what is drawn casts shadows, from every light that casts them, and is
		drawn nowhere else. Call it before `BeginDrawing`, or after it and before `BeginMode3D`, not within a 3D or texture mode.

		Draw the casters as the frame draws them, models and meshes posed and placed the same. Each draw runs its own shader's vertex
		stage, so a caster swaying, skinned or instanced there casts its shadow as it is drawn, and writes depth alone. A material with
		an alpha cutoff (the Materials extra) casts nothing where its albedo's alpha is below the cutoff. Each light's maps take what was
		drawn once, less the draws whose bounds fall outside a map's view.

		- **What a shadow keeps:** the vertex stage, given the same uniforms as the draw (bone matrices, a sway's time), and the
		  material's alpha cutoff. A fragment stage's own `discard` (a dissolve) isn't in the shadow.
		- **Cut out:** only where the vertex stage passes on `fragTexCoord`, which the cutoff samples the albedo at. A vertex stage
		  without it casts its whole shape.
		- **Cost:** every cascade and every face of a point light draws the casters again. A point light's shadows cost about six
		  times a directional light's single map.

		@param camera  The camera the frame is drawn from, which a directional light's shadows follow. */
	static function BeginShadowMode(camera:Camera3D):Void {
		helix.raylib.internal.Shadows.begin(camera);
	}

	/** Ends the shadow pass `BeginShadowMode` began. The lit draws after it receive its shadows. */
	static function EndShadowMode():Void {
		helix.raylib.internal.Shadows.end();
	}

	// Starts each of a lit shader's lights at intensity 1, as lights.glsl's lights are until set: its MAX_LIGHTS, 8.
	static function startIntensities(shader:Shader):Void {
		for (i in 0...8)
			SetShaderValue(shader, GetShaderLocation(shader, 'lights[$i].intensity'), 1.0, SHADER_UNIFORM_FLOAT);
	}
	#end
}
