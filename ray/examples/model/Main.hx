import helix.ray.Raylib.*;
import helix.ray.Camera3D;
import helix.ray.Vector3;

/** raylib's model loading: a glTF model on a grid, the camera turning about it, in raylib's own shape. The model is `web/assets/trophy.glb`.
	The `frames` option (`HELIX_FRAMES=60` natively, `?frames=60` in a page) stops it after that many frames. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-ray: a model");
		var camera = new Camera3D(new Vector3(3, 2.5, 3), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var model = LoadModel("assets/trophy.glb");
		SetTargetFPS(60);
		while (!WindowShouldClose()) {
			UpdateCamera(camera, CAMERA_ORBITAL);
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(model, new Vector3(0, 0, 0), 1, WHITE);
			DrawGrid(10, 1);
			EndMode3D();
			DrawText("a glTF model, the camera turning", 10, 10, 20, DARKGRAY);
			EndDrawing();
		}
		UnloadModel(model);
		CloseWindow();
	}
}
