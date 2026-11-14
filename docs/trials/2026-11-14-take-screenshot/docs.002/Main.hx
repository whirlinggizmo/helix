import helix.raylib.*;
import helix.raylib.Raylib.*;

class Main {
	static function main() {
		var maxFrames = 0;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);

		var panel:Texture2D = null;
		var titleFont:Font = null;
		var promptFont:Font = null;
		LoadTextureAsync("assets/ui/panel.png", t -> panel = t);
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> titleFont = f);
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> promptFont = f);

		var frame = 0;
		var quit = false;
		while (!quit && !WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER))
				quit = true;
			frame++;

			BeginDrawing();
			ClearBackground(new Color(20, 22, 30, 255));

			if (panel != null && IsTextureValid(panel))
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
					new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);

			var titleBottom = 120.0;
			if (titleFont != null && IsFontValid(titleFont)) {
				var size = MeasureTextEx(titleFont, "WARDENS", 64, 2);
				DrawTextEx(titleFont, "WARDENS", new Vector2((800 - size.x) / 2, 120), 64, 2, RAYWHITE);
				titleBottom = 120 + size.y;
			}

			// blinks once a second: visible for the first half of each second
			if (promptFont != null && IsFontValid(promptFont) && (GetTime() % 1.0) < 0.5) {
				var size = MeasureTextEx(promptFont, "PRESS ENTER", 24, 2);
				DrawTextEx(promptFont, "PRESS ENTER", new Vector2((800 - size.x) / 2, titleBottom + 20), 24, 2, LIGHTGRAY);
			}

			if (maxFrames > 0 && frame >= maxFrames) {
				TakeScreenshot("shot.png");
				quit = true;
			}
			EndDrawing();
		}
		CloseWindow();
	}
}
