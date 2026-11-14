import helix.raylib.Raylib.*;
import helix.raylib.*;

class Main {
	static function main() {
		var maxFrames = -1;
		for (a in Sys.args()) {
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));
		}

		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);

		var panel:Texture2D = null;
		var font:Font = null;
		var small:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace("panel: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font = f, e -> trace("font64: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> small = f, e -> trace("font24: " + e));

		var title = "WARDENS";
		var prompt = "PRESS ENTER";
		var tsize:Vector2 = null;
		var psize:Vector2 = null;
		var shotDone = false;
		var bg = new Color(20, 20, 28, 255);

		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER)) break;
			if (shotDone) break;
			frame++;

			// Fonts arrive asynchronously; measure once each is loaded.
			if (tsize == null && font != null) tsize = MeasureTextEx(font, title, 64, 2);
			if (psize == null && small != null) psize = MeasureTextEx(small, prompt, 24, 2);

			BeginDrawing();
			ClearBackground(bg);
			if (panel != null)
				DrawTexturePro(panel,
				new Rectangle(0, 0, panel.width, panel.height),
				new Rectangle(190, 95, 420, 260),
				new Vector2(0, 0), 0, WHITE);
			if (tsize != null)
				DrawTextEx(font, title, new Vector2(Std.int((800 - tsize.x) / 2), 120), 64, 2, WHITE);
			if (psize != null && (frame % 60) < 30)
				DrawTextEx(small, prompt, new Vector2(Std.int((800 - psize.x) / 2), 120 + 64 + 20), 24, 2, LIGHTGRAY);
			EndDrawing();

			if (maxFrames > 0 && frame >= maxFrames) {
				TakeScreenshotAsync("shot.png", () -> shotDone = true, e -> { trace("shot: " + e); shotDone = true; });
				maxFrames = -1;
			}
		}

		CloseWindow();
	}
}
