// helix-ray's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a glTF model loaded with LoadModelAsync and drawn in 3D.
import helix.ray.Raylib.*;
import helix.ray.Camera3D;
import helix.ray.Model;
import helix.ray.Texture2D;
import helix.ray.Vector2;
import helix.ray.Vector3;

/** A program written in raylib on helix-ray, as a game in raylib would be. Its image is docs/trials/2026-10-30-async/assets/player.png,
	its model ray/parity/assets/robot.glb. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		var camera = new Camera3D(new Vector3(6, 4, 6), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var texture:Null<Texture2D> = null;
		var model:Null<Model> = null;
		LoadTextureAsync("player.png", loaded -> texture = loaded);
		LoadModelAsync("robot.glb", loaded -> model = loaded);
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			if (model != null)
				DrawModel(model, new Vector3(0, 0, 0), 1, WHITE);
			EndMode3D();
			DrawRectangle(20, 20, 120, 60, MAROON);
			DrawCircle(220, 50, 30, DARKBLUE);
			DrawLine(20, 100, 260, 100, BLACK);
			DrawTriangle(new Vector2(300, 20), new Vector2(280, 80), new Vector2(340, 80), GOLD);
			DrawText("Hello, raylib", 20, 120, 20, DARKGRAY);
			if (texture != null)
				DrawTexture(texture, 20, 160, WHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
