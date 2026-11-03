// helix-ray's size ladder (tools/measure_sizes.py): each rung adds one thing to the one before; this one 2D shapes: a rectangle, a circle, a line and a triangle.
import helix.ray.Raylib.*;
import helix.ray.Vector2;

/** A program written in raylib on helix-ray, as a game in raylib would be. */
@:adds("helix.math.Vector3D", "helix.ray.raylib.RRlgl", "helix.ray.raylib.RShapes", "helix.services.images.Image")
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
			EndDrawing();
		}
		CloseWindow();
	}
}
