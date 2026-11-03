import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.Extras.*;

// scene.c's core_vr_simulator, drawn by helix-raylib as raylib's example is written: the third frame saved as helix.png. Its shader (web/)
// is raylib's distortion330.fs, as the example has it.
class Main {
	static function main():Void {
		InitWindow(800, 450, "vr");
		var device:VrDeviceInfo = {
			hResolution: 2160,
			vResolution: 1200,
			hScreenSize: 0.133793,
			vScreenSize: 0.0669,
			eyeToScreenDistance: 0.041,
			lensSeparationDistance: 0.07,
			interpupillaryDistance: 0.07,
			lensDistortionValues: [1.0, 0.22, 0.24, 0.0],
			chromaAbCorrection: [0.996, -0.004, 1.014, 0.0]
		};
		var config = LoadVrStereoConfig(device);
		var distortion = LoadShader(null, "distortion330.fs");
		SetShaderValue(distortion, GetShaderLocation(distortion, "leftLensCenter"), config.leftLensCenter, SHADER_UNIFORM_VEC2);
		SetShaderValue(distortion, GetShaderLocation(distortion, "rightLensCenter"), config.rightLensCenter, SHADER_UNIFORM_VEC2);
		SetShaderValue(distortion, GetShaderLocation(distortion, "leftScreenCenter"), config.leftScreenCenter, SHADER_UNIFORM_VEC2);
		SetShaderValue(distortion, GetShaderLocation(distortion, "rightScreenCenter"), config.rightScreenCenter, SHADER_UNIFORM_VEC2);
		SetShaderValue(distortion, GetShaderLocation(distortion, "scale"), config.scale, SHADER_UNIFORM_VEC2);
		SetShaderValue(distortion, GetShaderLocation(distortion, "scaleIn"), config.scaleIn, SHADER_UNIFORM_VEC2);
		SetShaderValue(distortion, GetShaderLocation(distortion, "deviceWarpParam"), device.lensDistortionValues, SHADER_UNIFORM_VEC4);
		SetShaderValue(distortion, GetShaderLocation(distortion, "chromaAbParam"), device.chromaAbCorrection, SHADER_UNIFORM_VEC4);
		var target = LoadRenderTexture(device.hResolution, device.vResolution);
		var sourceRec = new Rectangle(0, 0, target.texture.width, -target.texture.height);
		var destRec = new Rectangle(0, 0, GetScreenWidth(), GetScreenHeight());
		var camera = new Camera(new Vector3(5, 2, 5), new Vector3(0, 2, 0), new Vector3(0, 1, 0), 60, CAMERA_PERSPECTIVE);
		var cubePosition = new Vector3(0, 0, 0);
		var sphere = LoadModelFromMesh(GenMeshSphere(0.6, 16, 16));
		var frame = 0;
		while (!WindowShouldClose()) {
			BeginTextureMode(target);
			ClearBackground(RAYWHITE);
			BeginVrStereoMode(config);
			BeginMode3D(camera);
			DrawCube(cubePosition, 2, 2, 2, RED);
			DrawCubeWires(cubePosition, 2, 2, 2, MAROON);
			DrawGrid(40, 1);
			DrawModel(sphere, new Vector3(0, 2.5, 1), 1, BLUE);
			EndMode3D();
			EndVrStereoMode();
			EndTextureMode();
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginShaderMode(distortion);
			DrawTexturePro(target.texture, sourceRec, destRec, new Vector2(0, 0), 0, WHITE);
			EndShaderMode();
			if (frame == 2)
				TakeScreenshotAsync("helix.png");
			EndDrawing();
			frame++;
		}
		UnloadVrStereoConfig(config);
		UnloadRenderTexture(target);
		UnloadShader(distortion);
		CloseWindow();
	}
}
