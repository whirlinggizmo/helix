import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Shadowmaps.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.services.time.Time;

/** Checks `extras.Shadowmaps`: `LoadShadowmapRenderTexture` makes a render target whose depth is a texture, its `depth` that texture and
	its `texture` empty; a shader given the depth by `SetShaderValueTexture` binds it in the screen's draws and the white texture in the
	draws into the render texture itself; `UnloadShadowmapRenderTexture` frees the target and its depth once. Run by helix.py test on the
	interpreter and Node. */
@:access(helix.raylib.internal.Runtime)
@:access(helix.raylib.internal.Frame)
@:access(helix.raylib.Shader)
@:access(helix.raylib.internal.Program)
class ShadowmapsTests {
	static var checks = 0;

	static function check(value:Bool, message:String):Void {
		if (!value)
			throw message;
		checks++;
	}

	static function main():Void {
		SetTraceLogLevel(LOG_NONE);
		var graphics = new CountingGraphics();
		Runtime.graphics = graphics;
		Runtime.frame = new Frame(graphics);
		Runtime.system = new FakeSystem();
		Runtime.time = new Time(Runtime.system);
		Runtime.frame.begin(64, 64);

		// A render target with a depth texture, the depth its texture, and no color.
		var targets = graphics.targetCreations;
		var shadowMap = LoadShadowmapRenderTexture(64, 32);
		check(graphics.targetCreations == targets + 1, "one render target made");
		check(graphics.targetDepths.exists(shadowMap.id), "the render target has a depth texture");
		var depthGpu = graphics.targetDepths.get(shadowMap.id);
		check(shadowMap.depth.id != 0 && Textures.handle(shadowMap.depth.id) == depthGpu, "its depth is the target's depth texture");
		check(shadowMap.depth.width == 64 && shadowMap.depth.height == 32, "its depth is its size");
		check(shadowMap.texture.id == 0 && shadowMap.texture.width == 64 && shadowMap.texture.height == 32, "its texture is empty, of its size");

		// The depth set on a shader: drawn into the render texture, the white texture in its place; on the screen, the depth.
		var shader = LoadCompiledShaderFromMemory(haxe.Resource.getBytes("emissive.shader"));
		SetShaderValueTexture(shader, GetShaderLocation(shader, "emissiveMap"), shadowMap.depth);
		var slot = shader.program.slotOf("emissiveMap");
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		cube.materials[0].shader = shader;
		var camera = new Camera3D(new Vector3(0, 2, 4), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		BeginTextureMode(shadowMap);
		ClearBackground(WHITE);
		BeginMode3D(camera);
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		EndMode3D();
		EndTextureMode();
		BeginMode3D(camera);
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		EndMode3D();
		Runtime.frame.draw(64, 64, true);
		var drawn = [for (t in graphics.drawnTextures) if (slot < t.length) t[slot]];
		check(drawn.length == 2, 'the cube drawn twice, not ${drawn.length} times');
		check(drawn[0] == Runtime.frame.white, 'into the render texture, the white texture bound in place of its depth, not ${drawn[0]}');
		check(drawn[1] == depthGpu, 'on the screen, its depth bound, not ${drawn[1]}');

		// Freed: the target and its depth with it, once; a second unload does nothing.
		var target = shadowMap.id, depthId = shadowMap.depth.id;
		UnloadShadowmapRenderTexture(shadowMap);
		check(!graphics.textures.exists(target), "the render target freed");
		check(shadowMap.id == 0 && shadowMap.depth.id == 0, "its ids are 0");
		check(Textures.handle(depthId) == 0, "its depth's id is gone");
		UnloadShadowmapRenderTexture(shadowMap);
		check(graphics.doubles == 0, 'nothing freed twice, ${graphics.doubles} were');
		UnloadModel(cube);
		UnloadShader(shader);

		var report = haxe.Json.stringify({passed: true, checks: checks});
		#if js
		js.Syntax.code("console.log({0})", report);
		#else
		Sys.println(report);
		#end
	}
}
