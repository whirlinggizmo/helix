import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;

/** An image made on the CPU: a gradient with a circle and text drawn into it, then drawn as a texture in the middle of the window. The
	`quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: images");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		var image = GenImageGradientLinear(400, 200, 90, DARKBLUE, SKYBLUE);
		ImageDrawCircle(image, 100, 100, 60, GOLD);
		ImageDrawText(image, "Drawn on the CPU", 180, 90, 20, RAYWHITE);
		var texture = LoadTextureFromImage(image);
		UnloadImage(image);
		SetTargetFPS(60);
		while (!WindowShouldClose()) {
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawTexture(texture, Std.int((GetScreenWidth() - texture.width) / 2), Std.int((GetScreenHeight() - texture.height) / 2), WHITE);
			EndDrawing();
		}
		UnloadTexture(texture);
		CloseWindow();
	}
}
