import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Shadowmaps.*;

/** raylib's shadowmap example (`shaders_shadowmap.c`) with the Shadowmaps extra (`helix.raylib.extras.Shadowmaps`): a floor, a cube and
	the robot, animated, lit by a directional light the arrow keys turn, and shadowed through a shadow map. Each frame draws the scene into
	the shadow map from a camera at the light, then draws it again from the orbiting camera, its shader reading the shadow map's depth.
	The shaders are raylib's own `shadowmap.vs` and `shadowmap.fs`, unchanged, compiled by the build; the robot is `web/assets/robot.glb`,
	raylib's. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that
	frame. */
class Main {
	static inline final SHADOWMAP_RESOLUTION = 1024;

	static function drawScene(cube:Model, robot:Model):Void {
		DrawModelEx(cube, Vector3Zero(), new Vector3(0, 1, 0), 0, new Vector3(10, 1, 10), BLUE);
		DrawModelEx(cube, new Vector3(1.5, 1, -1.5), new Vector3(0, 1, 0), 0, Vector3One(), WHITE);
		DrawModelEx(robot, new Vector3(0, 0.5, 0), new Vector3(0, 1, 0), 0, new Vector3(1, 1, 1), RED);
	}

	static function main():Void {
		var screenWidth = 800, screenHeight = 450;
		SetConfigFlags(FLAG_MSAA_4X_HINT);
		InitWindow(screenWidth, screenHeight, "helix-raylib: shadowmaps");
		var cam = new Camera3D(new Vector3(10, 10, 10), Vector3Zero(), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var shadowShader:Null<Shader> = null,
			robot:Null<Model> = null,
			robotAnimations:Null<Array<ModelAnimation>> = null;
		LoadCompiledShaderAsync("assets/shadowmap.shader", loaded -> shadowShader = loaded);
		LoadModelAsync("assets/robot.glb", loaded -> robot = loaded);
		LoadModelAnimationsAsync("assets/robot.glb", loaded -> robotAnimations = loaded);
		var lightDir = Vector3Normalize(new Vector3(0.35, -1, -0.35));
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		var shadowMap = LoadShadowmapRenderTexture(SHADOWMAP_RESOLUTION, SHADOWMAP_RESOLUTION);
		// An orthographic camera at the light, as a directional light shines.
		var lightCam = new Camera3D(Vector3Scale(lightDir, -15), Vector3Zero(), new Vector3(0, 1, 0), 20, CAMERA_ORTHOGRAPHIC);
		var lightDirLoc = -1, lightVPLoc = -1, shadowMapLoc = -1;
		var ready = false, fc = 0;
		SetTargetFPS(60);
		while (!WindowShouldClose()) {
			if (!ready && shadowShader != null && robot != null && robotAnimations != null) {
				ready = true;
				shadowShader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shadowShader, "viewPos");
				lightDirLoc = GetShaderLocation(shadowShader, "lightDir");
				var lightColor = ColorNormalize(WHITE);
				SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "lightColor"), [lightColor.x, lightColor.y, lightColor.z, lightColor.w],
					SHADER_UNIFORM_VEC4);
				SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "ambient"), [0.1, 0.1, 0.1, 1.0], SHADER_UNIFORM_VEC4);
				lightVPLoc = GetShaderLocation(shadowShader, "lightVP");
				shadowMapLoc = GetShaderLocation(shadowShader, "shadowMap");
				SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "shadowMapResolution"), [SHADOWMAP_RESOLUTION], SHADER_UNIFORM_INT);
				cube.materials[0].shader = shadowShader;
				for (material in robot.materials)
					material.shader = shadowShader;
			}
			var dt = GetFrameTime();
			if (ready) {
				SetShaderValue(shadowShader, shadowShader.locs[SHADER_LOC_VECTOR_VIEW], [cam.position.x, cam.position.y, cam.position.z], SHADER_UNIFORM_VEC3);
				UpdateCamera(cam, CAMERA_ORBITAL);
				fc = (fc + 1) % robotAnimations[0].frameCount;
				UpdateModelAnimation(robot, robotAnimations[0], fc);
			}
			// The arrow keys turn the light.
			var cameraSpeed = 0.05;
			if (IsKeyDown(KEY_LEFT) && lightDir.x < 0.6)
				lightDir.x += cameraSpeed * 60 * dt;
			if (IsKeyDown(KEY_RIGHT) && lightDir.x > -0.6)
				lightDir.x -= cameraSpeed * 60 * dt;
			if (IsKeyDown(KEY_UP) && lightDir.z < 0.6)
				lightDir.z += cameraSpeed * 60 * dt;
			if (IsKeyDown(KEY_DOWN) && lightDir.z > -0.6)
				lightDir.z -= cameraSpeed * 60 * dt;
			lightDir = Vector3Normalize(lightDir);
			lightCam.position = Vector3Scale(lightDir, -15);
			BeginDrawing();
			ClearBackground(RAYWHITE);
			if (ready) {
				SetShaderValue(shadowShader, lightDirLoc, [lightDir.x, lightDir.y, lightDir.z], SHADER_UNIFORM_VEC3);
				// The scene's depth from the light, then the scene from the camera, shadowed where the light's depth is nearer.
				BeginTextureMode(shadowMap);
				ClearBackground(WHITE);
				BeginMode3D(lightCam);
				var lightView = rlGetMatrixModelview(),
					lightProj = rlGetMatrixProjection();
				drawScene(cube, robot);
				EndMode3D();
				EndTextureMode();
				SetShaderValueMatrix(shadowShader, lightVPLoc, MatrixMultiply(lightView, lightProj));
				SetShaderValueTexture(shadowShader, shadowMapLoc, shadowMap.depth);
				BeginMode3D(cam);
				drawScene(cube, robot);
				EndMode3D();
			}
			DrawText("Shadows in raylib using the shadowmapping algorithm!", screenWidth - 320, screenHeight - 20, 10, GRAY);
			DrawText("Use the arrow keys to rotate the light!", 10, 10, 30, RED);
			EndDrawing();
		}
		UnloadShadowmapRenderTexture(shadowMap);
		CloseWindow();
	}
}
