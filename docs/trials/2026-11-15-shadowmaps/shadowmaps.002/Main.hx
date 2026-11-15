import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Raymath.*;
import helix.raylib.Rlgl.*;
import helix.raylib.extras.Shadowmaps.*;

class Main {
	static inline var SHADOWMAP_RESOLUTION = 1024;

	static var cube:Model;
	static var robot:Model;

	static function DrawScene() {
		DrawModelEx(cube, Vector3Zero(), new Vector3(0.0, 1.0, 0.0), 0.0, new Vector3(10.0, 1.0, 10.0), BLUE);
		DrawModelEx(cube, new Vector3(1.5, 1.0, -1.5), new Vector3(0.0, 1.0, 0.0), 0.0, Vector3One(), WHITE);
		DrawModelEx(robot, new Vector3(0.0, 0.5, 0.0), new Vector3(0.0, 1.0, 0.0), 0.0, new Vector3(1.0, 1.0, 1.0), RED);
	}

	static function main() {
		final screenWidth = 800;
		final screenHeight = 450;

		SetConfigFlags(FLAG_MSAA_4X_HINT);
		InitWindow(screenWidth, screenHeight, "raylib [shaders] example - shadowmap");

		var cam = new Camera3D();
		cam.position = new Vector3(10.0, 10.0, 10.0);
		cam.target = Vector3Zero();
		cam.projection = CAMERA_PERSPECTIVE;
		cam.up = new Vector3(0.0, 1.0, 0.0);
		cam.fovy = 45.0;

		var shadowShader:Shader = null;
		var robotAnimations:Array<ModelAnimation> = null;
		LoadCompiledShaderAsync("shaders/shadowmap.shader", shader -> shadowShader = shader);
		LoadModelAsync("resources/models/robot.glb", model -> robot = model);
		LoadModelAnimationsAsync("resources/models/robot.glb", anims -> robotAnimations = anims);
		while (!WindowShouldClose() && (shadowShader == null || robot == null || robotAnimations == null)) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawText("Loading...", 10, 10, 30, GRAY);
			EndDrawing();
		}
		shadowShader.locs[SHADER_LOC_VECTOR_VIEW] = GetShaderLocation(shadowShader, "viewPos");
		var lightDir = Vector3Normalize(new Vector3(0.35, -1.0, -0.35));
		var lightColor = WHITE;
		var lightColorNormalized = ColorNormalize(lightColor);
		var lightDirLoc = GetShaderLocation(shadowShader, "lightDir");
		var lightColLoc = GetShaderLocation(shadowShader, "lightColor");
		SetShaderValue(shadowShader, lightDirLoc, lightDir, SHADER_UNIFORM_VEC3);
		SetShaderValue(shadowShader, lightColLoc, lightColorNormalized, SHADER_UNIFORM_VEC4);
		var ambientLoc = GetShaderLocation(shadowShader, "ambient");
		SetShaderValue(shadowShader, ambientLoc, new Vector4(0.1, 0.1, 0.1, 1.0), SHADER_UNIFORM_VEC4);
		var lightVPLoc = GetShaderLocation(shadowShader, "lightVP");
		var shadowMapLoc = GetShaderLocation(shadowShader, "shadowMap");
		SetShaderValue(shadowShader, GetShaderLocation(shadowShader, "shadowMapResolution"), SHADOWMAP_RESOLUTION, SHADER_UNIFORM_INT);

		cube = LoadModelFromMesh(GenMeshCube(1.0, 1.0, 1.0));
		cube.materials[0].shader = shadowShader;
		for (i in 0...robot.materialCount)
			robot.materials[i].shader = shadowShader;

		var shadowMap = LoadShadowmapRenderTexture(SHADOWMAP_RESOLUTION, SHADOWMAP_RESOLUTION);
		var lightCam = new Camera3D();
		lightCam.position = Vector3Scale(lightDir, -15.0);
		lightCam.target = Vector3Zero();
		lightCam.projection = CAMERA_ORTHOGRAPHIC;
		lightCam.up = new Vector3(0.0, 1.0, 0.0);
		lightCam.fovy = 20.0;

		SetTargetFPS(60);
		var fc = 0;

		while (!WindowShouldClose()) {
			var dt = GetFrameTime();

			SetShaderValue(shadowShader, shadowShader.locs[SHADER_LOC_VECTOR_VIEW], cam.position, SHADER_UNIFORM_VEC3);
			UpdateCamera(cam, CAMERA_ORBITAL);

			fc++;
			fc %= robotAnimations[0].frameCount;
			UpdateModelAnimation(robot, robotAnimations[0], fc);

			final cameraSpeed = 0.05;
			if (IsKeyDown(KEY_LEFT))
				if (lightDir.x < 0.6)
					lightDir.x += cameraSpeed * 60.0 * dt;
			if (IsKeyDown(KEY_RIGHT))
				if (lightDir.x > -0.6)
					lightDir.x -= cameraSpeed * 60.0 * dt;
			if (IsKeyDown(KEY_UP))
				if (lightDir.z < 0.6)
					lightDir.z += cameraSpeed * 60.0 * dt;
			if (IsKeyDown(KEY_DOWN))
				if (lightDir.z > -0.6)
					lightDir.z -= cameraSpeed * 60.0 * dt;
			lightDir = Vector3Normalize(lightDir);
			lightCam.position = Vector3Scale(lightDir, -15.0);
			SetShaderValue(shadowShader, lightDirLoc, lightDir, SHADER_UNIFORM_VEC3);

			BeginDrawing();

			BeginTextureMode(shadowMap);
			ClearBackground(WHITE);
			BeginMode3D(lightCam);
			var lightView = rlGetMatrixModelview();
			var lightProj = rlGetMatrixProjection();
			DrawScene();
			EndMode3D();
			EndTextureMode();
			var lightViewProj = MatrixMultiply(lightView, lightProj);

			ClearBackground(RAYWHITE);

			SetShaderValueMatrix(shadowShader, lightVPLoc, lightViewProj);
			SetShaderValueTexture(shadowShader, shadowMapLoc, shadowMap.depth);

			BeginMode3D(cam);
			DrawScene();
			EndMode3D();

			DrawText("Shadows in raylib using the shadowmapping algorithm!", screenWidth - 320, screenHeight - 20, 10, GRAY);
			DrawText("Use the arrow keys to rotate the light!", 10, 10, 30, RED);

			EndDrawing();

			if (IsKeyPressed(KEY_F))
				TakeScreenshot("shaders_shadowmap.png");
		}

		UnloadShader(shadowShader);
		UnloadModel(cube);
		UnloadModel(robot);
		UnloadModelAnimations(robotAnimations, robotAnimations.length);
		UnloadShadowmapRenderTexture(shadowMap);

		CloseWindow();
	}
}
