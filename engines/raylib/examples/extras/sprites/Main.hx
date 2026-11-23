import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.Raymath.*;
import helix.raylib.extras.Sprites.*;

/** Draws a thousand spinning sprites of one texture in one call (`helix.raylib.extras.Sprites`), each placed by its own matrix, the
	matrices reused each frame. The `quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page)
	quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: sprites");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		var image = GenImageChecked(16, 16, 8, 8, MAROON, GOLD);
		var texture = LoadTextureFromImage(image);
		UnloadImage(image);
		var count = 1000;
		var places = [
			for (i in 0...count)
				new Vector2(GetRandomValue(0, 800), GetRandomValue(40, 450))
		];
		var transforms = [for (i in 0...count) MatrixIdentity()];
		while (!WindowShouldClose()) {
			var time = GetTime();
			for (i in 0...count)
				transforms[i] = MatrixMultiply(MatrixMultiply(MatrixTranslate(-8, -8, 0), MatrixRotateZ(time * 2 + i)),
					MatrixTranslate(places[i].x, places[i].y, 0));
			BeginDrawing();
			ClearBackground(RAYWHITE);
			DrawTextureInstanced(texture, new Rectangle(0, 0, 16, 16), transforms, WHITE);
			DrawText('$count sprites, one call', 10, 10, 20, DARKGRAY);
			EndDrawing();
		}
		UnloadTexture(texture);
		CloseWindow();
	}
}
