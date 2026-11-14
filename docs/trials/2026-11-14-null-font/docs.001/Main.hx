import helix.raylib.*;
import helix.raylib.Raylib.*;

class Main {
	static var panel:Texture2D = null;
	static var titleFont:Font = null;
	static var promptFont:Font = null;

	static function drawScene(promptOn:Bool) {
		BeginDrawing();
		ClearBackground(new Color(18, 18, 24, 255));

		if (panel != null && IsTextureValid(panel)) {
			var src = new Rectangle(0, 0, panel.width, panel.height);
			var dst = new Rectangle((800 - 420) / 2, (450 - 260) / 2, 420, 260);
			DrawTexturePro(panel, src, dst, new Vector2(0, 0), 0, WHITE);
		}

		var titleBottom = 120.0;
		if (titleFont != null && IsFontValid(titleFont)) {
			var size = MeasureTextEx(titleFont, "WARDENS", 64, 2);
			DrawTextEx(titleFont, "WARDENS", new Vector2(Math.round((800 - size.x) / 2), 120), 64, 2, WHITE);
			titleBottom = 120 + size.y;
		}

		if (promptOn && promptFont != null && IsFontValid(promptFont)) {
			var size = MeasureTextEx(promptFont, "PRESS ENTER", 24, 2);
			DrawTextEx(promptFont, "PRESS ENTER", new Vector2(Math.round((800 - size.x) / 2), titleBottom + 20), 24, 2, LIGHTGRAY);
		}
		EndDrawing();
	}

	static function main() {
		var maxFrames = -1;
		for (a in Sys.args())
			if (StringTools.startsWith(a, "--frames="))
				maxFrames = Std.parseInt(a.substr(9));

		InitWindow(800, 450, "WARDENS");
		SetTargetFPS(60);

		LoadTextureAsync("assets/ui/panel.png", t -> panel = t);
		LoadFontExAsync("assets/ui/font.ttf", 64, null, 0, f -> titleFont = f);
		LoadFontExAsync("assets/ui/font.ttf", 24, null, 0, f -> promptFont = f);

		var frame = 0;
		while (!WindowShouldClose()) {
			if (IsKeyPressed(KEY_ENTER))
				break;

			var lastFrame = maxFrames > 0 && frame + 1 >= maxFrames;
			// blinks once a second: on for half of each second (always on for the screenshot)
			drawScene((frame % 60) < 30 || lastFrame);
			frame++;

			if (lastFrame) {
				var done = false;
				TakeScreenshotAsync("shot.png", () -> done = true, e -> done = true);
				while (!done && !WindowShouldClose())
					drawScene(true);
				break;
			}
		}
		CloseWindow();
	}
}
