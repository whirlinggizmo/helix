import helix.raylib.*;
import helix.raylib.Raylib.*;
import helix.raylib.extras.Screen.*;
import helix.raylib.extras.Assets.*;

/** Ensures a file ahead of raylib's load of it (`helix.raylib.extras.Assets`): `panel.png` ensured as the program starts, then
	loaded by `LoadTexture` at once and drawn, stretched across the window's middle, with the ensure's progress shown until then. The
	`quit_after_frame` option (`--quit_after_frame=60` natively, `?quit_after_frame=60` in a page) quits it after that frame. */
class Main {
	static function main():Void {
		InitWindow(800, 450, "helix-raylib: assets");
		// The 800 x 450 design fitted to any window, a phone's too (helix.raylib.extras.Screen).
		SetScreenFit(800, 450, SCREEN_STRETCH_CANVAS, SCREEN_FIT_EXPAND, false);
		SetTargetFPS(60);
		var ready = false, shown = "ensuring";
		EnsureAssetsAsync(["panel.png"], () -> ready = true, error -> shown = error, (done, total) -> shown = 'ensured $done of $total');
		var panel:Null<Texture2D> = null;
		while (!WindowShouldClose()) {
			if (ready && panel == null)
				panel = LoadTexture("panel.png");
			BeginDrawing();
			ClearBackground(DARKGRAY);
			if (panel != null)
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height), new Rectangle(200, 75, 400, 300), new Vector2(0, 0), 0, WHITE);
			else
				DrawText(shown, 20, 20, 20, RAYWHITE);
			EndDrawing();
		}
		CloseWindow();
	}
}
