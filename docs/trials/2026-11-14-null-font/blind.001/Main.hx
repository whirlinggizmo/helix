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
		var fontSmall:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t, e -> trace("panel failed: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> font = f, e -> trace("font failed: " + e));
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> fontSmall = f, e -> trace("font24 failed: " + e));

		function draw() {
			var t = GetTime();
			var blinkOn = (t - Math.floor(t)) < 0.5;

			BeginDrawing();
			ClearBackground(new Color(20, 20, 28, 255));
			if (panel != null && font != null && fontSmall != null) {
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
					new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

				var ts = MeasureTextEx(font, "WARDENS", 64, 0);
				DrawTextEx(font, "WARDENS", new Vector2(Math.round((800 - ts.x) / 2), 120), 64, 0, WHITE);

				if (blinkOn) {
					var ps = MeasureTextEx(fontSmall, "PRESS ENTER", 24, 0);
					DrawTextEx(fontSmall, "PRESS ENTER", new Vector2(Math.round((800 - ps.x) / 2), 120 + ts.y + 20), 24, 0, LIGHTGRAY);
				}
			}
			EndDrawing();
		}

		var frame = 0;
		while (!WindowShouldClose()) {
			draw();
			frame++;
			if (IsKeyPressed(KEY_ENTER))
				break;
			if (maxFrames > 0 && frame >= maxFrames) {
				var done = false;
				TakeScreenshotAsync("shot.png", () -> done = true, e -> { trace("shot failed: " + e); done = true; });
				while (!done && !WindowShouldClose())
					draw();
				break;
			}
		}

		UnloadFont(font);
		UnloadFont(fontSmall);
		UnloadTexture(panel);
		CloseWindow();
	}
}
