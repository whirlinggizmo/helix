// helix-ray's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one a window cleared each frame: raylib's loop and frame, and what helix-ray builds before main.
import helix.ray.Raylib.*;

/** A program written in raylib on helix-ray, as a game in raylib would be. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "sizes");
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
