import helix.raylib.*;
import helix.raylib.Raylib.*;

class Main {
	static function main() {
		var maxFrames = -1;
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
		var bg = new Color(18, 18, 26, 255);
		while (!WindowShouldClose()) {
			frame++;
			if (IsKeyPressed(KEY_ENTER))
				break;

			BeginDrawing();
			ClearBackground(bg);

			if (panel != null && IsTextureValid(panel)) {
				DrawTexturePro(panel, new Rectangle(0, 0, panel.width, panel.height),
					new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260), new Vector2(0, 0), 0, WHITE);
			}

			if (titleFont != null && IsFontValid(titleFont)) {
				var size = MeasureTextEx(titleFont, "WARDENS", 64, 2);
				DrawTextEx(titleFont, "WARDENS", new Vector2(Math.floor((800 - size.x) / 2), 120), 64, 2, WHITE);
			}

			// blinks once a second: on for half a second, off for half
			if (promptFont != null && IsFontValid(promptFont) && GetTime() % 1.0 < 0.5) {
				var size = MeasureTextEx(promptFont, "PRESS ENTER", 24, 2);
				DrawTextEx(promptFont, "PRESS ENTER", new Vector2(Math.floor((800 - size.x) / 2), 120 + 64 + 30), 24, 2, LIGHTGRAY);
			}

			if (maxFrames >= 0 && frame >= maxFrames)
				TakeScreenshot("shot.png");
			EndDrawing();
			if (maxFrames >= 0 && frame >= maxFrames)
				break;
		}
		CloseWindow();
	}
}
