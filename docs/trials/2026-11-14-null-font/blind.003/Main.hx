import helix.raylib.Raylib.*;
import helix.raylib.*;

class Main {
	static function draw(panel:Texture2D, font:Font, small:Font, frame:Int) {
		BeginDrawing();
		ClearBackground(new Color(18, 18, 24, 255));

		DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
			new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

		var title = "WARDENS";
		var ts = MeasureTextEx(font, title, 64, 2);
		DrawTextEx(font, title, new Vector2(Math.round((800 - ts.x) / 2), 120), 64, 2, RAYWHITE);

		// visible for the first half of every second
		if (frame % 60 < 30) {
			var prompt = "PRESS ENTER";
			var ps = MeasureTextEx(small, prompt, 24, 2);
			DrawTextEx(small, prompt, new Vector2(Math.round((800 - ps.x) / 2), 120 + 64 + 30), 24, 2, LIGHTGRAY);
		}
		EndDrawing();
	}

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
		var done = false;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace(e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font = f, e -> trace(e));
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> small = f, e -> trace(e));

		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER))
				break;

			if (panel == null || font == null || small == null) {
				BeginDrawing();
				ClearBackground(new Color(18, 18, 24, 255));
				EndDrawing();
				continue;
			}
			frame++;
			draw(panel, font, small, frame);

			if (maxFrames > 0 && frame >= maxFrames) {
				var saved = false;
				TakeScreenshotAsync("shot.png", () -> saved = true, e -> {trace(e); saved = true;});
				while (!saved && !WindowShouldClose()) {
					draw(panel, font, small, frame);
				}
				break;
			}
		}

		UnloadFont(font);
		UnloadFont(small);
		UnloadTexture(panel);
		CloseWindow();
	}
}
