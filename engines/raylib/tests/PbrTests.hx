import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Lights.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

/** Checks `LoadPbrShader`'s draws, on graphics that count what is live: its locations name its samplers, each set to its map's unit, so a
	material's map with a texture is bound at it, one without reads white and a missing normal map a flat normal; each draw writes the
	material's metalness, roughness and emissive values, and gives a normal-mapped mesh its tangents; a material marked unlit is drawn
	through the unlit twin; and a posed model's draw, through the skinned twins, binds and writes the same. */
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
		check(p.material, "the shader's draws write the material");

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

		// A material marked unlit: drawn through the unlit twin, its maps bound by their units.
		material.unlit = true;
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		var unlit = p.unlitTwin;
		check(unlit != null && unlit.material && unlit.shader != p.shader, "an unlit material's draw makes the unlit twin");
		var pipelines = [for (_ => id in unlit.pipelines) id];
		check(pipelines.indexOf(lastDraw().pipeline) >= 0, "the draw goes through the unlit twin");
		check(drawnTexture(unlit, "albedoMap") == Textures.handle(albedo.id), "the unlit twin binds the albedo map by its unit");
		check(pbr.locs[SHADER_LOC_MAP_NORMAL] >= 0 && unlit.shader.findSampler("normalMap") == null, "the unlit twin has no normal map");
		material.unlit = false;

		// A posed model: its draw through the skinned twin binds and writes the same.
		var dancer = skinned(pbr);
		dancer.materials[0].maps[MATERIAL_MAP_ALBEDO].texture = albedo;
		dancer.materials[0].maps[MATERIAL_MAP_ROUGHNESS].value = 0.5;
		UpdateModelAnimation(dancer, raise(), 0);
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		var twin = p.twin;
		check(twin != null && twin.material, "a posed draw through the PBR shader makes its skinned twin, which writes the material");
		check(drawnFloat(twin, "roughnessValue") == 0.5, "the twin's draw writes the material's values");
		check(drawnTexture(twin, "albedoMap") == Textures.handle(albedo.id), "the twin binds the albedo map at its sampler");
		check(drawnTexture(twin, "metalnessMap") == Runtime.frame.white, "the twin's map without a texture reads white");
		check(drawnTexture(twin, "normalMap") == flat, "the twin's missing normal map reads the flat normal texel");
		check(twin.slotOf("bonePalette") >= 0 && drawnTexture(twin, "bonePalette") != 0, "the twin reads the bone palette");

		// A posed model marked unlit: through the unlit twin's skinned twin.
		dancer.materials[0].unlit = true;
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		var unlitSkinned = unlit.twin;
		check(unlitSkinned != null && unlitSkinned.slotOf("bonePalette") >= 0 && unlitSkinned.shader.findSampler("normalMap") == null,
			"an unlit posed draw makes the unlit twin's skinned twin");
		check([for (_ => id in unlitSkinned.pipelines) id].indexOf(lastDraw().pipeline) >= 0, "the draw goes through it");
		check(drawnTexture(unlitSkinned, "albedoMap") == Textures.handle(albedo.id) && drawnTexture(unlitSkinned, "bonePalette") != 0,
			"it binds the albedo map by its unit and reads the bone palette");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
