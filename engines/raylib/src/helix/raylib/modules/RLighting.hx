package helix.raylib.modules;

#if !macro
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.modules.RCore.*;
import helix.raylib.internal.Defaults;
#end

/** Holds helix-raylib's lit and PBR shaders, lit by the scene's lights (rlights' `CreateLight`), the shadow pass, and what the Lighting extra sets on a
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

	/** Takes a light out of the scene. It lights nothing after, and its shadows are freed.

		@param light  The light, from `CreateLight`. */
	static function UnloadLight(light:Light):Void {
		helix.raylib.internal.SceneLights.remove(light);
		// Its place among the lights casting shadows is let go of by the next shadow pass (Shadows).
		@:privateAccess light.shadow = null;
		@:privateAccess light.shadowCasting = false;
		@:privateAccess light.shadowIndex = 0;
	}

	/** Sets how a light's shadows are made, whether or not it casts them. An option not given takes its default. It doesn't turn the
		light's shadows on: `SetLightShadowCasting` does.

		The casting lights share one shadow map, `mapSize` squared texels, as large as the largest any of them asks for. A light's shadows
		take a layer of it for each cascade of a directional light, six for a point light, and one for a spot light.

		@param light  The light, from `CreateLight`.
		@param options  Optional. How its shadows are made; every default when omitted or null. */
	static function SetLightShadows(light:Light, ?options:helix.raylib.extras.ShadowOptions):Void {
		@:privateAccess light.shadow = filledShadows(options == null ? {} : options, @:privateAccess light.shadow);
	}

	/** Returns how a light's shadows are made, as `SetLightShadows` set them, each default filled in. A light never given options has
		every default.

		@param light  The light, from `CreateLight`.
		@param out  Optional. The options filled; new ones when omitted.
		@return  out or the new options. */
	static function GetLightShadows(light:Light, ?out:helix.raylib.extras.ShadowOptions):helix.raylib.extras.ShadowOptions {
		if (out == null)
			out = {};
		var s = @:privateAccess light.shadow;
		if (s == null)
			return filledShadows({}, out);
		out.mapSize = s.mapSize;
		out.distance = s.distance;
		out.bounds = s.bounds == null ? null : s.bounds.copy();
		out.cascades = s.cascades;
		out.bias = s.bias;
		out.slopeBias = s.slopeBias;
		out.normalOffset = s.normalOffset;
		out.softness = s.softness;
		out.strength = s.strength;
		return out;
	}

	/** Turns a light's shadows on or off. A light casts none until turned on. Its shadows are made as `SetLightShadows` set them, with
		every default when it wasn't called.

		4 lights cast shadows at most. A fifth stays off, with a warning. Turning a light off frees its place for another and keeps its
		options. `UnloadLight` turns it off.

		@param light  The light, from `CreateLight`.
		@param casting  true to cast shadows, false to cast none. */
	static function SetLightShadowCasting(light:Light, casting:Bool):Void {
		if (!casting) {
			@:privateAccess light.shadowCasting = false;
			@:privateAccess light.shadowIndex = 0;
			return;
		}
		if (@:privateAccess light.shadow == null)
			SetLightShadows(light);
		helix.raylib.internal.Shadows.addCaster(light);
	}

	/** Returns whether a light casts shadows (`SetLightShadowCasting`).

		@param light  The light, from `CreateLight`.
		@return  true when it casts shadows. */
	static function IsLightShadowCasting(light:Light):Bool {
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

	// Shadow options with each default filled and each value kept in its range, into the light's own when it has them.
	static function filledShadows(o:helix.raylib.extras.ShadowOptions, into:Null<helix.raylib.extras.ShadowOptions>):helix.raylib.extras.ShadowOptions {
		var f:helix.raylib.extras.ShadowOptions = into == null ? {} : into;
		var asked = o.mapSize == null ? 2048 : o.mapSize, size = 256;
		while (size * 2 <= asked && size < 4096)
			size *= 2;
		f.mapSize = size;
		f.distance = o.distance == null ? 50 : Math.max(1e-6, o.distance);
		f.bounds = o.bounds == null ? null : o.bounds.copy();
		var cascades = o.cascades == null ? 1 : o.cascades;
		f.cascades = cascades < 1 ? 1 : cascades > 4 ? 4 : cascades;
		f.bias = o.bias == null ? 1 : Math.max(0, o.bias);
		f.slopeBias = o.slopeBias == null ? 4 : Math.max(0, o.slopeBias);
		f.normalOffset = o.normalOffset == null ? 1 : Math.max(0, o.normalOffset);
		f.softness = o.softness == null ? 1 : Math.max(0, Math.min(8, o.softness));
		f.strength = o.strength == null ? 1 : Math.max(0, Math.min(1, o.strength));
		return f;
	}

	// Starts each of a lit shader's lights at intensity 1, as lights.glsl's lights are until set: its MAX_LIGHTS, 8.
	static function startIntensities(shader:Shader):Void {
		for (i in 0...8)
			SetShaderValue(shader, GetShaderLocation(shader, 'lights[$i].intensity'), 1.0, SHADER_UNIFORM_FLOAT);
	}
	#end
}
