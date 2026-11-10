import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Shaders.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

/** Checks the draws `UpdateModelAnimation` poses (docs/DECISIONS.md 44, 45), on graphics that count what is live: a mesh drawn through
	a program's own shader including `<helix/raylib/shaders/skinning.glsl>` before any pose reads no bones (its `boneOffset` 0, the bind
	pose), posed reads its first bone plus one, and a draw after the posed one reads no bones again; and a texture or a texture unit set
	on the default shader (`SetShaderValueTexture`, `SetShaderValue` on a sampler), before its skinned twin is made and after, is set on
	the twin too. Each model is a model of a mesh whose bones the program set, posed as a loaded model is. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Models)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.Shader)
@:access(helix.raylib.Model)
@:access(helix.raylib.Mesh)
class SkinningTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// A cube of one bone, every vertex its whole, posed by an animation of one frame raising it by one: a model of a mesh whose bones
	// the program sets, as a raylib program does.
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

	// The boneOffset the last draw recorded read.
	static function lastOffset(p:Program):Int {
		var pass = Runtime.frame.pass;
		var draw = pass.draws[pass.draws.length - 1];
		var place = p.shader.findUniformPlace(p.shader.findUniform("boneOffset"));
		return draw.uniforms[place.blockSlot].getInt32(place.offset);
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		var anim = raise();

		// A program's own shader skinning from the palette (tests/shaders/own_skinning.vs, compiled ahead of time by helix.py): the bind pose
		// until posed, and again for a draw after the posed one.
		var own = LoadCompiledShaderFromData(haxe.Resource.getBytes("own_skinning.shader"));
		var still = skinned(own), moving = skinned(own);
		DrawModel(still, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(own.program) == 0, "a draw before any pose reads no bones");
		UpdateModelAnimation(moving, anim, 0);
		DrawModel(moving, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(own.program) == 1, 'a posed draw reads its first bone plus one, not ${lastOffset(own.program)}');
		DrawModel(still, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(own.program) == 0, "a draw after a posed one reads no bones");
		// UpdateModelAnimationBones, raylib 6.2's bones-only call: a shader reading the bones itself draws the pose, the default shader
		// leaves the mesh as it was.
		var bonesOnly = skinned(own);
		UpdateModelAnimationBones(bonesOnly, anim, 0);
		DrawModel(bonesOnly, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(own.program) >= 1, "UpdateModelAnimationBones poses a mesh under a shader that reads the bones");
		var plain = skinned(null);
		UpdateModelAnimationBones(plain, anim, 0);
		DrawModel(plain, new Vector3(0, 0, 0), 1, WHITE);
		check(plain.meshes[0].pose == null && Runtime.frame.defaultProgram.twin == null,
			"UpdateModelAnimationBones under the default shader leaves the mesh as it was, as raylib's");
		check(moving.meshes[0].animVertices == null, "a shader reading the bone ids leaves animVertices, as raylib's CPU skinning does");

		// The default shader: a texture and a unit set before its skinned twin is made, and after, reach the twin.
		var shader = LoadMaterialDefault().shader;
		var red = LoadTextureFromImage(GenImageColor(2, 2, RED)),
			blue = LoadTextureFromImage(GenImageColor(2, 2, BLUE));
		var location = GetShaderLocation(shader, "texture0");
		SetShaderValueTexture(shader, location, red);
		SetShaderValue(shader, location, MATERIAL_MAP_EMISSION, SHADER_UNIFORM_INT);
		var dancer = skinned(shader);
		UpdateModelAnimation(dancer, anim, 0);
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		var twin = shader.program.twin;
		check(twin != null, "a posed draw through the default shader makes its skinned twin");
		var slot = twin.slotOf("texture0");
		check(twin.textures[slot] == red.id, "a texture set before the twin is set on it");
		check(twin.units[slot] == MATERIAL_MAP_EMISSION, "a unit set before the twin is set on it");
		SetShaderValueTexture(shader, location, blue);
		SetShaderValue(shader, location, MATERIAL_MAP_ALBEDO, SHADER_UNIFORM_INT);
		check(twin.textures[slot] == blue.id, "a texture set after the twin is set on it");
		check(twin.units[slot] == MATERIAL_MAP_ALBEDO, "a unit set after the twin is set on it");
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(twin) >= 1, "the twin's draw reads its bones");
		check(moving.meshes[0].boneMatrices != null && moving.meshes[0].boneMatrices[0].m13 == 1,
			"a model of a mesh whose bones the program set is posed, its mesh's boneMatrices raised by one");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
