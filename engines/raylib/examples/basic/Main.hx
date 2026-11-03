import helix.ray.Raylib.*;

/** raylib's basic window: text in the middle and a circle at the mouse, in raylib's own shape. The `frames` option (`HELIX_FRAMES=60`
	natively, `?frames=60` in a page) stops it after that many frames. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-ray: basic window");
		SetTargetFPS(60);
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			var text = "Congrats! You created your first window!";
			DrawText(text, Std.int((GetScreenWidth() - MeasureText(text, 20)) / 2), Std.int(GetScreenHeight() / 2 - 10), 20, LIGHTGRAY);
			DrawCircleV(GetMousePosition(), 12, IsMouseButtonDown(MOUSE_BUTTON_LEFT) ? MAROON : DARKBLUE);
			EndDrawing();
		}
		CloseWindow();
	}
}
