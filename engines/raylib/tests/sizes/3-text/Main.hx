// helix-raylib's size ladder (tools/gen_sizes.py): each rung adds one thing to the one before; this one text in raylib's default font.
import helix.raylib.Raylib.*;
import helix.raylib.Vector2;

/** A program written in raylib on helix-raylib, as a game in raylib would be. */
@:adds("helix.raylib.internal.DefaultFont", "helix.raylib.internal.Pixels", "helix.raylib.modules.RText", "helix.raylib.modules.RTextures")
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawRectangle(20, 20, 120, 60, MAROON);
			DrawCircle(220, 50, 30, DARKBLUE);
			DrawLine(20, 100, 260, 100, BLACK);
			DrawTriangle(new Vector2(300, 20), new Vector2(280, 80), new Vector2(340, 80), GOLD);
			DrawText("Hello, raylib", 20, 120, 20, DARKGRAY);
			EndDrawing();
		}
		CloseWindow();
	}
}
