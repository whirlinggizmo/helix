import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Shadowmaps.*;

// scene.c drawn by helix-raylib: raylib's shadowmap example with its shadowmap.vs and shadowmap.fs, compiled ahead of time into
// shadowmap.shader, its render texture of depth alone made by the Shadowmaps extra and its depth bound with SetShaderValueTexture in place
// of the example's rlEnableTexture and rlSetUniform. The third frame after its loads saved as helix.png, and drawn again after it.
class Main {
	static function drawScene(cube:Model, robot:Model):Void {
		DrawModelEx(cube, Vector3Zero(), new Vector3(0, 1, 0), 0, new Vector3(10, 1, 10), BLUE);
		DrawModelEx(cube, new Vector3(1.5, 1, -1.5), new Vector3(0, 1, 0), 0, Vector3One(), WHITE);
		DrawModelEx(robot, new Vector3(0, 0.5, 0), new Vector3(0, 1, 0), 0, new Vector3(1, 1, 1), RED);
	}

	static function main():Void {
		var screenWidth = 800, screenHeight = 450;
		InitWindow(screenWidth, screenHeight, "shadowmap");
		var cam = new Camera3D(new Vector3(10, 10, 10), Vector3Zero(), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var shadowShader:Shader = null,
			robot:Model = null,
			robotAnimations:Array<ModelAnimation> = null;
		LoadCompiledShaderAsync("shadowmap.shader", s -> shadowShader = s);
		LoadModelAsync("robot.glb", m -> robot = m);
		LoadModelAnimationsAsync("robot.glb", a -> robotAnimations = a);
		var lightDir = Vector3Normalize(new Vector3(0.35, -1, -0.35));
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		var shadowMap = LoadShadowmapRenderTexture(1024, 1024);
		var lightCam = new Camera3D(Vector3Scale(lightDir, -15), Vector3Zero(), new Vector3(0, 1, 0), 20, CAMERA_ORTHOGRAPHIC);
		var lightDirLoc = 0, lightVPLoc = 0, shadowMapLoc = 0;
		var frame = -1;
		while (!WindowShouldClose()) {
			var ready = shadowShader != null && robot != null && robotAnimations != null;
			if (ready && frame < 0) {
				frame = 0;
				shadowShader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shadowShader, "viewPos");
				lightDirLoc = GetShaderLocation(shadowShader, "lightDir");
				var lightColorNormalized = ColorNormalize(WHITE);
				SetShaderValue(shadowShader, lightDirLoc, [lightDir.x, lightDir.y, lightDir.z], SHADER_UNIFORM_VEC3);
				SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "lightColor"), [
					lightColorNormalized.x,
					lightColorNormalized.y,
					lightColorNormalized.z,
					lightColorNormalized.w
				], SHADER_UNIFORM_VEC4);
				SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
				lightVPLoc = GetShaderLocation(shadowShader, "lightVP");
				shadowMapLoc = GetShaderLocation(shadowShader, "shadowMap");
				SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "shadowMapResolution"), [1024], SHADER_UNIFORM_INT);
				cube.materials[0].shader = shadowShader;
				for (m in robot.materials)
					m.shader = shadowShader;
			}
			BeginDrawing();
			if (ready) {
				// CAMERA_ORBITAL's turn of a frame at 60 frames a second, and the left key's turn of the light, as scene.c turns them; held
				// after the third frame, so a page's screenshot, captured later, shows it.
				if (frame <= 2) {
					SetShaderValue(shadowShader, shadowShader.locs[SHADER_LOC_VECTOR_VIEW], [cam.position.x, cam.position.y, cam.position.z],
						SHADER_UNIFORM_VEC3);
					var rotation = MatrixRotate(cam.up, -0.5 / 60);
					cam.position = Vector3Add(Vector3Transform(Vector3Subtract(cam.position, cam.target), rotation), cam.target);
					UpdateModelAnimation(robot, robotAnimations[0], 20 + 7 * frame);
					if (lightDir.x < 0.6)
						lightDir.x += 0.05;
					lightDir = Vector3Normalize(lightDir);
					lightCam.position = Vector3Scale(lightDir, -15);
					SetShaderValue(shadowShader, lightDirLoc, [lightDir.x, lightDir.y, lightDir.z], SHADER_UNIFORM_VEC3);
				}
				BeginTextureMode(shadowMap);
				ClearBackground(WHITE);
				BeginMode3D(lightCam);
				var lightView = rlGetMatrixModelview(),
					lightProj = rlGetMatrixProjection();
				drawScene(cube, robot);
				EndMode3D();
				EndTextureMode();
				ClearBackground(RAYWHITE);
				SetShaderValueMatrix(shadowShader, lightVPLoc, MatrixMultiply(lightView, lightProj));
				SetShaderValueTexture(shadowShader, shadowMapLoc, shadowMap.depth);
				BeginMode3D(cam);
				drawScene(cube, robot);
				EndMode3D();
				DrawText("Shadows in raylib using the shadowmapping algorithm!", screenWidth - 320, screenHeight - 20, 10, GRAY);
				DrawText("Use the arrow keys to rotate the light!", 10, 10, 30, RED);
			} else
				ClearBackground(RAYWHITE);
			if (frame == 2)
				LoadImageFromScreenAsync(shot -> sys.io.File.saveBytes("helix.png", ExportImageToMemory(shot, ".png", [0])));
			EndDrawing();
			if (frame >= 0)
				frame++;
		}
		UnloadShadowmapRenderTexture(shadowMap);
		CloseWindow();
	}
}
