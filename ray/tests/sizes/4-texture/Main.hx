// helix-ray's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a texture loaded with LoadTextureAsync and drawn.
import helix.ray.Raylib.*;
import helix.ray.Texture2D;
import helix.ray.Vector2;

/** A program written in raylib on helix-ray, as a game in raylib would be. Its image is docs/trials/2026-10-30-async/assets/player.png. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		var texture:Null<Texture2D> = null;
		LoadTextureAsync("player.png", loaded -> texture = loaded);
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
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
