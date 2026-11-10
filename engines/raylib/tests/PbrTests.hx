import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Rlights.*;
import helix.raylib.extras.Lighting.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

/** Checks `LoadPbrShader`'s draws, on graphics that count what is live: its locations name its samplers, each set to its map's unit, so a
	material's map with a texture is bound at it, one without reads white and a missing normal map a flat normal; each draw writes the
	material's metalness, roughness and emissive values, and gives a normal-mapped mesh its tangents; a material marked unlit writes
	unlitValue 1; a posed model's draw, through the skinned twin, binds and writes the same; and each light starts at
	intensity 1, its range and intensity set by `SetShaderValue`. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Models)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.Shader)
@:access(helix.raylib.Model)
class PbrTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// The last draw recorded.
	static function lastDraw():Dynamic {
		var pass = Runtime.frame.pass;
		return pass.draws[pass.draws.length - 1];
	}

	// A float uniform's value in the last draw's blocks.
	static function drawnFloat(p:Program, name:String, index = 0):Float {
		var place = p.shader.findUniformPlace(p.shader.findUniform(name));
		var bytes:Bytes = lastDraw().uniforms[place.blockSlot];
		return bytes.getFloat(place.offset + index * 4);
	}

	static function drawnInt(p:Program, name:String):Int {
		var place = p.shader.findUniformPlace(p.shader.findUniform(name));
		var bytes:Bytes = lastDraw().uniforms[place.blockSlot];
		return bytes.getInt32(place.offset);
	}

	// The texture the last draw binds at a sampler.
	static function drawnTexture(p:Program, sampler:String):Int {
		var textures:Array<Int> = lastDraw().textures;
		return textures[p.slotOf(sampler)];
	}

	// A cube of one bone, every vertex its whole, posed by an animation of one frame raising it by one (SkinningTests').
	static function skinned(shader:Shader):Model {
		var mesh = GenMeshCube(1, 1, 1);
		mesh.boneIds = [for (k in 0...mesh.vertexCount * 4) 0];
		mesh.boneWeights = [for (k in 0...mesh.vertexCount * 4) k % 4 == 0 ? 1. : 0.];
		var model = LoadModelFromMesh(mesh);
		model.boneCount = 1;
		model.bones = [new BoneInfo("root", -1)];
		model.bindPose = [
			new Transform(new Vector3(0, 0, 0), new Quaternion(0, 0, 0, 1), new Vector3(1, 1, 1))
		];
		Models.animated(model);
		model.materials[0].shader = shader;
		return model;
	}

	static function raise():ModelAnimation {
		var anim = new ModelAnimation();
		anim.boneCount = 1;
		anim.bones = [new BoneInfo("root", -1)];
		anim.frameCount = 1;
		anim.framePoses = [
			[
				new Transform(new Vector3(0, 1, 0), new Quaternion(0, 0, 0, 1), new Vector3(1, 1, 1))
			]
		];
		return anim;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);

		var pbr = LoadPbrShader();
		var p = pbr.program;
		var maps = [
			SHADER_LOC_MAP_ALBEDO => "albedoMap",
			SHADER_LOC_MAP_METALNESS => "metalnessMap",
			SHADER_LOC_MAP_ROUGHNESS => "roughnessMap",
			SHADER_LOC_MAP_NORMAL => "normalMap",
			SHADER_LOC_MAP_OCCLUSION => "occlusionMap",
			SHADER_LOC_MAP_EMISSION => "emissiveMap"
		];
		for (loc => name in maps) {
			check(pbr.locs[loc] >= 0 && p.textureSlot(pbr.locs[loc]) == p.slotOf(name), 'locs[$loc] is $name');
			check(p.units[p.slotOf(name)] == loc - SHADER_LOC_MAP_ALBEDO, '$name reads its map\'s unit');
		}
		check(pbr.locs[SHADER_LOC_VECTOR_VIEW] >= 0, "the view vector's location");
		check(Std.isOfType(p, helix.raylib.internal.LitProgram) && Std.isOfType(p.twin, helix.raylib.internal.LitProgram),
			"loading it makes its program and its skinned twin, each writing the material's values");

		// A material's values and maps in a draw: the values written, a map with a texture bound, one without reading white.
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		var material = cube.materials[0];
		material.shader = pbr;
		material.maps[MATERIAL_MAP_METALNESS].value = 0.25;
		material.maps[MATERIAL_MAP_ROUGHNESS].value = 0.75;
		material.maps[MATERIAL_MAP_EMISSION].color = new Color(255, 0, 51, 255);
		var albedo = LoadTextureFromImage(GenImageColor(2, 2, RED)),
			normal = LoadTextureFromImage(GenImageColor(2, 2, BLUE));
		material.maps[MATERIAL_MAP_ALBEDO].texture = albedo;
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		check(drawnFloat(p, "metallicValue") == 0.25
			&& drawnFloat(p, "roughnessValue") == 0.75, "the metalness and roughness values written");
		check(drawnFloat(p, "emissiveColor") == 1
			&& Math.abs(drawnFloat(p, "emissiveColor", 2) - 0.2) < 1e-6, "the emissive color written, linear");
		check(drawnTexture(p, "albedoMap") == Textures.handle(albedo.id), "the albedo map bound at its sampler");
		check(drawnTexture(p, "roughnessMap") == Runtime.frame.white, "a map without a texture reads white");
		var flat = drawnTexture(p, "normalMap");
		check(flat != 0 && flat != Runtime.frame.white && graphics.textures.exists(flat), "a missing normal map reads the flat normal texel");
		check(cube.meshes[0].tangents == null, "a mesh without a normal map keeps no tangents");
		material.maps[MATERIAL_MAP_NORMAL].texture = normal;
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		check(drawnTexture(p, "normalMap") == Textures.handle(normal.id), "a normal map bound at its sampler");
		check(cube.meshes[0].tangents != null && cube.meshes[0].tangents.length == cube.meshes[0].vertexCount * 4,
			"a mesh without tangents gets them for its normal map");

		// A material marked unlit: drawn through the same program, its unlitValue 1, and 0 again once it isn't.
		material.unlit = true;
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		check(drawnFloat(p, "unlitValue") == 1 && [for (_ => id in p.pipelines) id].indexOf(lastDraw().pipeline) >= 0,
			"an unlit material's draw writes unlitValue 1, through the PBR shader");
		material.unlit = false;
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		check(drawnFloat(p, "unlitValue") == 0, "a lit material's draw writes unlitValue 0");

		// A posed model: its draw through the skinned twin binds and writes the same.
		var dancer = skinned(pbr);
		dancer.materials[0].maps[MATERIAL_MAP_ALBEDO].texture = albedo;
		dancer.materials[0].maps[MATERIAL_MAP_ROUGHNESS].value = 0.5;
		UpdateModelAnimation(dancer, raise(), 0);
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		var twin = p.twin;
		check(twin != null, "a posed draw through the PBR shader makes its skinned twin");
		check(drawnFloat(twin, "roughnessValue") == 0.5, "the twin's draw writes the material's values");
		check(drawnTexture(twin, "albedoMap") == Textures.handle(albedo.id), "the twin binds the albedo map at its sampler");
		check(drawnTexture(twin, "metalnessMap") == Runtime.frame.white, "the twin's map without a texture reads white");
		check(drawnTexture(twin, "normalMap") == flat, "the twin's missing normal map reads the flat normal texel");
		check(twin.slotOf("bonePalette") >= 0 && drawnTexture(twin, "bonePalette") != 0, "the twin reads the bone palette");

		// A posed model marked unlit: through the skinned twin, its unlitValue 1.
		dancer.materials[0].unlit = true;
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		check(drawnFloat(twin, "unlitValue") == 1 && [for (_ => id in twin.pipelines) id].indexOf(lastDraw().pipeline) >= 0,
			"an unlit posed draw writes unlitValue 1, through the skinned twin");

		// A texture set on the shader by SetShaderValueTexture is kept by its id and bound by its handle (RestoreTests: after a restore,
		// the handle it was sent again with).
		var emissiveLoc = GetShaderLocation(pbr, "emissiveMap");
		SetShaderValueTexture(pbr, emissiveLoc, normal);
		material.maps[MATERIAL_MAP_NORMAL].texture = new Texture2D();
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		check(drawnTexture(p, "emissiveMap") == Textures.handle(normal.id) && p.textures[p.slotOf("emissiveMap")] == normal.id,
			"a texture set on the shader, kept by its id and bound by its handle");

		// A light's range and intensity: each light starts at intensity 1, and both are set as any uniform is.
		var at = p.locate("lights[0].intensity");
		check(at >= 0 && p.written[at][0] == 1, "each light starts at intensity 1");
		CreateLight(LIGHT_POINT, new Vector3(0, 2, 0), new Vector3(0, 0, 0), WHITE, pbr);
		var range = GetShaderLocation(pbr, "lights[0].range"),
			intensity = GetShaderLocation(pbr, "lights[0].intensity");
		SetShaderValue(pbr, range, 6.0, SHADER_UNIFORM_FLOAT);
		SetShaderValue(pbr, intensity, 9.0, SHADER_UNIFORM_FLOAT);
		check(range >= 0
			&& intensity >= 0
			&& p.written[p.locate("lights[0].range")][0] == 6
			&& p.written[at][0] == 9, "a light's range and intensity written");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
