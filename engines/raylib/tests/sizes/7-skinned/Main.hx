// helix-raylib's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one the model's animations loaded with LoadModelAnimationsAsync and one played.
import helix.raylib.Raylib.*;
import helix.raylib.Camera3D;
import helix.raylib.Model;
import helix.raylib.ModelAnimation;
import helix.raylib.Texture2D;
import helix.raylib.Vector2;
import helix.raylib.Vector3;

/** A program written in raylib on helix-raylib, as a game in raylib would be. Its image is docs/trials/2026-10-30-async/assets/player.png,
	its model and animations engines/raylib/parity/assets/robot.glb. */
@:adds("helix.raylib.internal.Skinning", "helix.raylib.internal._Skinning.Chunk")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		var camera = new Camera3D(new Vector3(6, 4, 6), new Vector3(0, 1.5, 0), new Vector3(0, 1, 0), 45, CAMERA_PERSPECTIVE);
		var texture:Null<Texture2D> = null;
		var model:Null<Model> = null;
		var cube = LoadModelFromMesh(GenMeshCube(1, 1, 1));
		var animations:Null<Array<ModelAnimation>> = null;
		var frame = 0;
		LoadTextureAsync("player.png", loaded -> texture = loaded);
		LoadModelAsync("robot.glb", loaded -> model = loaded);
		LoadModelAnimationsAsync("robot.glb", loaded -> animations = loaded);
		while (!WindowShouldClose()) {
			if (model != null && animations != null && animations.length > 0) {
				frame = (frame + 1) % animations[0].frameCount;
				UpdateModelAnimation(model, animations[0], frame);
			}
			BeginDrawing();
			ClearBackground(RAYWHITE);
			BeginMode3D(camera);
			DrawModel(cube, new Vector3(-3, 0.5, 0), 1, WHITE);
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
