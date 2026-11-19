import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Lighting.*;
import helix.raylib.extras.Shadowmaps.*;
import helix.raylib.internal.Frame;
import helix.raylib.internal.Runtime;
import helix.raylib.internal.Textures;
import helix.services.time.Time;

/** Checks `extras.Shadowmaps`: `LoadShadowmapRenderTexture` makes a render target whose depth is a texture, its `depth` that texture and
	its `texture` empty; a shader set the depth by `SetShaderValueTexture` binds it in the screen's draws and the white texture in the
	draws into the render texture itself, a light casting the Lighting extra's shadows or not; `UnloadShadowmapRenderTexture` and
	`UnloadRenderTexture` free the target and its depth once, either called again doing nothing. Run by helix.py test on the
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

		// With the Lighting extra's shadows too, a lit shader loaded and a light casting after the shadowmap: a draw into a shadowmap
		// with its own depth bound still binds the white texture there, and the screen's the depth.
		var second = LoadShadowmapRenderTexture(32, 32);
		var secondDepth = graphics.targetDepths.get(second.id);
		var lit = LoadLightingShader();
		var sun = CreateLight(LIGHT_DIRECTIONAL, new Vector3(-4, 8, 0), Vector3Zero(), WHITE, lit);
		EnableLightShadows(sun);
		check(IsLightCastingShadows(sun), "the light casts");
		var floor = LoadModelFromMesh(GenMeshCube(4, 0.1, 4));
		floor.materials[0].shader = lit;
		BeginShadowMode(camera);
		DrawModel(floor, new Vector3(0, 0, 0), 1, WHITE);
		EndShadowMode();
		SetShaderValueTexture(shader, GetShaderLocation(shader, "emissiveMap"), second.depth);
		graphics.drawnTextures.resize(0);
		BeginTextureMode(second);
		ClearBackground(WHITE);
		BeginMode3D(camera);
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		EndMode3D();
		EndTextureMode();
		BeginMode3D(camera);
		DrawModel(floor, new Vector3(0, 0, 0), 1, WHITE);
		DrawModel(cube, new Vector3(0, 0, 0), 1, WHITE);
		EndMode3D();
		Runtime.frame.draw(64, 64, true);
		var own = [for (t in graphics.drawnTextures) if (t.indexOf(secondDepth) >= 0) t];
		check(own.length == 1, 'with a light casting, the depth bound by the screen\'s cube alone, not ${own.length} draws');
		check(graphics.drawnTextures.length >= 3, 'the shadow, the shadowmap\'s and the screen\'s draws made, ${graphics.drawnTextures.length}');

		// UnloadRenderTexture frees a shadowmap render texture, its depth with it, once; either call again does nothing.
		var target2 = second.id, depthId2 = second.depth.id;
		UnloadRenderTexture(second);
		check(!graphics.textures.exists(target2), "UnloadRenderTexture frees the shadowmap's render target");
		check(second.id == 0 && second.depth.id == 0 && Textures.handle(depthId2) == 0, "UnloadRenderTexture: its ids are 0, its depth's gone");
		UnloadRenderTexture(second);
		UnloadShadowmapRenderTexture(second);
		var third = LoadShadowmapRenderTexture(16, 16), target3 = third.id;
		UnloadShadowmapRenderTexture(third);
		UnloadRenderTexture(third);
		UnloadShadowmapRenderTexture(third);
		check(!graphics.textures.exists(target3), "the third shadowmap freed");
		// A plain render texture still frees as it did, the shadowmap's unload in place.
		var plain = LoadRenderTexture(8, 8), plainTarget = plain.id;
		UnloadRenderTexture(plain);
		check(!graphics.textures.exists(plainTarget), "a plain render texture freed");
		UnloadRenderTexture(plain);
		check(graphics.doubles == 0, 'unloads by either call, twice: nothing freed twice, ${graphics.doubles} were');
		UnloadModel(floor);
		UnloadLight(sun);
		UnloadShader(lit);
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
