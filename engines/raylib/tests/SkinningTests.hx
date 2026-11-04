import haxe.io.Bytes;
import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Lights.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Models;
import helix.raylib.internal.Program;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;

/** Checks the draws `UpdateModelAnimation` poses (docs/DECISIONS.md 44, 45), on graphics that count what is live: a mesh drawn through
	a program's own shader including `<helix/raylib/shaders/skinning.glsl>` before any pose reads no bones (its `boneOffset` 0, the bind
	pose), posed reads its first bone plus one, and a draw after the posed one reads no bones again; and a texture or a texture unit set
	on the lit shader (`SetShaderValueTexture`, `SetShaderValue` on a sampler), before its skinned twin is made and after, is set on the
	twin too. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.internal.Models)
@:access(helix.raylib.internal.Program)
@:access(helix.raylib.Shader)
@:access(helix.raylib.Model)
class SkinningTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	// A cube of one bone, every vertex its whole, posed by an animation of one frame raising it by one.
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

		// A program's own shader skinning from the palette: the bind pose until posed, and again for a draw after the posed one.
		var own = LoadShaderFromMemory("#version 330
#include <helix/raylib/shaders/skinning.glsl>
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
out vec2 fragTexCoord;
out vec4 fragColor;
uniform mat4 mvp;
void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    gl_Position = mvp*helixSkin()*vec4(vertexPosition, 1.0);
}
", null);
		var still = skinned(own), moving = skinned(own);
		DrawModel(still, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(own.program) == 0, "a draw before any pose reads no bones");
		UpdateModelAnimation(moving, anim, 0);
		DrawModel(moving, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(own.program) == 1, 'a posed draw reads its first bone plus one, not ${lastOffset(own.program)}');
		DrawModel(still, new Vector3(0, 0, 0), 1, WHITE);
		check(lastOffset(own.program) == 0, "a draw after a posed one reads no bones");
		check(moving.meshes[0].animVertices == null, "a shader reading the bone ids leaves animVertices, as raylib's CPU skinning does");

		// The lit shader: a texture and a unit set before its twin is made, and after, reach the twin.
		var lit = LoadLightingShader();
		var red = LoadTextureFromImage(GenImageColor(2, 2, RED)),
			blue = LoadTextureFromImage(GenImageColor(2, 2, BLUE));
		var location = GetShaderLocation(lit, "texture0");
		SetShaderValueTexture(lit, location, red);
		SetShaderValue(lit, location, MATERIAL_MAP_EMISSION, SHADER_UNIFORM_INT);
		var dancer = skinned(lit);
		UpdateModelAnimation(dancer, anim, 0);
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		var twin = lit.program.twin;
		check(twin != null, "a posed draw through the lit shader makes its skinned twin");
		var slot = twin.slotOf("texture0");
		check(twin.textures[slot] == Textures.handle(red.id), "a texture set before the twin is set on it");
		check(twin.units[slot] == MATERIAL_MAP_EMISSION, "a unit set before the twin is set on it");
		SetShaderValueTexture(lit, location, blue);
		SetShaderValue(lit, location, MATERIAL_MAP_ALBEDO, SHADER_UNIFORM_INT);
		check(twin.textures[slot] == Textures.handle(blue.id), "a texture set after the twin is set on it");
		check(twin.units[slot] == MATERIAL_MAP_ALBEDO, "a unit set after the twin is set on it");
		var ambient = GetShaderLocation(lit, "ambient");
		SetShaderValue(lit, ambient, [0.5, 0.25, 0.125, 1], SHADER_UNIFORM_VEC4);
		DrawModel(dancer, new Vector3(0, 0, 0), 1, WHITE);
		var place = twin.shader.findUniformPlace(twin.shader.findUniform("ambient"));
		var pass = Runtime.frame.pass;
		var bytes:Bytes = pass.draws[pass.draws.length - 1].uniforms[place.blockSlot];
		check(bytes.getFloat(place.offset + 4) == 0.25, "a value set on the lit shader reaches its twin's draws");
		check(lastOffset(twin) >= 1, "the twin's draw reads its bones");

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
