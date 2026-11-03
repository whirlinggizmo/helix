import helix.raylib.Raylib.*;
import helix.raylib.Extras.*;
import helix.raylib.Camera3D;
import helix.raylib.Model;
import helix.raylib.Vector3;

/** raylib's model loading: a glTF model on a grid, the camera turning about it, in raylib's own shape, the model loaded with
	`LoadModelAsync` so it loads the same in a page and natively. The model is `web/assets/trophy.glb`.
	The `frames` option (`HELIX_FRAMES=60` natively, `?frames=60` in a page) stops it after that many frames. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: a model");
		var camera = new Camera3D(new Vector3(3, 2.5, 3), new Vector3(0, 0, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var model:Null<Model> = null;
		LoadModelAsync("assets/trophy.glb", loaded -> model = loaded);
		SetTargetFPS(60);
		while (!WindowShouldClose()) {
			UpdateCamera(camera, CAMERA_ORBITAL);
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			if (model != null)
				DrawModel(model, new Vector3(0, 0, 0), 1, WHITE);
			DrawGrid(10, 1);
			EndMode3D();
			DrawText("a glTF model, the camera turning", 10, 10, 20, DARKGRAY);
			EndDrawing();
		}
		if (model != null)
			UnloadModel(model);
		CloseWindow();
	}
}
